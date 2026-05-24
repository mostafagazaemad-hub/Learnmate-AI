import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/services/settings_service.dart';
import 'home/home_screen.dart';
import 'courses/courses_screen.dart';
import 'classes/classes_screen.dart';
import 'tasks/tasks_screen.dart';
import 'profile/profile_screen.dart';
import 'tasks/add_task_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final SettingsService _settings = SettingsService();

  final List<Widget> _screens = [
    const HomeScreen(),
    const CoursesScreen(),
    const ClassesScreen(),
    const TasksScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isArabic = _settings.locale.languageCode == 'ar';
        
        return Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, -8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : AppColors.white,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: isArabic ? 'الرئيسية' : 'Home',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.book_outlined),
                  activeIcon: const Icon(Icons.book),
                  label: isArabic ? 'الدورات' : 'Courses',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.school_outlined),
                  activeIcon: const Icon(Icons.school),
                  label: isArabic ? 'الفصول' : 'Classes',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.check_circle_outline),
                  activeIcon: const Icon(Icons.check_circle),
                  label: isArabic ? 'المهام' : 'Tasks',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: isArabic ? 'الملف' : 'Profile',
                ),
              ],
            ),
          ),
          floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 3)
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
                    );
                  },
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                )
              : null,
        );
      }
    );
  }
}
