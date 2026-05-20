import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/settings_service.dart';
import '../profile/edit_profile_screen.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'en',
                groupValue: _settings.locale.languageCode,
                onChanged: (val) {
                  _settings.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                _settings.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('العربية'),
              leading: Radio<String>(
                value: 'ar',
                groupValue: _settings.locale.languageCode,
                onChanged: (val) {
                  _settings.setLocale(const Locale('ar'));
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                _settings.setLocale(const Locale('ar'));
                Navigator.pop(context);
              },
            ),
          ],
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
        final currentLanguage = isArabic ? 'العربية' : 'English';

        final labels = {
          'title': isArabic ? 'الإعدادات' : 'Settings',
          'preferences': isArabic ? 'التفضيلات' : 'Preferences',
          'darkMode': isArabic ? 'الوضع الليلي' : 'Dark Mode',
          'language': isArabic ? 'اللغة' : 'Language',
          'account': isArabic ? 'الحساب' : 'Account',
          'profile': isArabic ? 'إعدادات الملف الشخصي' : 'Profile Settings',
          'privacy': isArabic ? 'الخصوصية والأمان' : 'Privacy & Security',
          'support': isArabic ? 'الدعم' : 'Support',
          'help': isArabic ? 'مركز المساعدة' : 'Help Center',
          'about': isArabic ? 'عن LearnMate AI' : 'About LearnMate AI',
          'logout': isArabic ? 'تسجيل الخروج' : 'Log Out',
          'logout_confirm': isArabic ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟' : 'Are you sure you want to log out?',
          'cancel': isArabic ? 'إلغاء' : 'Cancel',
        };

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              labels['title']!,
              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSection(labels['preferences']!, isDark),
              _buildSettingsCard([
                _buildToggleItem(
                  Icons.dark_mode_outlined, 
                  labels['darkMode']!, 
                  isDark, 
                  (val) => _settings.toggleTheme(val),
                  isDark
                ),
                _buildDivider(isDark),
                _buildNavItem(
                  Icons.language, 
                  labels['language']!, 
                  currentLanguage, 
                  _showLanguageDialog,
                  isDark
                ),
              ], isDark),
              const SizedBox(height: 24),
              _buildSection(labels['account']!, isDark),
              _buildSettingsCard([
                _buildNavItem(Icons.person_outline, labels['profile']!, null, () {
                  final user = FirebaseAuth.instance.currentUser;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfileScreen(
                      initialName: user?.displayName ?? '',
                      initialEmail: user?.email ?? '',
                    )),
                  );
                }, isDark),
                _buildDivider(isDark),
                _buildNavItem(Icons.lock_outline, labels['privacy']!, null, () {}, isDark),
              ], isDark),
              const SizedBox(height: 24),
              _buildSection(labels['support']!, isDark),
              _buildSettingsCard([
                _buildNavItem(Icons.help_outline, labels['help']!, null, () {}, isDark),
                _buildDivider(isDark),
                _buildNavItem(Icons.info_outline, labels['about']!, 'v1.0.0', () {}, isDark),
              ], isDark),
              const SizedBox(height: 40),
              
              // Logout Button in Settings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: GestureDetector(
                  onTap: () => _logout(context, labels),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, color: AppColors.error),
                        const SizedBox(width: 12),
                        Text(
                          labels['logout']!,
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
              const SizedBox(height: 40),
            ],
          ),
        );
      }
    );
  }

  Future<void> _logout(BuildContext context, Map<String, String> labels) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _settings.isDarkMode ? AppColors.darkCard : Colors.white,
        title: Text(labels['logout']!, style: TextStyle(color: _settings.isDarkMode ? Colors.white : AppColors.textPrimary)),
        content: Text(labels['logout_confirm']!, style: TextStyle(color: _settings.isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(labels['cancel']!)),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(labels['logout']!)
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

  Widget _buildSection(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleItem(IconData icon, String title, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimary)),
      trailing: Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.primary),
    );
  }

  Widget _buildNavItem(IconData icon, String title, String? trailing, VoidCallback onTap, bool isDark) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.divider, indent: 56);
  }
}
