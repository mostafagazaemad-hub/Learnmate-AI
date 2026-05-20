import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/groq_service.dart';
import '../../../core/services/settings_service.dart';

class SummaryTab extends StatefulWidget {
  final String topic;
  final Function(String)? onGenerated;
  final String? initialData;
  const SummaryTab({super.key, required this.topic, this.onGenerated, this.initialData});

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> with AutomaticKeepAliveClientMixin {
  final GroqService _groqService = GroqService();
  final SettingsService _settings = SettingsService();
  String? _summary;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _summary = widget.initialData;
    }
  }

  Future<void> _generateSummary() async {
    setState(() => _isLoading = true);
    try {
      final result = await _groqService.generateSummary(widget.topic);
      if (mounted) {
        setState(() {
          _summary = result;
          _isLoading = false;
        });
        if (widget.onGenerated != null) {
          widget.onGenerated!(result);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _copyToClipboard() {
    final isArabic = _settings.locale.languageCode == 'ar';
    if (_summary != null) {
      Clipboard.setData(ClipboardData(text: _summary!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'تم نسخ الملخص إلى الحافظة' : 'Summary copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
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

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildContent(isDark, isArabic),
        );
      },
    );
  }

  Widget _buildContent(bool isDark, bool isArabic) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_summary == null) {
      return _buildGenerateState(isDark, isArabic);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildHeader(isDark, isArabic),
        const SizedBox(height: 20),
        _buildSummaryCard(isDark, isArabic),
        const SizedBox(height: 24),
        _buildActionButtons(isArabic),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHeader(bool isDark, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'ملخص الموضوع' : 'Topic Summary',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    widget.topic,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(bool isDark, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.primary.withOpacity(0.05), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'رؤى رئيسية' : 'Key Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: _copyToClipboard,
                  icon: Icon(Icons.copy_all_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, size: 22),
                  tooltip: isArabic ? 'نسخ إلى الحافظة' : 'Copy to clipboard',
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(20),
            child: MarkdownBody(
              data: _summary!,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(fontSize: 16, height: 1.6, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                h1: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
                h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
                h3: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
                listBullet: const TextStyle(fontSize: 16, color: AppColors.primary),
                blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                blockquoteDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(left: BorderSide(color: AppColors.primary, width: 4)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isArabic) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _generateSummary,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(isArabic ? 'إعادة توليد الملخص' : 'Regenerate Summary'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _settings.isDarkMode ? AppColors.darkCard : AppColors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

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
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 32),
            Text(
              isArabic ? 'تحليل وتلخيص' : 'Analyze & Summarize',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              isArabic ? 'حول هذا الموضوع إلى ملخص موجز واحترافي مدعوم بالذكاء الاصطناعي.' : 'Transform this topic into a concise, professional summary powered by AI.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateSummary,
                icon: const Icon(Icons.bolt_rounded, color: Colors.white),
                label: Text(isArabic ? 'توليد الملخص' : 'Generate Summary', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.4),
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

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Shimmer.fromColors(
          baseColor: _settings.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: _settings.isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 150, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 12),
              Container(width: 250, height: 32, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                height: 400,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
