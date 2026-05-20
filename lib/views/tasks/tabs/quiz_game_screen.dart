import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

// 1. نموذج يمثل كل سؤال
class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctIndex,
  });
}

class QuizGameScreen extends StatefulWidget {
  final String aiJsonResponse;
  final VoidCallback? onBack;

  const QuizGameScreen({super.key, required this.aiJsonResponse, this.onBack});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  List<QuizQuestion> questions = [];
  String quizMessage = "جاري تجهيز التحدي...";
  
  int currentQuestionIndex = 0;
  int score = 0;
  bool isAnswered = false; 
  int? selectedOptionIndex; 

  Timer? _timer;
  int _timeLeft = 10;

  @override
  void initState() {
    super.initState();
    _setupQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = 10;
      isAnswered = false;
      selectedOptionIndex = null;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _onTimeOut();
      }
    });
  }

  void _onTimeOut() {
    _timer?.cancel();
    setState(() {
      isAnswered = true;
      // لا يوجد خيار محدد
    });
    
    // الانتقال بعد ثانيتين
    _moveToNextQuestion();
  }

  /// دالة تفكيك الـ JSON وتجهيز الأسئلة
  void _setupQuiz() {
    try {
      final data = jsonDecode(widget.aiJsonResponse);
      setState(() {
        quizMessage = data['quiz_message'] ?? 'مستعد للتحدي؟';
      });

      final List<dynamic> questionsData = data['questions'];
      for (var q in questionsData) {
        questions.add(QuizQuestion(
          questionText: q['question'],
          options: List<String>.from(q['options']),
          correctIndex: q['correct_index'],
        ));
      }
      
      if (questions.isNotEmpty) {
        _startTimer();
      }
    } catch (e) {
      debugPrint("خطأ في قراءة الـ JSON: $e");
    }
  }

  /// دالة معالجة إجابة الطالب
  void _checkAnswer(int index) {
    if (isAnswered) return; 

    _timer?.cancel();
    setState(() {
      isAnswered = true;
      selectedOptionIndex = index;

      if (index == questions[currentQuestionIndex].correctIndex) {
        score++;
      }
    });

    _moveToNextQuestion();
  }

  void _moveToNextQuestion() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
        });
        _startTimer();
      } else {
        _showFinalScore();
      }
    });
  }

  /// عرض النتيجة النهائية
  void _showFinalScore() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('انتهى التحدي!', textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            Text('نتيجتك هي:', style: GoogleFonts.inter(fontSize: 18)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                Text('$score', 
                    style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
                Text(' من ', 
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary.withOpacity(0.7))),
                Text('${questions.length}', 
                    style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); 
            },
            child: Text('حسناً', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    final timeProgress = _timeLeft / 10;
    final timerColor = _timeLeft <= 3 ? Colors.red : AppColors.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('تحدي المعلومات الذكي', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timer Progress Bar
            Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: timerColor.withOpacity(0.1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: timeProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'السؤال ${currentQuestionIndex + 1} من ${questions.length}',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '$_timeLeft ثوانٍ متبقية',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: timerColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // عرض السؤال
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  Text(
                    quizMessage,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentQuestion.questionText,
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // عرض الخيارات كأزرار
            ...List.generate(currentQuestion.options.length, (index) {
              // تحديد لون الزر بناءً على حالة الإجابة
              Color buttonColor = Colors.white;
              Color borderColor = Colors.grey.shade200;
              Color textColor = AppColors.textPrimary;

              if (isAnswered) {
                if (index == currentQuestion.correctIndex) {
                  buttonColor = Colors.green.shade50;
                  borderColor = Colors.green;
                  textColor = Colors.green.shade700;
                } else if (index == selectedOptionIndex) {
                  buttonColor = Colors.red.shade50;
                  borderColor = Colors.red;
                  textColor = Colors.red.shade700;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: textColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: borderColor, width: 2),
                      ),
                    ),
                    onPressed: () => _checkAnswer(index),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: borderColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(fontWeight: FontWeight.bold, color: borderColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            currentQuestion.options[index],
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (isAnswered && index == currentQuestion.correctIndex)
                          const Icon(Icons.check_circle, color: Colors.green),
                        if (isAnswered && index == selectedOptionIndex && index != currentQuestion.correctIndex)
                          const Icon(Icons.cancel, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
