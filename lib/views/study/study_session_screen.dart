import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/task_service.dart';
import '../../core/services/settings_service.dart';
import '../tasks/tabs/summary_tab.dart';
import '../tasks/tabs/flashcards_tab.dart';
import '../tasks/tabs/quiz_tab.dart';
import '../tasks/tabs/plan_tab.dart';
import '../tasks/tabs/audio_summary_tab.dart';
import '../chat/chat_screen.dart';
import '../mindmap/mind_map_screen.dart';
import '../tasks/tabs/slides_tab.dart';
import '../tasks/tabs/table_tab.dart';
import '../tasks/tabs/video_tab.dart';
import '../tasks/tabs/game_tab.dart';
import '../tasks/tabs/visual_tab.dart';

class StudySessionScreen extends StatefulWidget {
  final String topic;
  final Map<String, dynamic>? initialTools;

  const StudySessionScreen({
    super.key,
    required this.topic,
    this.initialTools,
  });

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TaskService _taskService = TaskService();
  final SettingsService _settings = SettingsService();
  bool _showSaveButton = true;
  
  // Track all generated contents for different tools
  final Map<String, dynamic> _generatedTools = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 12, vsync: this);
    _tabController.addListener(_handleTabSelection);
    if (widget.initialTools != null) {
      _showSaveButton = false; // Hide save button if we're viewing a saved session
    }
  }

  void _handleTabSelection() {
    setState(() {
      _showSaveButton = _tabController.index != 5; // Hide for AI Chat
    });
  }

  void _onToolGenerated(String type, dynamic content) {
    _generatedTools[type] = content;
  }

  Future<void> _saveAllTools() async {
    final isArabic = _settings.locale.languageCode == 'ar';
    if (_generatedTools.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'لم يتم توليد أي محتوى بعد.' : 'No tools generated yet.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _taskService.saveSession(
        topic: widget.topic,
        subject: 'General',
        tools: Map<String, dynamic>.from(_generatedTools),
      );

      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'تم حفظ الجلسة بنجاح!' : 'Session saved!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'فشل الحفظ: $e' : 'Failed to save tools: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getActiveColor() {
    switch (_tabController.index) {
      case 3: return Colors.red;
      case 6: return Colors.blue;
      case 7: return Colors.orange;
      case 9: return Colors.blue;
      default: return AppColors.primary;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        final isArabic = _settings.locale.languageCode == 'ar';

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            elevation: 0,
            title: Text(
              widget.topic, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 18,
                color: isDark ? Colors.white : AppColors.textPrimary
              )
            ),
            actions: [
              if (_showSaveButton)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: TextButton.icon(
                    onPressed: _saveAllTools,
                    icon: const Icon(Icons.save_outlined, size: 20, color: AppColors.primary),
                    label: Text(
                      isArabic ? 'حفظ الكل' : 'Save All',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: _getActiveColor(),
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              indicatorColor: _getActiveColor(),
              tabs: [
                Tab(text: isArabic ? 'خطة الدراسة' : 'Study Plan', icon: const Icon(Icons.event_note_outlined)),
                Tab(text: isArabic ? 'الملخص' : 'Summary', icon: const Icon(Icons.description_outlined)),
                Tab(text: isArabic ? 'البودكاست' : 'Podcast', icon: const Icon(Icons.podcasts_outlined)),
                Tab(text: isArabic ? 'الفيديو' : 'Video', icon: const Icon(Icons.play_circle_outline)),
                Tab(text: isArabic ? 'المعرض' : 'Gallery', icon: const Icon(Icons.palette_outlined)),
                Tab(text: isArabic ? 'دردشة AI' : 'AI Chat', icon: const Icon(Icons.chat_bubble_outline)),
                Tab(text: isArabic ? 'جدول بيانات' : 'Spreadsheet', icon: const Icon(Icons.table_chart_outlined)),
                Tab(text: isArabic ? 'الخريطة الذهنية' : 'Mind Map', icon: const Icon(Icons.account_tree_outlined)),
                Tab(text: isArabic ? 'البطاقات' : 'Flashcards', icon: const Icon(Icons.style_outlined)),
                Tab(text: isArabic ? 'الشرائح' : 'Slides', icon: const Icon(Icons.slideshow_outlined)),
                Tab(text: isArabic ? 'اللعبة' : 'Game', icon: const Icon(Icons.videogame_asset_outlined)),
                Tab(text: isArabic ? 'الاختبار' : 'Quiz', icon: const Icon(Icons.quiz_outlined)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              PlanTab(
                topic: widget.topic,
                onGenerated: (data) => _onToolGenerated('Plan', data),
                initialData: widget.initialTools?['Plan'],
              ),
              SummaryTab(
                topic: widget.topic,
                onGenerated: (data) => _onToolGenerated('Summary', data),
                initialData: widget.initialTools?['Summary'],
              ),
              AudioSummaryTab(
                topic: widget.topic,
                onGenerated: (data) => _onToolGenerated('AudioSummary', data),
                initialData: widget.initialTools?['AudioSummary'],
              ),
              VideoTab(
                topic: widget.topic,
                onGenerated: (data) => _onToolGenerated('Video', data),
                initialData: widget.initialTools?['Video'],
              ),
              VisualTab(
                topic: widget.topic,
                onGenerated: (data) => _onToolGenerated('Visual', data),
                initialData: widget.initialTools?['Visual'],
              ),
              ChatTab(topic: widget.topic), 
              TableTab(
                topic: widget.topic,
                onGenerated: (data) => _onToolGenerated('Table', data),
                initialData: widget.initialTools?['Table'],
              ),
              MindMapTab(
                topic: widget.topic,
                onGenerated: (data) => _onToolGenerated('MindMap', data),
                initialData: widget.initialTools?['MindMap'],
              ),
              FlashcardsTab(
                topic: widget.topic,
                onGenerated: (data) => _onToolGenerated('Flashcards', data),
                initialData: widget.initialTools?['Flashcards'],
              ),
              SlidesTab(
                topic: widget.topic,
                onGenerated: (data) => _onToolGenerated('Slides', data),
                initialData: widget.initialTools?['Slides'],
              ),
              GameTab(
                topic: widget.topic,
                onGenerated: (data) => _onToolGenerated('Game', data),
                initialData: widget.initialTools?['Game'],
              ),
              QuizTab(
                topic: widget.topic,
                onGenerated: (data) => _onToolGenerated('Quiz', data),
                initialData: widget.initialTools?['Quiz'],
              ),
            ],
          ),
        );
      }
    );
  }
}

class ChatTab extends StatelessWidget {
  final String topic;
  const ChatTab({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return ChatScreen(initialTopic: topic);
  }
}

class MindMapTab extends StatelessWidget {
  final String topic;
  final Function(dynamic)? onGenerated;
  final String? initialData;
  const MindMapTab({super.key, required this.topic, this.onGenerated, this.initialData});

  @override
  Widget build(BuildContext context) {
    return MindMapScreen(topic: topic, onGenerated: onGenerated, initialData: initialData);
  }
}
