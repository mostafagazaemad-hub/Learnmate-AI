import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/groq_service.dart';
import '../../../core/services/settings_service.dart';

// ─── تبويب الشرائح ────────────────────────────────────────────────────────────
// هذا التبويب يولد شرائح عرض تعليمية من الذكاء الاصطناعي ويعرضها داخل WebView.
class Slide {
  final String title;
  final String layout;
  final String htmlContent;
  
  Slide({
    required this.title, 
    required this.layout,
    required this.htmlContent,
  });
}

class SlidesTab extends StatefulWidget {
  final String topic;
  final Function(String)? onGenerated;
  final String? initialData;
  const SlidesTab({super.key, required this.topic, this.onGenerated, this.initialData});

  @override
  State<SlidesTab> createState() => _SlidesTabState();
}

class _SlidesTabState extends State<SlidesTab> with AutomaticKeepAliveClientMixin {
  final GroqService _groqService = GroqService();
  final SettingsService _settings = SettingsService();
  List<Slide>? _slides;
  bool _isLoading = false;
  int _currentIndex = 0;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _parseInitialData(widget.initialData!);
    }
  }

  // Parses stored JSON slide payload into Slide objects when the tab opens with saved data.
  void _parseInitialData(String data) {
    try {
      final json = jsonDecode(data);
      final List<dynamic> raw = json['slides'] ?? [];
      _slides = raw.map((s) => Slide(
        title: s['title'] ?? 'Slide',
        layout: s['layout'] ?? 'TwoColumn',
        htmlContent: s['htmlContent'] ?? '',
      )).toList();
    } catch (e) {
      debugPrint('Error parsing slides data: $e');
    }
  }

  // Calls GroqService to generate slides, then sanitizes and decodes AI JSON before displaying.
  Future<void> _generateSlides() async {
    setState(() => _isLoading = true);
    try {
      final result = await _groqService.generateSlides(
        widget.topic,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      );
      
      // Handle potential error messages from the service
      if (result.contains('⚠️')) {
        throw Exception(result.replaceAll('⚠️', '').trim());
      }

      String cleaned = result.trim();
      if (cleaned.contains('```')) {
        final start = cleaned.indexOf('{');
        final end = cleaned.lastIndexOf('}');
        if (start != -1 && end != -1) {
          cleaned = cleaned.substring(start, end + 1);
        }
      }

      final json = jsonDecode(cleaned);
      final List<dynamic> raw = json['slides'] ?? [];
      
      if (raw.isEmpty) {
        throw Exception('No slides were generated. Please try again.');
      }

      setState(() {
        _slides = raw.map((s) => Slide(
          title: s['title']?.toString() ?? 'Slide',
          layout: s['layout'] ?? 'TwoColumn',
          htmlContent: s['htmlContent'] ?? '',
        )).toList();
        _isLoading = false;
        _currentIndex = 0;
      });
      
      if (widget.onGenerated != null) {
        widget.onGenerated!(jsonEncode(json));
      }
    } catch (e) {
      debugPrint('Error generating slides: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        String errorMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg), 
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        final isArabic = _settings.locale.languageCode == 'ar';

        if (_slides == null && !_isLoading) return _buildGenerateState(isDark, isArabic);
        if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.blue));

        return Container(
          color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildDescriptionField(isDark, isArabic),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _slides!.length,
                  itemBuilder: (context, index) {
                    return SlideItem(
                      slide: _slides![index],
                      isDark: isDark,
                      isArabic: isArabic,
                      index: index,
                    );
                  },
                ),
              ),
              _buildBottomBar(isDark, isArabic),
            ],
          ),
        );
      }
    );
  }

  Widget _buildBottomBar(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isArabic ? 'عدد الشرائح: ${_slides?.length ?? 0}' : 'Total Slides: ${_slides?.length ?? 0}',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary),
          ),
          ElevatedButton.icon(
            onPressed: _generateSlides,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(isArabic ? 'إعادة التوليد' : 'Regenerate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_motion_rounded, size: 80, color: Colors.blue),
            ),
            const SizedBox(height: 32),
            Text(
              isArabic ? 'شرائح تعليمية احترافية' : 'Professional Educational Slides',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isArabic 
                ? 'قم بتوليد شرائح منظمة واحترافية لمساعدتك في الشرح والتقديم.' 
                : 'Generate structured, professional slides to help you explain and present.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600),
            ),
            const SizedBox(height: 48),
            _buildDescriptionField(isDark, isArabic),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _generateSlides,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  isArabic ? 'توليد الشرائح الآن' : 'Generate Slides Now', 
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField(bool isDark, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 1,
        style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: isArabic ? 'وصف مخصص للشرائح (مثلاً: ركز على الأمثلة)...' : 'Custom slide description (e.g., Focus on examples)...',
          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.edit_note, color: Colors.blue),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class SlideItem extends StatefulWidget {
  final Slide slide;
  final bool isDark;
  final bool isArabic;
  final int index;

  const SlideItem({
    required this.slide,
    required this.isDark,
    required this.isArabic,
    required this.index,
    super.key,
  });

  @override
  State<SlideItem> createState() => _SlideItemState();
}

class _SlideItemState extends State<SlideItem> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    if (!kIsWeb) {
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      _controller.setBackgroundColor(const Color(0x00000000));
    }
    _controller.loadHtmlString(_wrapHtml(widget.slide.htmlContent, widget.isDark));
  }

  @override
  void didUpdateWidget(SlideItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slide.htmlContent != widget.slide.htmlContent || oldWidget.isDark != widget.isDark) {
      _controller.loadHtmlString(_wrapHtml(widget.slide.htmlContent, widget.isDark));
    }
  }

  String _wrapHtml(String content, bool isDark) {
    final bgColor = isDark ? '#1e293b' : '#ffffff';
    final textColor = isDark ? '#f1f5f9' : '#0f172a';
    final accentColor = '#2196F3';
    final mutedColor = isDark ? '#94a3b8' : '#64748b';
    
    return """
      <!DOCTYPE html>
      <html dir="${widget.isArabic ? 'rtl' : 'ltr'}">
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0">
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&family=Noto+Sans+Arabic:wght@400;700&display=swap" rel="stylesheet">
        <style>
          :root {
            --primary: $accentColor;
            --bg: $bgColor;
            --text: $textColor;
            --text-muted: $mutedColor;
          }
          
          * { box-sizing: border-box; margin: 0; padding: 0; }
          
          body { 
            background-color: var(--bg); 
            color: var(--text); 
            font-family: 'Inter', 'Noto Sans Arabic', sans-serif; 
            padding: 30px;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
          }

          .slide-content {
            width: 100%;
            max-width: 800px;
            margin: 0 auto;
          }

          h1 { 
            font-size: 2.2rem; 
            font-weight: 800; 
            margin-bottom: 20px; 
            color: var(--primary);
            line-height: 1.3;
            word-wrap: break-word;
          }

          h2, h3 {
            font-size: 1.5rem;
            margin-bottom: 15px;
            color: var(--text);
            line-height: 1.4;
          }

          p { 
            font-size: 1.1rem; 
            line-height: 1.7; 
            color: var(--text); 
            opacity: 0.9;
            margin-bottom: 15px;
          }
          
          .subtitle { 
            font-size: 1.3rem; 
            color: var(--text-muted); 
            margin-top: -15px; 
            margin-bottom: 25px; 
            font-weight: 600;
          }

          /* Layout: Two Column - Responsive */
          .two-column { 
            display: flex; 
            flex-direction: row;
            gap: 30px; 
            margin-top: 20px;
          }
          @media (max-width: 600px) {
            .two-column { flex-direction: column; gap: 20px; }
          }
          .left, .right { flex: 1; display: flex; flex-direction: column; gap: 15px; }
          
          /* Layout: Timeline */
          .timeline { position: relative; padding-right: 25px; margin-top: 30px; }
          .timeline::after {
            content: ''; position: absolute; right: 0; top: 0; bottom: 0;
            width: 3px; background: rgba(99, 102, 241, 0.2); border-radius: 3px;
          }
          .timeline-item { position: relative; margin-bottom: 30px; padding-bottom: 10px; }
          .timeline-item::after { 
            content: ''; position: absolute; right: -3px; top: 5px; 
            width: 9px; height: 9px; background: var(--primary); border-radius: 50%; box-shadow: 0 0 0 4px var(--bg);
          }
          .date { font-weight: 800; color: var(--primary); font-size: 1.2rem; display: block; margin-bottom: 5px; }
          
          /* Layout: Stats */
          .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 20px; margin-top: 30px; }
          .stat-card { 
            background: rgba(99, 102, 241, 0.08); 
            padding: 20px; 
            border-radius: 16px; 
            text-align: center;
            border: 1px solid rgba(99, 102, 241, 0.15);
          }
          .stat-val { font-size: 2.5rem; font-weight: 800; color: var(--primary); display: block; margin-bottom: 5px; }
          .stat-label { font-size: 0.95rem; color: var(--text-muted); font-weight: 600; }

          ul { list-style: none; margin: 15px 0; }
          li { 
            position: relative; 
            padding-right: 25px; 
            margin-bottom: 12px; 
            font-size: 1.1rem;
            line-height: 1.6;
          }
          li::before { 
            content: '•'; position: absolute; right: 0; color: var(--primary); font-weight: bold; font-size: 1.4rem; top: -2px;
          }

          /* General Text Improvements */
          .text-center { text-align: center; }
          .highlight { color: var(--primary); font-weight: 700; }
        </style>
      </head>
      <body>
        <div class="slide-content">
          $content
        </div>
      </body>
      </html>
    """;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 500, // الارتفاع المرجعي للشرائح
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.slide.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: widget.isDark ? Colors.white70 : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: WebViewWidget(controller: _controller),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
