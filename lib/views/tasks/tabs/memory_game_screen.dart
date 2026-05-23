import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. نموذج يمثل كل بطاقة في اللعبة
class MemoryCard {
  final String text;
  final int pairId; // رقم يربط المصطلح بتعريفه
  bool isFlipped;
  bool isMatched;

  MemoryCard({
    required this.text,
    required this.pairId,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class MemoryGameScreen extends StatefulWidget {
  final String aiJsonResponse; // JSON المولّد من خدمة الذكاء الاصطناعي
  final VoidCallback? onBack; // دالة الرجوع إلى الشاشة السابقة

  const MemoryGameScreen({super.key, required this.aiJsonResponse, this.onBack});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  List<MemoryCard> cards = [];
  String gameMessage = "جاري تجهيز اللعبة...";

  MemoryCard? firstSelected;
  MemoryCard? secondSelected;
  bool isProcessing = false; // يمنع الضغط المتكرر قبل انتهاء المطابقة
  int score = 0;

  @override
  void initState() {
    super.initState();
    _setupGame();
  }

  /// يقرأ استجابة AI ويحوّل الأزواج إلى بطاقات قابلة للعرض.
  void _setupGame() {
    try {
      final data = jsonDecode(widget.aiJsonResponse);
      setState(() {
        gameMessage = data['game_message'] ?? 'اختر بطاقتين متطابقتين!';
      });

      final List<dynamic> pairs = data['pairs'];
      int idCounter = 0;

      // إنشاء بطاقة لكل مصطلح وتعريف، مع ربطهما بالـ pairId نفسه.
      for (var pair in pairs) {
        cards.add(MemoryCard(text: pair['term'], pairId: idCounter));
        cards.add(MemoryCard(text: pair['definition'], pairId: idCounter));
        idCounter++;
      }

      // خلط البطاقات حتى تظهر بشكل عشوائي على الشاشة.
      cards.shuffle();
    } catch (e) {
      debugPrint("خطأ في قراءة الـ JSON: $e");
    }
  }

  /// يتعامل مع ضغطة المستخدم على بطاقة.
  void _onCardTap(MemoryCard card) {
    if (card.isFlipped || card.isMatched || isProcessing) return;

    setState(() {
      card.isFlipped = true;

      if (firstSelected == null) {
        firstSelected = card;
      } else {
        secondSelected = card;
        isProcessing = true;
        _checkForMatch();
      }
    });
  }

  /// يتحقق مما إذا كانت البطاقتان المتاخرتان متطابقتين.
  void _checkForMatch() {
    if (firstSelected!.pairId == secondSelected!.pairId) {
      setState(() {
        firstSelected!.isMatched = true;
        secondSelected!.isMatched = true;
        score++;
        _resetSelection();
      });

      // إذا أكمل المستخدم كل الأزواج، نعرض إشعار نجاح.
      if (score == 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('مبروك! لقد أكملت التحدي بنجاح! 🏆'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // إذا كانت البطاقة خاطئة، نعيد إخفائها بعد تأخير بسيط.
      Timer(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            firstSelected!.isFlipped = false;
            secondSelected!.isFlipped = false;
            _resetSelection();
          });
        }
      });
    }
  }

  /// إعادة تهيئة الاختيارات حتى يتمكن المستخدم من محاولة زوج آخر.
  void _resetSelection() {
    firstSelected = null;
    secondSelected = null;
    isProcessing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('لعبة الذاكرة الذكية', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // عرض رسالة اللعبة في الأعلى.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                gameMessage,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            // شبكة البطاقات التي يعرضها المستخدم.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape = constraints.maxWidth > constraints.maxHeight;
                  final crossAxisCount = isLandscape ? 5 : 2;
                  final aspectRatio = isLandscape ? 1.4 : 1.1;

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: aspectRatio,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return GestureDetector(
                        onTap: () => _onCardTap(card),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: card.isFlipped || card.isMatched ? Colors.white : AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: card.isMatched ? Colors.green : AppColors.primary,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(12),
                          child: card.isFlipped || card.isMatched
                              ? Text(
                                  card.text,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                )
                              : const Icon(Icons.psychology_outlined, color: Colors.white, size: 48),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // زر إعادة اللعب بعد إنهاء اللعبة.
            if (score == 5)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      cards.clear();
                      score = 0;
                      _setupGame();
                    });
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('اللعب مرة أخرى'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
