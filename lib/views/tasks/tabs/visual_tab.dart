import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/image_generation_service.dart';

// ─── تبويب الرسوم التوضيحية ───────────────────────────────────────────────────
// يولد صوراً تعليمية من خدمة الذكاء الاصطناعي ويعرضها مع خيارات تنزيل للمستعرض.

class VisualTab extends StatefulWidget {
  final String topic;
  final Function(String)? onGenerated;
  final String? initialData;

  const VisualTab({
    super.key,
    required this.topic,
    this.onGenerated,
    this.initialData,
  });

  @override
  State<VisualTab> createState() => _VisualTabState();
}

class _VisualTabState extends State<VisualTab> with AutomaticKeepAliveClientMixin {
  final SettingsService _settings = SettingsService();
  bool _isLoading = false;
  List<String>? _imageUrls;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      try {
        final decoded = jsonDecode(widget.initialData!);
        if (decoded is List) {
          _imageUrls = List<String>.from(decoded);
        } else {
          _imageUrls = [widget.initialData!];
        }
      } catch (e) {
        // Fallback for old single string URLs
        _imageUrls = [widget.initialData!];
      }
    }
  }

  // Generates illustration URLs using the image generation service.
  Future<void> _generateImage() async {
    setState(() {
      _isLoading = true;
      _imageUrls = null; // Clear old images to show fresh results
    });
    try {
      final urls = await ImageGenerationService.generateIllustrations(widget.topic);
      if (mounted) {
        setState(() {
          _imageUrls = urls.isNotEmpty ? urls : null;
          _isLoading = false;
        });
        if (urls.isNotEmpty && widget.onGenerated != null) {
          widget.onGenerated!(jsonEncode(urls));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل توليد الصورة: $e')),
        );
      }
    }
  }

  // Downloads the generated image.
  void _downloadImage(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة التنزيل ستتوفر قريباً في نسخة المتجر')),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        final isArabic = _settings.locale.languageCode == 'ar';

        if (_isLoading) return _buildLoadingState(isDark, isArabic);
        if (_imageUrls == null || _imageUrls!.isEmpty) return _buildGenerateState(isDark, isArabic);

        return _buildImageDisplay(isDark, isArabic);
      },
    );
  }

  Widget _buildLoadingState(bool isDark, bool isArabic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            isArabic ? 'جاري رسم لوحة تعليمية...' : 'Creating educational illustration...',
            style: GoogleFonts.inter(color: isDark ? Colors.white70 : AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateState(bool isDark, bool isArabic) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.palette_outlined, size: 80, color: Colors.teal),
            ),
            const SizedBox(height: 32),
            Text(
              isArabic ? 'المعرض البصري الذكي' : 'Smart Visual Gallery',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              isArabic 
                ? 'حول المفاهيم المعقدة إلى رسوم توضيحية احترافية تساعدك على التذكر.' 
                : 'Turn complex concepts into professional illustrations to help you remember.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _generateImage,
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(isArabic ? 'توليد لوحات تعليمية' : 'Generate Illustrations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay(bool isDark, bool isArabic) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.topic,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: _imageUrls!.length,
            itemBuilder: (context, index) {
              final url = _imageUrls![index];
              return Container(
                margin: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                        ),
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 300,
                              color: Colors.grey.withOpacity(0.1),
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _downloadImage(url),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: Text(isArabic ? 'تنزيل الصورة' : 'Download Image'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: OutlinedButton.icon(
            onPressed: _generateImage,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(isArabic ? 'إعادة رسم (مجموعة جديدة)' : 'Redraw (New Batch)'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}
