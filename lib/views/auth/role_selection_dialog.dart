import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main_layout.dart';
import 'teacher_profile_screen.dart';
import '../../core/theme/app_colors.dart';

/// واجهة منبثقة (Dialog) تظهر للمستخدم بعد التسجيل لاختيار نوع الحساب (طالب أم مدرس)
class RoleSelectionDialog extends StatefulWidget {
  const RoleSelectionDialog({super.key});

  /// دالة مساعدة لعرض هذه الواجهة المنبثقة من أي مكان في التطبيق
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // منع إغلاق النافذة عند الضغط خارجها لإجبار المستخدم على الاختيار
      builder: (context) => const RoleSelectionDialog(),
    );
  }

  @override
  State<RoleSelectionDialog> createState() => _RoleSelectionDialogState();
}

class _RoleSelectionDialogState extends State<RoleSelectionDialog> {
  bool _isLoading = false;

  Future<void> _selectRole(String role) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (role == 'student') {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'role': role,
            'hasSelectedRole': true,
          }, SetOptions(merge: true));

          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainLayout()),
            (route) => false,
          );
        } else {
          // للمدرس، ننتقل فقط للشاشة التالية دون تحديد الدور في قاعدة البيانات بعد
          // لضمان عدم توجيه المستخدم للشاشة الرئيسية قبل إكمال بياناته
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const TeacherProfileScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الدور: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_circle_outlined, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'اختر نوع الحساب',
              style: GoogleFonts.lexend(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'هل تريد استخدام التطبيق كطالب أم كمدرس؟\nDo you want to use the app as a student or a teacher?',
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      context: context,
                      title: 'طالب\nStudent',
                      icon: Icons.school_outlined,
                      color: AppColors.primary,
                      onTap: () => _selectRole('student'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRoleCard(
                      context: context,
                      title: 'مُدرّس\nTeacher',
                      icon: Icons.verified_user_outlined,
                      color: AppColors.accent,
                      onTap: () => _selectRole('instructor'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// بناء بطاقة (زر كبير) تمثل كل دور متاح (طالب / مدرس)
  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
