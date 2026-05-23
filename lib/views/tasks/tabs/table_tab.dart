import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/groq_service.dart';
import '../../../core/services/settings_service.dart';

// ─── تبويب الجدول ────────────────────────────────────────────────────────────
// ينشئ جدول معلومات من الذكاء الاصطناعي ويعرضه مع نسخ سريع إلى الحافظة.
class TableTab extends StatefulWidget {
  final String topic;
  final Function(String)? onGenerated;
  final String? initialData;
  const TableTab({super.key, required this.topic, this.onGenerated, this.initialData});

  @override
  State<TableTab> createState() => _TableTabState();
}

class _TableTabState extends State<TableTab> with AutomaticKeepAliveClientMixin {
  final GroqService _groqService = GroqService();
  final SettingsService _settings = SettingsService();
  final TextEditingController _descriptionController = TextEditingController();
  String? _tableData;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _tableData = widget.initialData;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Requests a data table from the AI service and stores the Markdown table result.
  Future<void> _generateTable() async {
    setState(() => _isLoading = true);
    try {
      final result = await _groqService.generateTable(
        widget.topic, 
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null
      );
      if (mounted) {
        setState(() {
          _tableData = result;
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

  // Copies the generated table markdown text to the system clipboard.
  void _copyToClipboard() {
    final isArabic = _settings.locale.languageCode == 'ar';
    if (_tableData != null) {
      Clipboard.setData(ClipboardData(text: _tableData!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'تم نسخ الجدول إلى الحافظة' : 'Table copied to clipboard'),
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

    if (_tableData == null) {
      return _buildGenerateState(isDark, isArabic);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildHeader(isDark, isArabic),
        const SizedBox(height: 20),
        _buildDescriptionField(isDark, isArabic),
        const SizedBox(height: 20),
        _buildTableCard(isDark, isArabic),
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
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.table_chart_rounded, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'جدول البيانات' : 'Data Table',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
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

  Widget _buildTableCard(bool isDark, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkDivider : Colors.blue.withOpacity(0.05), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'الجدول المولد' : 'Generated Table',
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
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                // This empty callback intercepts the drag and prevents TabBarView from swiping
              },
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: IntrinsicWidth(
                  child: MarkdownBody(
                    data: _tableData!,
                    shrinkWrap: true,
                    styleSheet: MarkdownStyleSheet(
                      tableBorder: TableBorder.all(
                        color: isDark ? AppColors.darkDivider : Colors.grey.shade300,
                      ),
                      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      tableHead: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      tableBody: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      p: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        height: 1.5,
                      ),
                      tableHeadAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(bool isDark, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 2,
        style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: isArabic ? 'وصف مخصص للجدول (اختياري)...' : 'Custom table description (optional)...',
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 14),
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isArabic) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _generateTable,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(isArabic ? 'إعادة توليد الجدول' : 'Regenerate Table'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _settings.isDarkMode ? AppColors.darkCard : AppColors.white,
              foregroundColor: Colors.blue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.blue, width: 1.5),
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
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.table_view_rounded, size: 64, color: Colors.blue),
            ),
            const SizedBox(height: 32),
            Text(
              isArabic ? 'تحويل البيانات إلى جدول' : 'Transform Data to Table',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              isArabic ? 'نظم المعلومات والبيانات المتعلقة بالموضوع في جدول احترافي.' : 'Organize topic-related information and data into a professional table.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            
            // Description Field (Optional)
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: isArabic ? 'يرجى وصف جدول البيانات المراد انشاؤه (اختياري)...' : 'Please describe the spreadsheet you want to create (optional)...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateTable,
                icon: const Icon(Icons.bolt_rounded, color: Colors.white),
                label: Text(isArabic ? 'توليد الجدول' : 'Generate Table', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.blue.withOpacity(0.4),
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
                height: 300,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
