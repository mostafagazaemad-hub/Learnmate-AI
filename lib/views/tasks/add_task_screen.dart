import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/settings_service.dart';
import '../study/study_session_screen.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _topicController = TextEditingController();
  final SettingsService _settings = SettingsService();

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, bool isDark, {Color color = AppColors.primary}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: isDark ? Colors.white : Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool _isGibberish(String text) {
    if (text.length < 3) return true;
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final weirdWords = words.where((w) {
      if (w.length < 2) return true;
      final chars = w.toLowerCase().split('');
      return chars.every((c) => c == chars.first);
    }).length;
    final letterCount = text.replaceAll(RegExp(r'[^a-zA-Z\u0600-\u06FF]'), '').length;
    return (letterCount < 3) || (weirdWords / words.length > 0.8 && text.length < 10);
  }

  List<String> _detectMultipleTopics(String text) {
    final parts = text.split(RegExp(r',|;|\sand\s|\sو\s', caseSensitive: false))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.length > 1 ? parts : [];
  }

  void _startLearning(bool isDark, bool isArabic) {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      _showSnackBar(isArabic ? 'يرجى إدخال موضوع للدراسة أولاً!' : 'Please enter a study topic first!', isDark);
      return;
    }

    if (_isGibberish(topic)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.help_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'موضوع غير واضح' : 'Unclear Topic', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : AppColors.textPrimary)
              ),
            ],
          ),
          content: Text(
            isArabic 
              ? 'يبدو أن الموضوع الذي أدخلته قد لا يكون موضوعاً صالحاً للدراسة. جرب إدخال شيء مثل:\n\n'
                '• "التركيب الضوئي"\n'
                '• "الحرب العالمية الثانية"\n'
                '• "أساسيات تعلم الآلة"'
              : 'It looks like the topic you entered might not be a valid study subject. Try entering something like:\n\n'
                '• "Photosynthesis"\n'
                '• "World War II"\n'
                '• "Machine Learning Basics"',
            style: TextStyle(height: 1.6, color: isDark ? Colors.white70 : AppColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isArabic ? 'تعديل الموضوع' : 'Edit Topic', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final topics = _detectMultipleTopics(topic);
    if (topics.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.list_alt, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'مواضيع متعددة' : 'Multiple Topics', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : AppColors.textPrimary)
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'وجدنا مواضيع متعددة. اختر واحداً للتركيز عليه في هذه الجلسة:' : 'We found multiple topics. Pick one to focus on for this session:',
                style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              ...topics.map(
                (t) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.radio_button_unchecked, color: AppColors.primary),
                  title: Text(t, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateToChat(t);
                  },
                ),
              ),
              Divider(color: isDark ? AppColors.darkDivider : AppColors.divider),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.merge_type, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                title: Text(
                  isArabic ? 'دراسة جميع المواضيع معاً' : 'Study all topics together',
                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToChat(topic);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isArabic ? 'إلغاء' : 'Cancel', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
            ),
          ],
        ),
      );
      return;
    }

    _navigateToChat(topic);
  }

  void _navigateToChat(String topic) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StudySessionScreen(topic: topic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        final isArabic = _settings.locale.languageCode == 'ar';

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isArabic ? 'جلسة دراسة جديدة' : 'New Study Session',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : AppColors.textPrimary),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'ماذا تريد أن تتعلم اليوم؟' : 'What do you want to learn today?',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1C1E)),
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic ? 'أدخل موضوعاً وسيقوم الذكاء الاصطناعي الخاص بنا بإنشاء خطة دراسة مخصصة لك.' : 'Enter a topic and our AI will generate a personalized study plan for you.',
                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 48),

                // Topic Input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'موضوع الدراسة' : 'Study Topic',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF1A1C1E)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkDivider : const Color(0xFFE9EBEE)),
                      ),
                      child: TextField(
                        controller: _topicController,
                        autofocus: false,
                        style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _startLearning(isDark, isArabic),
                        decoration: InputDecoration(
                          hintText: isArabic ? 'مثلاً: ميكانيكا الكم، أساسيات تعلم الآلة...' : 'e.g. Quantum Physics, Machine Learning Basics...',
                          hintStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Start Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _startLearning(isDark, isArabic),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          isArabic ? 'ابدأ التعلم بالذكاء الاصطناعي' : 'Start Learning with AI',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    isArabic ? 'مدعوم بواسطة LearnMate AI' : 'POWERED BY LEARNMATE AI',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }
    );
  }
}
