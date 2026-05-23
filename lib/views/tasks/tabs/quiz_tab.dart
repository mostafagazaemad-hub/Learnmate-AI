import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/groq_service.dart';
import '../../../core/services/settings_service.dart';

// ─── تبويب الاختبار ───────────────────────────────────────────────────────────
// يولد اختبارات بالذكاء الاصطناعي، يجمع إجابات المستخدم، ثم يقيّمها ويعرض النتائج.
class Question {
  final String question;
  final List<String> options;
  final String answer;
  final String type;
  String? userAnswer;
  double? accuracy;
  String? feedback;
  bool? isCorrect;

  Question({
    required this.question,
    required this.options,
    required this.answer,
    required this.type,
    this.userAnswer,
    this.accuracy,
    this.feedback,
    this.isCorrect,
  });
}

class QuizTab extends StatefulWidget {
  final String topic;
  final Function(String)? onGenerated;
  final String? initialData;
  const QuizTab({super.key, required this.topic, this.onGenerated, this.initialData});

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> with AutomaticKeepAliveClientMixin {
  final GroqService _groqService = GroqService();
  final SettingsService _settings = SettingsService();
  List<Question>? _questions;
  bool _isLoading = false;
  bool _isEvaluating = false;
  int _currentIndex = 0;
  bool _isFinished = false;
  
  // Quiz Settings
  int _questionCount = 5;
  List<String> _selectedTypes = ['multiple choice'];
  bool _showSettings = true;

  final TextEditingController _textController = TextEditingController();

  List<Map<String, dynamic>> get _quizTypes {
    final isArabic = _settings.locale.languageCode == 'ar';
    return [
      {'id': 'multiple choice', 'label': isArabic ? 'اختيار من متعدد' : 'Multiple Choice', 'icon': Icons.list_alt_rounded},
      {'id': 'true/false', 'label': isArabic ? 'صح / خطأ' : 'True / False', 'icon': Icons.check_circle_outline_rounded},
      {'id': 'fill in the blanks', 'label': isArabic ? 'ملء الفراغات' : 'Fill in Blanks', 'icon': Icons.edit_note_rounded},
      {'id': 'define terms', 'label': isArabic ? 'تعريف المصطلحات' : 'Definitions', 'icon': Icons.description_outlined},
    ];
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _parseQuizData(widget.initialData!);
      _showSettings = false;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Parses a saved quiz JSON payload into question objects when restored from initialData.
  void _parseQuizData(String data) {
    try {
      final json = jsonDecode(data);
      final List<dynamic> raw = json['questions'] ?? [];
      setState(() {
        _questions = raw.map((q) => Question(
          question: q['question']?.toString() ?? '',
          options: List<String>.from(q['options'] ?? []),
          answer: q['answer']?.toString() ?? '',
          type: q['type']?.toString() ?? 'multiple choice',
        )).toList();
      });
    } catch (e) {
      debugPrint('Error parsing Quiz data: $e');
    }
  }

  // Requests quiz questions from GroqService using selected count and types.
  Future<void> _generateQuiz() async {
    final isArabic = _settings.locale.languageCode == 'ar';
    if (_selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'يرجى اختيار نوع واحد على الأقل' : 'Please select at least one type'))
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _showSettings = false;
      _questions = null;
      _currentIndex = 0;
      _isFinished = false;
      _textController.clear();
    });
    try {
      final result = await _groqService.generateQuiz(
        widget.topic, 
        count: _questionCount, 
        types: _selectedTypes
      );
      
      String cleaned = result.trim();
      if (cleaned.contains('```')) {
        final start = cleaned.indexOf('{');
        final end = cleaned.lastIndexOf('}');
        if (start != -1 && end != -1) {
          cleaned = cleaned.substring(start, end + 1);
        }
      }

      final json = jsonDecode(cleaned);
      final List<dynamic> raw = json['questions'] ?? [];
      
      if (raw.isEmpty) throw Exception('No questions found');

      setState(() {
        _questions = raw.map((q) => Question(
          question: q['question']?.toString() ?? '',
          options: List<String>.from(q['options'] ?? []),
          answer: q['answer']?.toString() ?? '',
          type: q['type']?.toString() ?? _selectedTypes.first,
        )).toList();
        _isLoading = false;
      });
      if (widget.onGenerated != null) {
        widget.onGenerated!(jsonEncode(json));
      }
    } catch (e) {
      debugPrint('Error generating quiz: $e');
      setState(() {
        _isLoading = false;
        _showSettings = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'فشل توليد الاختبار: $e' : 'Failed to generate quiz: $e'),
            backgroundColor: AppColors.error,
          )
        );
      }
    }
  }

  Future<void> _submitAnswer() async {
    if (_questions == null) return;
    
    final currentQ = _questions![_currentIndex];
    if (currentQ.type == 'fill in the blanks' || currentQ.type == 'define terms') {
      currentQ.userAnswer = _textController.text.trim();
    }

    if (currentQ.userAnswer == null || currentQ.userAnswer!.isEmpty) return;

    if (_currentIndex < _questions!.length - 1) {
      setState(() {
        _currentIndex++;
        _textController.clear();
      });
    } else {
      await _finishQuiz();
    }
  }

  // Submits completed quiz answers to GroqService for evaluation and enriches questions with feedback.
  Future<void> _finishQuiz() async {
    setState(() {
      _isFinished = true;
      _isEvaluating = true;
    });

    try {
      final List<Map<String, dynamic>> results = _questions!.asMap().entries.map((entry) {
        return {
          'index': entry.key,
          'question': entry.value.question,
          'correct_answer': entry.value.answer,
          'user_answer': entry.value.userAnswer,
          'type': entry.value.type,
        };
      }).toList();

      final evalResponse = await _groqService.evaluateAnswers(widget.topic, results);
      
      String cleaned = evalResponse.trim();
      if (cleaned.contains('```')) {
        final start = cleaned.indexOf('{');
        final end = cleaned.lastIndexOf('}');
        if (start != -1 && end != -1) {
          cleaned = cleaned.substring(start, end + 1);
        }
      }
      
      final evalJson = jsonDecode(cleaned);
      final List<dynamic> evals = evalJson['evaluations'] ?? [];

      setState(() {
        for (var eval in evals) {
          int index = eval['index'];
          if (index < _questions!.length) {
            _questions![index].accuracy = (eval['accuracy'] as num).toDouble();
            _questions![index].feedback = eval['feedback'];
            _questions![index].isCorrect = eval['is_correct'] ?? (eval['accuracy'] > 0.6);
          }
        }
        _isEvaluating = false;
      });
    } catch (e) {
      debugPrint('Error evaluating answers: $e');
      setState(() {
        for (var q in _questions!) {
          if (q.type == 'multiple choice' || q.type == 'true/false' || q.type == 'fill in the blanks') {
            q.isCorrect = q.userAnswer?.trim().toLowerCase() == q.answer.trim().toLowerCase();
            q.accuracy = q.isCorrect! ? 1.0 : 0.0;
          } else {
            q.accuracy = 0.5; // Fallback
            q.isCorrect = true;
          }
        }
        _isEvaluating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        final isArabic = _settings.locale.languageCode == 'ar';

        if (_isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 20),
                Text(isArabic ? 'جاري تحضير الاختبار...' : 'Preparing your quiz...', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        if (_showSettings) {
          return _buildSettingsState(isDark, isArabic);
        }

        if (_isFinished) {
          if (_isEvaluating) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 20),
                  Text(isArabic ? 'جاري تقييم إجاباتك...' : 'Evaluating your answers...', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }
          return _buildResultState(isDark, isArabic);
        }

        if (_questions == null || _questions!.isEmpty) {
          return _buildSettingsState(isDark, isArabic);
        }

        return _buildQuizState(isDark, isArabic);
      }
    );
  }

  Widget _buildSettingsState(bool isDark, bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF6C5DD3)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_rounded, color: Colors.white, size: 48),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isArabic ? 'إعدادات الاختبار' : 'Quiz Settings', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('${isArabic ? 'الموضوع' : 'Topic'}: ${widget.topic}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(isArabic ? 'عدد الأسئلة' : 'Number of Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [5, 10, 15, 20].map((count) {
              final isSelected = _questionCount == count;
              return GestureDetector(
                onTap: () => setState(() => _questionCount = count),
                child: Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.darkDivider : Colors.grey.shade200)),
                  ),
                  child: Center(
                    child: Text(count.toString(), style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.textPrimary), fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text(isArabic ? 'أنواع الأسئلة' : 'Question Types', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.6),
            itemCount: _quizTypes.length,
            itemBuilder: (context, index) {
              final type = _quizTypes[index];
              final isSelected = _selectedTypes.contains(type['id']);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      if (_selectedTypes.length > 1) _selectedTypes.remove(type['id']);
                    } else {
                      _selectedTypes.add(type['id']);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.darkDivider : Colors.grey.shade200)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(type['icon'], color: isSelected ? AppColors.primary : Colors.grey.shade400, size: 32),
                      const SizedBox(height: 8),
                      Text(type['label'], style: TextStyle(color: isSelected ? AppColors.primary : (isDark ? Colors.white : AppColors.textPrimary), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _generateQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(isArabic ? 'ابدأ الاختبار' : 'Start Quiz', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizState(bool isDark, bool isArabic) {
    final q = _questions![_currentIndex];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions!.length,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            color: AppColors.primary,
            minHeight: 8,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              Text(
                isArabic ? 'السؤال ${_currentIndex + 1} من ${_questions!.length}' : 'Question ${_currentIndex + 1} of ${_questions!.length}', 
                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)
              ),
              const SizedBox(height: 12),
              Text(q.question, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: 32),
              if (q.type == 'multiple choice' || q.type == 'true/false')
                ...q.options.map((opt) {
                  final isSelected = q.userAnswer == opt;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => setState(() => q.userAnswer = opt),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), 
                        side: BorderSide(color: isSelected ? AppColors.primary : (isDark ? AppColors.darkDivider : Colors.grey.shade200))
                      ),
                      tileColor: isSelected ? AppColors.primary.withOpacity(0.05) : (isDark ? AppColors.darkCard : Colors.white),
                      title: Text(opt, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : null, color: isDark ? Colors.white : AppColors.textPrimary)),
                      leading: Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? AppColors.primary : Colors.grey),
                    ),
                  );
                })
              else
                TextField(
                  controller: _textController,
                  maxLines: 4,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: isArabic ? 'اكتب إجابتك هنا...' : 'Type your answer here...',
                    hintStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300)),
                  ),
                  onChanged: (val) => setState(() => q.userAnswer = val),
                ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: (q.userAnswer != null && q.userAnswer!.isNotEmpty) ? _submitAnswer : null,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: Text(
                  _currentIndex < _questions!.length - 1 
                    ? (isArabic ? 'السؤال التالي' : 'Next Question') 
                    : (isArabic ? 'إنهاء الاختبار' : 'Finish Quiz'), 
                  style: const TextStyle(color: Colors.white, fontSize: 18)
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultState(bool isDark, bool isArabic) {
    int correctCount = _questions!.where((q) => q.isCorrect == true).length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF6C5DD3)]), borderRadius: BorderRadius.circular(32)),
            child: Column(
              children: [
                Text(isArabic ? 'اكتمل الاختبار!' : 'Quiz Completed!', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${isArabic ? 'النتيجة' : 'Score'}: $correctCount / ${_questions!.length}', style: const TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildCompactSettings(isDark, isArabic),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: _generateQuiz, 
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: Text(isArabic ? 'إعادة توليد الاختبار' : 'Regenerate Quiz', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              )),
            ],
          ),
          const SizedBox(height: 32),
          ..._questions!.asMap().entries.map((entry) {
            final q = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white, 
                borderRadius: BorderRadius.circular(20), 
                border: Border.all(color: q.isCorrect == true ? Colors.green.shade400 : Colors.red.shade400)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${isArabic ? 'س' : 'Q'}${entry.key + 1}: ${q.question}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Text('${isArabic ? 'إجابتك' : 'Your Answer'}: ${q.userAnswer}', style: TextStyle(color: q.isCorrect == true ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  Text('${isArabic ? 'الإجابة الصحيحة' : 'Correct Answer'}: ${q.answer}', style: const TextStyle(color: Colors.green)),
                  if (q.feedback != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${isArabic ? 'تعليق' : 'Feedback'}: ${q.feedback}', style: const TextStyle(fontSize: 12, color: Colors.blue))),
                ],
              ),
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCompactSettings(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkDivider : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(isArabic ? 'تعديل إعدادات التوليد' : 'Modify Generation Settings', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          // Compact Question Count
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [5, 10, 15, 20].map((count) {
                final isSelected = _questionCount == count;
                return GestureDetector(
                  onTap: () => setState(() => _questionCount = count),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBackground : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(count.toString(), style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Compact Types
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quizTypes.map((type) {
              final isSelected = _selectedTypes.contains(type['id']);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      if (_selectedTypes.length > 1) _selectedTypes.remove(type['id']);
                    } else {
                      _selectedTypes.add(type['id']);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(type['icon'], size: 14, color: isSelected ? AppColors.primary : Colors.grey),
                      const SizedBox(width: 4),
                      Text(type['label'], style: TextStyle(fontSize: 11, color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
