import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/groq_service.dart';
import '../../../core/services/settings_service.dart';

class Flashcard {
  final String front;
  final String back;
  Flashcard({required this.front, required this.back});
}

class FlashcardsTab extends StatefulWidget {
  final String topic;
  final Function(String)? onGenerated;
  final String? initialData;
  const FlashcardsTab({super.key, required this.topic, this.onGenerated, this.initialData});

  @override
  State<FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<FlashcardsTab> with AutomaticKeepAliveClientMixin {
  final GroqService _groqService = GroqService();
  final SettingsService _settings = SettingsService();
  List<Flashcard>? _cards;
  bool _isLoading = false;
  int _currentIndex = 0;
  bool _isFlipped = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      try {
        final json = jsonDecode(widget.initialData!);
        final List<dynamic> rawCards = json['flashcards'] ?? [];
        _cards = rawCards.map((c) => Flashcard(front: c['front'], back: c['back'])).toList();
      } catch (e) {
        debugPrint('Error parsing initial Flashcards data: $e');
      }
    }
  }

  Future<void> _generateCards() async {
    setState(() {
      _isLoading = true;
      _cards = null;
    });
    try {
      final result = await _groqService.generateFlashcards(widget.topic);
      
      String cleaned = result.trim();
      if (cleaned.contains('```')) {
        final start = cleaned.indexOf('{');
        final end = cleaned.lastIndexOf('}');
        if (start != -1 && end != -1) {
          cleaned = cleaned.substring(start, end + 1);
        }
      }

      final json = jsonDecode(cleaned);
      final List<dynamic> rawCards = json['flashcards'] ?? [];
      
      setState(() {
        _cards = rawCards.map((c) => Flashcard(
          front: c['front']?.toString() ?? 'Empty Question', 
          back: c['back']?.toString() ?? 'Empty Answer'
        )).toList();
        _isLoading = false;
        _currentIndex = 0;
        _isFlipped = false;
      });
      
      if (widget.onGenerated != null) {
        widget.onGenerated!(jsonEncode(json));
      }
    } catch (e) {
      debugPrint('Error generating flashcards: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_settings.locale.languageCode == 'ar' ? 'فشل التوليد: $e' : 'Failed to generate: $e'),
            backgroundColor: AppColors.error,
          )
        );
      }
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

        if (_cards == null && !_isLoading) {
          return _buildGenerateState(isDark, isArabic);
        }

        if (_isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(isArabic ? 'جاري توليد البطاقات...' : 'Generating Flashcards...', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
              ],
            ),
          );
        }

        if (_cards!.isEmpty) {
          return Center(child: Text(isArabic ? 'لم يتم العثور على بطاقات. حاول التوليد مجدداً.' : 'No flashcards found. Try regenerating.', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)));
        }

        final card = _cards![_currentIndex];

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'بطاقة ${_currentIndex + 1} / ${_cards!.length}' : 'Card ${_currentIndex + 1} / ${_cards!.length}', 
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                ),
                TextButton.icon(
                  onPressed: _isLoading ? null : _generateCards,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(isArabic ? 'إعادة توليد' : 'Regenerate'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _cards!.length,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              color: AppColors.primary,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => setState(() => _isFlipped = !_isFlipped),
              child: Container(
                height: 300,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: isDark ? Border.all(color: AppColors.darkDivider) : null,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 20)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isFlipped 
                        ? (isArabic ? 'الإجابة' : 'ANSWER') 
                        : (isArabic ? 'السؤال' : 'QUESTION'), 
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isFlipped ? card.back : card.front,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentIndex > 0 ? () => setState(() { _currentIndex--; _isFlipped = false; }) : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.divider),
                      foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    child: Text(isArabic ? 'السابق' : 'Previous'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentIndex < _cards!.length - 1 ? () => setState(() { _currentIndex++; _isFlipped = false; }) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isArabic ? 'التالي' : 'Next'),
                  ),
                ),
              ],
            ),
          ],
        );
      }
    );
  }

  Widget _buildGenerateState(bool isDark, bool isArabic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.style_outlined, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            isArabic ? 'لا توجد بطاقات بعد' : 'No Flashcards yet', 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)
          ),
          const SizedBox(height: 12),
          Text(
            isArabic ? 'قم بتوليد بطاقات تعليمية بالذكاء الاصطناعي لاختبار معرفتك.' : 'Generate AI flashcards to test your knowledge.', 
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _generateCards,
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: Text(isArabic ? 'توليد البطاقات' : 'Generate Cards', style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
