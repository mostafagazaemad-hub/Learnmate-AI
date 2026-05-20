import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/settings_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../classes/add_class_screen.dart';
import '../courses/my_courses_screen.dart';
import '../classes/classes_screen.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final settings = SettingsService();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final isDark = settings.isDarkMode;
        final isArabic = settings.locale.languageCode == 'ar';

        return StreamBuilder<DocumentSnapshot>(
          stream: user != null 
              ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
              : null,
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
            final photoUrl = userData?['photoUrl'] ?? user?.photoURL ?? 'https://img.freepik.com/free-photo/portrait-expressive-young-woman_1258-48167.jpg';
            final name = userData?['name'] ?? user?.displayName ?? (isArabic ? 'مدرس' : 'Teacher');

            return StreamBuilder<QuerySnapshot>(
              stream: user != null
                  ? FirebaseFirestore.instance
                      .collection('classrooms')
                      .where('instructorId', isEqualTo: user.uid)
                      .snapshots()
                  : null,
              builder: (context, classSnapshot) {
                final classrooms = classSnapshot.data?.docs ?? [];
                final activeClassesCount = classrooms.length.toString();

                return Scaffold(
                  backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
                  appBar: AppBar(
                    backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                    elevation: 0,
                    title: Text(
                      isArabic ? 'لوحة التحكم' : 'My Dashboard', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.notifications_outlined, color: isDark ? Colors.white : AppColors.textPrimary), 
                        onPressed: () {}
                      ),
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(photoUrl),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'مرحباً بك، ${name.split(' ').first}' : 'Welcome back, ${name.split(' ').first}',
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isArabic ? 'إليك ما يحدث في فصولك الدراسية اليوم.' : 'Here\'s what\'s happening with your classes today.',
                          style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: Icon(Icons.file_download_outlined, color: isDark ? Colors.white70 : AppColors.primary),
                                label: Text(isArabic ? 'تصدير تقرير' : 'Export Report', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textPrimary)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.divider),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AddClassScreen()),
                                ),
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: Text(isArabic ? 'فصل جديد' : 'New Class', style: const TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Stats Cards
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.5,
                          children: [
                            _buildStatCard(isArabic ? 'الفصول النشطة' : 'Active Classes', activeClassesCount, isArabic ? 'مباشر' : 'Live', Icons.school_outlined, AppColors.primary, isDark),
                            _buildStatCard(isArabic ? 'الأداء العام' : 'Avg. Performance', '0%', '0%', Icons.trending_up, AppColors.success, isDark),
                            _buildStatCard(isArabic ? 'معدل الإنجاز' : 'Completion Rate', '0%', '0%', Icons.check_circle_outline, Colors.orange, isDark),
                            _buildStatCard(isArabic ? 'مهام معلقة' : 'Assignments Pending', '0', '0', Icons.assignment_outlined, AppColors.error, isDark),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Active Classes Table
                        _buildSectionHeader(isArabic ? 'الفصول النشطة' : 'Active Classes', '', isDark, isArabic),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                          ),
                          child: Column(
                            children: [
                              _buildTableHeader(isDark, isArabic),
                              if (classrooms.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Center(
                                    child: Text(
                                      isArabic ? 'لا توجد فصول دراسية بعد' : 'No active classes found',
                                      style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                    ),
                                  ),
                                )
                              else
                                ...classrooms.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return _buildTableRow(
                                    data['name'] ?? '',
                                    data['subject'] ?? '',
                                    (data['membersCount'] ?? 0).toString(),
                                    isDark
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // AI Insights Card (Placeholder for real data)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    isArabic ? 'تحليلات ذكاء LearnMate' : 'LearnMate AI Insights',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isArabic 
                                  ? 'قم بإضافة طلاب وفصول دراسية للبدء في تلقي تحليلات ذكية حول أداء طلابك.'
                                  : 'Add students and classes to start receiving AI-powered insights about your student performance.',
                                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }
    );
  }

  Widget _buildStatCard(String title, String value, String trend, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              Text(trend, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value, 
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                )
              ),
              Text(title, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, bool isDark, bool isArabic) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title, 
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          )
        ),
        if (action.isNotEmpty)
          TextButton(onPressed: () {}, child: Text(action, style: const TextStyle(color: AppColors.primary))),
      ],
    );
  }

  Widget _buildTableHeader(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkDivider : const Color(0xFFF1F4F9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(isArabic ? 'اسم الفصل' : 'CLASS NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary))),
          Expanded(child: Text(isArabic ? 'المادة' : 'SUBJECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary))),
          Expanded(child: Text(isArabic ? 'الطلاب' : 'STUDENTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildTableRow(String name, String subject, String students, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.divider))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary))),
          Expanded(child: Text(subject, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary))),
          Expanded(child: Text(students, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary))),
        ],
      ),
    );
  }
}
