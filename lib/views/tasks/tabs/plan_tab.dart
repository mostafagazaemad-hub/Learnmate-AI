import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/groq_service.dart';
import '../../../core/services/settings_service.dart';

// ─── تبويب خطة الدراسة ──────────────────────────────────────────────────────
// هذا التبويب يطلب من الذكاء الاصطناعي توليد خطة دراسة منظمة، ثم يعرض الأيام والمهام.
// يحتفظ بحالة التقدم والتثبيت على الشاشة الرئيسية إذا تم تثبيت الخطة.
class PlanTab extends StatefulWidget {
  final String topic;
  final Function(String)? onGenerated;
  final String? initialData;
  const PlanTab({super.key, required this.topic, this.onGenerated, this.initialData});

  @override
  State<PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<PlanTab> with AutomaticKeepAliveClientMixin {
  final GroqService _groqService = GroqService();
  final SettingsService _settings = SettingsService();
  List<dynamic>? _planData;
  String? _totalDuration;
  String? _rawPlanData;
  bool _isLoading = false;
  int _selectedDayIndex = 0;
  final Map<String, bool> _completedTasks = {};
  final Map<String, bool> _notificationsEnabled = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _rawPlanData = widget.initialData;
      _parsePlan(widget.initialData!);
      
      // Load saved state if this is the pinned plan
      if (_settings.isPlanPinned && _settings.pinnedPlanTopic == widget.topic && _settings.pinnedPlanTasksState != null) {
        try {
          final Map<String, dynamic> state = jsonDecode(_settings.pinnedPlanTasksState!);
          state.forEach((key, value) {
            _completedTasks[key] = value as bool;
          });
        } catch (e) {
          debugPrint('Error loading task state: $e');
        }
      }
    }
  }

  // Parses the JSON response from Groq into structured plan data.
  void _parsePlan(String jsonString) {
    try {
      String cleaned = jsonString.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(RegExp(r'```[a-z]*\n?'), '')
            .replaceFirst(RegExp(r'```$'), '')
            .trim();
      }
      final data = jsonDecode(cleaned);
      setState(() {
        _planData = data['plan'];
        _totalDuration = data['total_duration_estimate'];
      });
      
      // Update progress if this plan is pinned
      if (_settings.isPlanPinned && _settings.pinnedPlanTopic == widget.topic) {
        _settings.updatePinnedProgress(_calculateProgress());
      }
    } catch (e) {
      debugPrint('Error parsing plan: $e');
    }
  }

  // Requests a study plan from GroqService and updates the UI with the returned JSON.
  Future<void> _generatePlan() async {
    setState(() => _isLoading = true);
    try {
      final result = await _groqService.generateStudyPlan(widget.topic);
      _rawPlanData = result;
      _parsePlan(result);
      if (widget.onGenerated != null) {
        widget.onGenerated!(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate plan')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateProgress() {
    if (_planData == null) return 0;
    int totalTasks = 0;
    int completedCount = 0;
    for (var day in _planData!) {
      final tasks = day['tasks'] as List;
      for (int i = 0; i < tasks.length; i++) {
        totalTasks++;
        final taskId = '${day['day']}_$i';
        if (_completedTasks[taskId] == true) {
          completedCount++;
        }
      }
    }
    return totalTasks == 0 ? 0 : completedCount / totalTasks;
  }

  void _togglePin() {
    if (_settings.isPlanPinned && _settings.pinnedPlanTopic == widget.topic) {
      _settings.unpinPlan();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_settings.locale.languageCode == 'ar' ? 'تمت الإزالة من الشاشة الرئيسية' : 'Removed from Home Screen'))
      );
    } else {
      _settings.pinPlan(
        widget.topic, 
        _calculateProgress(), 
        _rawPlanData ?? "", 
        tasksState: jsonEncode(_completedTasks)
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_settings.locale.languageCode == 'ar' ? 'تمت الإضافة إلى الشاشة الرئيسية' : 'Added to Home Screen'))
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        final isArabic = _settings.locale.languageCode == 'ar';

        if (_planData == null && !_isLoading) {
          return _buildGenerateState(isDark, isArabic);
        }

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final progress = _calculateProgress();
        final currentDay = _planData![_selectedDayIndex];
        final tasks = currentDay['tasks'] as List;
        final isPinned = _settings.isPlanPinned && _settings.pinnedPlanTopic == widget.topic;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildPlanHeader(progress, isArabic),
            const SizedBox(height: 16),
            
            // Add to Home Screen Button
            _buildPinButton(isPinned, isArabic),
            const SizedBox(height: 24),

            _buildDaySelector(isDark),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? "جدول ${currentDay['label']}" : "${currentDay['label']} Schedule",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
                ),
                if (_totalDuration != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          _totalDuration!,
                          style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            ...tasks.asMap().entries.map((entry) {
              final i = entry.key;
              final task = entry.value;
              final taskId = '${currentDay['day']}_$i';
              return _buildTaskCard(task, taskId, isDark);
            }),

            const SizedBox(height: 24),
            _buildRecommendationCard(isArabic, isDark),
            const SizedBox(height: 40),
          ],
        );
      }
    );
  }

  Widget _buildPinButton(bool isPinned, bool isArabic) {
    return InkWell(
      onTap: _togglePin,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPinned ? AppColors.success.withOpacity(0.1) : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isPinned ? AppColors.success.withOpacity(0.3) : AppColors.primary.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPinned ? Icons.check_circle_rounded : Icons.add_to_home_screen_rounded,
              color: isPinned ? AppColors.success : AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              isPinned 
                ? (isArabic ? 'مضاف إلى الشاشة الرئيسية' : 'Added to Home Screen')
                : (isArabic ? 'إضافة الخطة إلى الشاشة الرئيسية' : 'Add Plan to Home Screen'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPinned ? AppColors.success : AppColors.primary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanHeader(double progress, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'تقدم الخطة الدراسية' : 'Study Plan Progress',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isArabic ? 'استمر في العمل الرائع! أنت تتقدم.' : 'Keep up the great work! You are ahead.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: Colors.white,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(bool isDark) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _planData!.length,
        itemBuilder: (context, index) {
          final day = _planData![index];
          final isSelected = _selectedDayIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 75,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.darkDivider : Colors.grey.shade200)),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
                    : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day['label'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day['date']?.toString() ?? '',
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.textPrimary),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(dynamic task, String taskId, bool isDark) {
    final isCompleted = _completedTasks[taskId] ?? false;
    final isNotified = _notificationsEnabled[taskId] ?? false;
    final duration = task['duration'] ?? '30 mins';
    final priority = task['priority'] ?? 'Medium';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCompleted ? AppColors.primary.withOpacity(0.3) : (isDark ? AppColors.darkDivider : Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _completedTasks[taskId] = !isCompleted);
                if (_settings.isPlanPinned && _settings.pinnedPlanTopic == widget.topic) {
                  _settings.updatePinnedProgress(_calculateProgress(), tasksState: jsonEncode(_completedTasks));
                }
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isCompleted ? AppColors.primary : (isDark ? AppColors.darkDivider : Colors.grey.shade300), width: 2),
                ),
                child: isCompleted ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task['title'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? AppColors.textSecondary : (isDark ? Colors.white : AppColors.textPrimary),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _notificationsEnabled[taskId] = !isNotified);
                        },
                        icon: Icon(
                          isNotified ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                          color: isNotified ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade400),
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task['description'],
                    style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildTaskBadge(Icons.access_time_filled_rounded, task['time'], Colors.blue),
                      const SizedBox(width: 12),
                      _buildTaskBadge(Icons.hourglass_bottom_rounded, duration, Colors.orange),
                      const SizedBox(width: 12),
                      _buildTaskBadge(Icons.flag_rounded, priority, priority == 'High' ? Colors.red : Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(bool isArabic, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkDivider : Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_rounded, color: Colors.blue, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'نصيحة ذكية' : 'Smart Tip',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.blue : Colors.blue.shade900),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic ? 'أخذ فترات راحة قصيرة يزيد من تركيزك بنسبة 20%.' : 'Taking short breaks increases your focus by 20%.',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.blue.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateState(bool isDark, bool isArabic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_note_outlined, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            isArabic ? 'لا توجد خطة دراسية بعد' : 'No Study Plan yet', 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)
          ),
          const SizedBox(height: 12),
          Text(
            isArabic ? 'قم بتوليد خطة دراسية مخصصة لهذا الموضوع.' : 'Generate a personalized study plan for this topic.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _generatePlan,
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: Text(isArabic ? 'توليد الخطة' : 'Generate Plan', style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
