import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/settings_service.dart';
import '../courses/my_courses_screen.dart';
import '../dashboard/teacher_dashboard.dart';
import 'teacher_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../notifications/notifications_screen.dart';
import 'edit_profile_screen.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final SettingsService _settings = SettingsService();

  Future<void> _logout() async {
    final isArabic = _settings.locale.languageCode == 'ar';
    
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تسجيل الخروج' : 'Log Out'),
        content: Text(isArabic 
          ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟' 
          : 'Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text(isArabic ? 'إلغاء' : 'Cancel')
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(isArabic ? 'خروج' : 'Log Out')
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: Text('Please log in to view profile.'));
    }

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
              isArabic ? 'الملف الشخصي' : 'Profile', 
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.settings, color: isDark ? Colors.white : AppColors.textPrimary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(_user!.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              final String name = userData?['name'] ?? _user!.displayName ?? 'User';
              final String email = userData?['email'] ?? _user!.email ?? '';
              final String? photoUrl = userData?['photoUrl'] ?? _user!.photoURL;
              final String role = userData?['role'] ?? 'student';

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Profile Header
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditProfileScreen(
                              initialName: name,
                              initialEmail: email,
                            )),
                          );
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 3),
                                image: DecorationImage(
                                  image: NetworkImage(photoUrl ?? 'https://ui-avatars.com/api/?name=$name&background=random'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
                    ),
                    Text(
                      email,
                      style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 16),
                    ),
                    if (role == 'instructor')
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isArabic ? 'معلم' : 'Instructor',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Settings Sections
                    _buildSectionTitle(isArabic ? 'إعدادات الحساب' : 'ACCOUNT SETTINGS', isDark),
                    _buildSettingTile(
                      icon: Icons.person_outline,
                      title: isArabic ? 'المعلومات الشخصية' : 'Personal Information',
                      subtitle: isArabic ? 'الاسم، البريد الإلكتروني، وكلمة المرور' : 'Name, email, and password',
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditProfileScreen(
                            initialName: name,
                            initialEmail: email,
                          )),
                        );
                      },
                    ),
                    _buildSettingTile(
                      icon: Icons.school_outlined,
                      title: isArabic ? 'دوراتي' : 'My Courses',
                      subtitle: isArabic ? 'عرض وإدارة الدورات المسجلة' : 'View and manage your enrolled courses',
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MyCoursesScreen()),
                        );
                      },
                    ),
                    
                    if (role == 'instructor') ...[
                      _buildSettingTile(
                        icon: Icons.dashboard_outlined,
                        title: isArabic ? 'لوحة تحكم المعلم' : 'Teacher Dashboard',
                        subtitle: isArabic ? 'التبديل إلى عرض المعلم وإدارة الفصول' : 'Switch to teacher view and manage classes',
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TeacherDashboard()),
                          );
                        },
                      ),
                      _buildSettingTile(
                        icon: Icons.account_box_outlined,
                        title: isArabic ? 'ملف المعلم' : 'Teacher Profile',
                        subtitle: isArabic ? 'عرض ملفك الشخصي العام كمعلم' : 'View your public teacher profile',
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TeacherProfileScreen()),
                          );
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    _buildSectionTitle(isArabic ? 'التفضيلات' : 'PREFERENCES', isDark),
                    _buildSettingTile(
                      icon: Icons.notifications_none,
                      title: isArabic ? 'التنبيهات' : 'Notifications',
                      subtitle: isArabic ? 'تنبيهات البريد الإلكتروني والرسائل' : 'Email and push alerts',
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                    // Log Out Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: _logout,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout, color: AppColors.error),
                              const SizedBox(width: 12),
                              Text(
                                isArabic ? 'تسجيل الخروج' : 'Log Out',
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'LEARNMATE AI V2.4.0',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary.withOpacity(0.5) : AppColors.textSecondary.withOpacity(0.5),
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        );
      }
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Align(
        alignment: isDark ? Alignment.centerLeft : Alignment.centerLeft, // Align left regardless, but inside RTL it will be right
        child: Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
        subtitle: Text(subtitle, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, size: 20),
        onTap: onTap,
      ),
    );
  }
}
