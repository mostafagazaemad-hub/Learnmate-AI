import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/groq_service.dart';
import '../../../core/services/settings_service.dart';
import 'memory_game_screen.dart';
import 'quiz_game_screen.dart';

// ─── تبويب الألعاب التعليمية ───────────────────────────────────────────────────
// يستخدم هذا الجزء الذكاء الاصطناعي لتحويل الموضوع إلى لعبة ذاكرة أو اختبار.
class GameTab extends StatefulWidget {
  final String topic;
  final Function(String)? onGenerated;
  final String? initialData;

  const GameTab({
    super.key,
    required this.topic,
    this.onGenerated,
    this.initialData,
  });

  @override
  State<GameTab> createState() => _GameTabState();
}

class _GameTabState extends State<GameTab> with AutomaticKeepAliveClientMixin {
  // خدمة الذكاء الاصطناعي لطلب توليد المحتوى من Groq.
  final GroqService _groq = GroqService();

  // خدمة الإعدادات لقراءة وضع الثيم واللغة الحالية.
  final SettingsService _settings = SettingsService();

  // متغير للسيطرة على عرض مؤشر التحميل أثناء انتظار الـ AI.
  bool _isLoading = false;

  // يحفظ كامل استجابة اللعبة المولدة كـ JSON نصي.
  String? _gameData;

  // نوع اللعبة المختار حالياً: ذاكرة أو اختبار.
  String _selectedGameType = 'memory'; // 'memory' أو 'quiz'

  @override
  bool get wantKeepAlive => true;

  // ─── تهيئة الحالة ───────────────────────────────────────────────────────────
  // إذا جاءنا JSON لعبة جاهز من شاشة أخرى، نحفظه ونعرضه دون توليد جديد.
  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _gameData = widget.initialData;
    }
  }

  // ─── توليد لعبة جديدة عبر الـ AI ───────────────────────────────────────────────
  // يطلب من الخدمة إنشاء لعبة جديدة بناءً على الموضوع الحالي.
  Future<void> _generateGame() async {
    setState(() => _isLoading = true);
    try {
      final result = _selectedGameType == 'memory'
          ? await _groq.generateMemoryGame(widget.topic)
          : await _groq.generateQuizGame(widget.topic);

      String cleaned = result.trim();

      // في بعض الأحيان يعيد النموذج نصاً إضافياً مثل fences كود.
      // نبحث عن الكائن JSON الصحيح ونستخرجه فقط.
      if (cleaned.contains('```')) {
        final start = cleaned.indexOf('{');
        final end = cleaned.lastIndexOf('}');
        if (start != -1 && end != -1) {
          cleaned = cleaned.substring(start, end + 1);
        }
      }

      // التحقق من أن النص المحرّر هو JSON صالح.
      jsonDecode(cleaned);

      setState(() {
        _gameData = cleaned;
        _isLoading = false;
      });

      // إرسال البيانات المولدة للخارج إذا تم توفير callback.
      if (widget.onGenerated != null) {
        widget.onGenerated!(cleaned);
      }
    } catch (e) {
      debugPrint('Game Generation Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إنشاء اللعبة: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ─── بناء واجهة التبويب ─────────────────────────────────────────────────────
  // يختار بين حالة التحميل، شاشة اللعبة، أو شاشة البدء.
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        final isArabic = _settings.locale.languageCode == 'ar';

        if (_isLoading) return _buildLoadingState(isDark, isArabic);

        if (_gameData != null) {
          return Stack(
            children: [
              _buildCurrentGameScreen(() {
                setState(() {
                  _gameData = null;
                });
              }),
              Positioned(
                top: 10,
                right: 20,
                child: IconButton(
                  onPressed: _generateGame,
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                  tooltip: isArabic ? 'إعادة توليد اللعبة' : 'Regenerate Game',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black26,
                  ),
                ),
              ),
            ],
          );
        }

        return _buildGenerateState(isDark, isArabic);
      },
    );
  }

  // ─── اختيار شاشة اللعبة بين ذاكرة أو اختبار ───────────────────────────────
  Widget _buildCurrentGameScreen(VoidCallback onBack) {
    final data = jsonDecode(_gameData!);
    if (data.containsKey('pairs')) {
      return MemoryGameScreen(aiJsonResponse: _gameData!, onBack: onBack);
    } else if (data.containsKey('questions')) {
      return QuizGameScreen(aiJsonResponse: _gameData!, onBack: onBack);
    }
    return const Center(child: Text('Unknown game format'));
  }

  // ─── شاشة التحميل أثناء انتظار الذكاء الاصطناعي ──────────────────────────────
  Widget _buildLoadingState(bool isDark, bool isArabic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            isArabic ? 'جاري تحويل الموضوع إلى لعبة ممتعة...' : 'Turning topic into a fun game...',
            style: GoogleFonts.inter(color: isDark ? Colors.white70 : AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── شاشة اختيار نوع اللعبة قبل التوليد ───────────────────────────────────
  Widget _buildGenerateState(bool isDark, bool isArabic) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videogame_asset_outlined, size: 64, color: Colors.orange),
            ),
            const SizedBox(height: 32),
            Text(
              isArabic ? 'اختر تحدي الذكاء المفضل لديك' : 'Choose Your Smart Challenge',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isArabic
                ? 'تعلم بطريقة ممتعة وتفاعلية من خلال الألعاب الذكية.'
                : 'Learn in a fun and interactive way through smart games.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            const SizedBox(height: 40),
            _buildGameTypeCard(
              title: isArabic ? 'لعبة الذاكرة' : 'Memory Match',
              description: isArabic ? 'طابق المصطلحات بتعريفاتها' : 'Match terms with definitions',
              icon: Icons.psychology_outlined,
              type: 'memory',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildGameTypeCard(
              title: isArabic ? 'تحدي الأسئلة' : 'Quiz Challenge',
              description: isArabic ? 'أجب على الأسئلة السريعة' : 'Answer fast questions',
              icon: Icons.quiz_outlined,
              type: 'quiz',
              isDark: isDark,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateGame,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: Text(isArabic ? 'بدء التوليد واللعب' : 'Generate & Play'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── بطاقة اختيار نوع اللعبة ────────────────────────────────────────────────
  // تعرض الخيار وتحدد إذا كان مختاراً بصرياً.
  Widget _buildGameTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required String type,
    required bool isDark,
  }) {
    final isSelected = _selectedGameType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedGameType = type),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.withOpacity(0.05))
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orange : (isDark ? Colors.white10 : Colors.grey.shade200),
            width: 2,
          ),
          boxShadow: isSelected ? [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 10)] : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.orange),
          ],
        ),
      ),
    );
  }
}
