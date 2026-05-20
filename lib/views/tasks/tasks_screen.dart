import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/task_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/models/study_task.dart';
import '../chat/chat_screen.dart';
import '../settings/settings_screen.dart';
import 'add_task_screen.dart';
import '../study/study_session_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskService _taskService = TaskService();
  final SettingsService _settings = SettingsService();

  void _deleteTask(String id) async {
    final isArabic = _settings.locale.languageCode == 'ar';
    try {
      await _taskService.deleteTask(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'تم حذف المهمة' : 'Task deleted'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'خطأ في الحذف: $e' : 'Error deleting task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewTask(StudyTask task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudySessionScreen(
          topic: task.topic,
          initialTools: task.tools,
        ),
      ),
    );
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
              isArabic ? 'المهام' : 'Tasks', 
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : AppColors.textPrimary),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: StreamBuilder<List<StudyTask>>(
            stream: _taskService.getTasks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)));
              }
              final tasks = snapshot.data ?? [];
              return tasks.isEmpty ? _buildEmptyState(isDark, isArabic) : _buildTaskList(tasks, isDark, isArabic);
            },
          ),
        );
      }
    );
  }

  Widget _buildTaskList(List<StudyTask> tasks, bool isDark, bool isArabic) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatsRow(tasks, isDark, isArabic),
        const SizedBox(height: 24),

        Text(
          isArabic ? 'الجلسات السابقة' : 'Past Sessions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          isArabic ? '${tasks.length} جلسة دراسية' : '${tasks.length} study sessions',
          style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),

        ...tasks.map((task) => _buildTaskCard(task, isDark, isArabic)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStatsRow(List<StudyTask> tasks, bool isDark, bool isArabic) {
    final completed = tasks.where((t) => t.status == 'Completed').length;
    final inProgress = tasks.where((t) => t.status == 'In Progress').length;

    return Row(
      children: [
        _buildStatCard(isArabic ? 'الكل' : 'Total', tasks.length.toString(), Icons.list_alt_outlined, AppColors.primary, isDark),
        const SizedBox(width: 12),
        _buildStatCard(isArabic ? 'مكتمل' : 'Done', completed.toString(), Icons.check_circle_outline, const Color(0xFF4CAF50), isDark),
        const SizedBox(width: 12),
        _buildStatCard(isArabic ? 'نشط' : 'Active', inProgress.toString(), Icons.play_circle_outline, const Color(0xFFFF9F69), isDark),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: AppColors.darkDivider) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(StudyTask task, bool isDark, bool isArabic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: AppColors.darkDivider) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(task.icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.topic,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.bookmark_outline, size: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            task.subject,
                            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: task.statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isArabic 
                      ? (task.status == 'Completed' ? 'مكتمل' : 'قيد التقدم') 
                      : task.status,
                    style: TextStyle(color: task.statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.darkDivider : const Color(0xFFF0F0F0)),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _viewTask(task),
                  icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                  label: Text(isArabic ? 'عرض' : 'View', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ),
              Container(width: 1, height: 24, color: isDark ? AppColors.darkDivider : const Color(0xFFF0F0F0)),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _confirmDelete(task),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFF44336)),
                  label: Text(isArabic ? 'حذف' : 'Delete', style: const TextStyle(color: Color(0xFFF44336), fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(StudyTask task) {
    final isArabic = _settings.locale.languageCode == 'ar';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isArabic ? 'حذف المهمة' : 'Delete Task', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          isArabic ? 'هل أنت متأكد من حذف "${task.topic}"؟' : 'Are you sure you want to delete "${task.topic}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel', style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () { Navigator.pop(ctx); _deleteTask(task.id); },
            child: Text(isArabic ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), shape: BoxShape.circle),
              child: Icon(Icons.note_add_outlined, size: 64, color: AppColors.primary.withOpacity(0.4)),
            ),
            const SizedBox(height: 32),
            Text(
              isArabic ? 'لا توجد مهام حالياً' : 'No tasks yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              isArabic 
                ? 'ابدأ بتنظيم دراستك الآن ودع الذكاء الاصطناعي يساعدك في تلخيص الدروس ووضع خطط الدراسة.'
                : 'Start organizing your study now and let AI help you summarize lessons and create study plans.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskScreen())),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(isArabic ? 'بدء مهمة جديدة' : 'Start New Task', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ],
        ),
      ),
    );
  }
}
