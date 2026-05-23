import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/video_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/groq_service.dart';
import '../../../widgets/custom_video_player.dart';

// ─── تبويب الفيديو ────────────────────────────────────────────────────────────
// يبحث عن فيديو تعليمي مناسب باستخدام GroqService للترجمة ثم VideoService لجلب رابط.
class VideoTab extends StatefulWidget {
  final String topic;
  final Function(String)? onGenerated;
  final String? initialData;

  const VideoTab({
    super.key,
    required this.topic,
    this.onGenerated,
    this.initialData,
  });

  @override
  State<VideoTab> createState() => _VideoTabState();
}

class _VideoTabState extends State<VideoTab> with AutomaticKeepAliveClientMixin {
  final SettingsService _settings = SettingsService();
  bool _isLoading = false;
  String? _videoUrl;
  String _selectedLanguage = 'ar';
  int _attemptCount = 0; // Track number of searches to get different videos

  final TextEditingController _topicController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _topicController.text = widget.topic;
    _selectedLanguage = _settings.locale.languageCode == 'ar' ? 'ar' : 'en';
    
    if (widget.initialData != null && widget.initialData!.startsWith('http')) {
      _videoUrl = widget.initialData;
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  // Generates a video search query, optionally translates the topic, then fetches a video URL.
  Future<void> _generateAIVideo() async {
    final isArabic = _settings.locale.languageCode == 'ar';
    setState(() => _isLoading = true);

    try {
      String searchTopic = _topicController.text.isNotEmpty ? _topicController.text : widget.topic;
      final groq = GroqService();

      String optimizedQuery;
      if (_selectedLanguage == 'ar') {
        optimizedQuery = 'شرح $searchTopic تعليمي';
      } else {
        final englishTopic = await groq.translateToEnglish(searchTopic);
        optimizedQuery = '$englishTopic educational lesson explanation';
      }

      // Fetch educational video using VideoService with the current attempt index
      final result = await VideoService.generateVideo(optimizedQuery, index: _attemptCount);

      if (mounted) {
        setState(() {
          _videoUrl = result;
          _isLoading = false;
          _attemptCount++; // Increment for the next time they search another video
        });

        if (result != null && widget.onGenerated != null) {
          widget.onGenerated!(result);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'فشل جلب الفيديو: $e' : 'Failed to fetch video: $e'),
            backgroundColor: AppColors.error,
          ),
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

        if (_isLoading) return _buildLoadingState(isDark, isArabic);
        if (_videoUrl == null) return _buildGenerateState(isDark, isArabic);

        return _buildVideoPlayerView(isDark, isArabic);
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
            isArabic ? 'جاري البحث عن فيديوهات تعليمية...' : 'Searching for educational videos...',
            style: GoogleFonts.inter(color: isDark ? Colors.white70 : AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic ? 'يتم الآن جلب فيديو مناسب لموضوعك' : 'Fetching a relevant video for your topic',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_motion_rounded, size: 64, color: Colors.red),
            ),
            const SizedBox(height: 32),
            Text(
              isArabic ? 'جلب فيديو تعليمي' : 'Fetch Educational Video',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              isArabic 
                ? 'استخدم مكتبة ضخمة لجلب فيديو تعليمي جاهز ومناسب لموضوعك.' 
                : 'Use a vast library to fetch a ready-made educational video for your topic.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildTopicInput(isDark, isArabic),
            const SizedBox(height: 24),
            _buildLanguageSelection(isDark, isArabic),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateAIVideo,
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                label: Text(isArabic ? 'البحث عن فيديو' : 'Search for Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
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

  Widget _buildLanguageSelection(bool isDark, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'لغة الفيديو المفضل' : 'Preferred Video Language',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildLangChip('ar', isArabic ? 'بالعربية' : 'Arabic', isDark),
            const SizedBox(width: 12),
            _buildLangChip('en', 'English', isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildLangChip(String langCode, String label, bool isDark) {
    final isSelected = _selectedLanguage == langCode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedLanguage = langCode),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.red : (isDark ? AppColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.red : (isDark ? Colors.white10 : Colors.grey.shade300),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicInput(bool isDark, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'موضوع الفيديو' : 'Video Topic',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: TextField(
            controller: _topicController,
            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: isArabic ? 'أدخل موضوع الفيديو هنا...' : 'Enter video topic here...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.movie_filter_outlined, color: Colors.red),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayerView(bool isDark, bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'الفيديو التعليمي' : 'Educational Video',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _topicController.text,
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          GeneratedVideoPlayer(videoUrl: _videoUrl!),
          const SizedBox(height: 32),
          _buildTopicInput(isDark, isArabic),
          const SizedBox(height: 24),
          _buildLanguageSelection(isDark, isArabic),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _generateAIVideo,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(isArabic ? 'البحث عن فيديو آخر' : 'Search Another Video'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
