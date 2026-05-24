import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/settings_service.dart';
import '../settings/settings_screen.dart';
import '../notifications/notifications_screen.dart';
import '../chat/chat_screen.dart';
import '../study/study_session_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final isDark = settings.isDarkMode;
        final isArabic = settings.locale.languageCode == 'ar';

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.08),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LearnMate AI', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        color: isDark ? Colors.white : AppColors.textPrimary
                      )
                    ),
                    Text(
                      'Learning Platform',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : AppColors.textPrimary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, color: isDark ? Colors.white : AppColors.textPrimary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    },
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text(
                  isArabic 
                    ? 'أهلاً، ${FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ?? 'طالبنا'}! 👋'
                    : 'Hi, ${FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ?? 'Student'}! 👋',
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic 
                    ? 'أنت على المسار الصحيح لإنهاء هدفين هذا الأسبوع.'
                    : 'You\'re on track to finish 2 goals this week.',
                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 24),

                // Pinned Plan Progress or Placeholder
                settings.isPlanPinned 
                  ? _buildPinnedPlanCard(settings, isDark, isArabic, context)
                  : _buildPlanPlaceholder(isDark, isArabic),

                const SizedBox(height: 32),

                // AI Suggested Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'اقتراحات الذكاء الاصطناعي' : 'AI Suggested for You',
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(isArabic ? 'عرض الكل' : 'View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildSuggestionCard(
                        isArabic ? 'مراجعة سريعة' : 'QUICK REVIEW',
                        isArabic ? 'هياكل بيانات بايثون' : 'Python Data Structures',
                        isArabic ? 'بناءً على نتائج الاختبار الأخير' : 'Based on your last quiz results',
                        isArabic ? 'ابدأ بطاقات 5د' : 'Start 5m Flashcards',
                        Icons.timer_outlined,
                        AppColors.accent,
                        isDark
                      ),
                      const SizedBox(width: 16),
                      _buildSuggestionCard(
                        isArabic ? 'ممارسة' : 'PRACTICE',
                        isArabic ? 'تجهيز شخصية المستخدم' : 'UX Persona Prep',
                        isArabic ? 'التحضير للدرس القادم' : 'Preparation for next class',
                        isArabic ? 'راجع الآن' : 'Review Now',
                        Icons.description_outlined,
                        AppColors.primary,
                        isDark
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Upcoming Deadlines
                Text(
                  isArabic ? 'المواعيد القادمة' : 'Upcoming Deadlines',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary
                  ),
                ),
                const SizedBox(height: 16),
                _buildDeadlineTile('MAY\n24', isArabic ? 'تسليم المشروع النهائي' : 'Final Project Submission', 'Data Science 101', isDark),
                const SizedBox(height: 12),
                _buildDeadlineTile('MAY\n28', isArabic ? 'تحليل دراسة الحالة' : 'Case Study Analysis', 'Advanced Python', isDark),
                const SizedBox(height: 32),

                // Enrolled Classes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isArabic ? 'الفصول المسجلة' : 'Enrolled Classes',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(isArabic ? 'جميع الفصول' : 'All classes'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildClassCard(isArabic ? 'علم البيانات' : 'Data Science', isArabic ? 'الوحدة 4 من 10' : 'Module 4 of 10', 'https://picsum.photos/seed/ds/500/300', isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildClassCard(isArabic ? 'أساسيات تصميم UX' : 'UX Design Essentials', isArabic ? 'الوحدة 2 من 8' : 'Module 2 of 8', 'https://picsum.photos/seed/ux/500/300', isDark)),
                  ],
                ),
                const SizedBox(height: 32),

                // AI Chat Banner
                _buildChatBanner(isDark, isArabic, context),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildPinnedPlanCard(SettingsService settings, bool isDark, bool isArabic, BuildContext context) {
    final progress = settings.pinnedPlanProgress;
    return GestureDetector(
      onTap: () {
        if (settings.pinnedPlanTopic != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudySessionScreen(
                topic: settings.pinnedPlanTopic!,
                initialTools: {'Plan': settings.pinnedPlanData},
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
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
                      isArabic ? 'تقدم الخطة الحالية' : 'Current Plan Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.w600, 
                        fontSize: 14,
                        color: isDark ? Colors.white70 : AppColors.textSecondary
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settings.pinnedPlanTopic ?? "",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        color: isDark ? Colors.white : AppColors.textPrimary
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  isArabic ? 'استمر في التقدم!' : 'Keep going!',
                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanPlaceholder(bool isDark, bool isArabic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today_rounded, color: AppColors.primary.withOpacity(0.5), size: 40),
          const SizedBox(height: 16),
          Text(
            isArabic 
              ? "يمكنك الاطلاع على خطتك الرئيسية هنا بعد اضافتها من صفحة الخطة"
              : "You can view your main plan here after adding it from the Plan page",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontSize: 14,
              height: 1.5
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(String tag, String title, String subtitle, String buttonText, IconData icon, Color iconColor, bool isDark) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: AppColors.darkDivider) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                tag,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 16,
              color: isDark ? Colors.white : AppColors.textPrimary
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 12),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
                foregroundColor: AppColors.primary,
                elevation: 0,
                side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.divider),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineTile(String date, String title, String course, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppColors.darkDivider) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              date,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.textPrimary
                  ),
                ),
                Text(
                  course,
                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildClassCard(String title, String modules, String imageUrl, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: AppColors.darkDivider) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.textPrimary
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  modules,
                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBanner(bool isDark, bool isArabic, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF6C5DD3)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'اسأل LearnMate AI' : 'Ask LearnMate AI',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isArabic 
                      ? 'تحدث مع معلمك الذكي، واحصل على ملخصات وخرائط ذهنية'
                      : 'Chat with your AI Tutor, get summaries & mind maps',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
