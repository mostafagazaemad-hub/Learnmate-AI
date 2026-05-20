import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/settings_service.dart';
import '../../core/models/classroom_model.dart';

class ClassroomSettingsScreen extends StatefulWidget {
  final Classroom classroom;
  const ClassroomSettingsScreen({super.key, required this.classroom});

  @override
  State<ClassroomSettingsScreen> createState() => _ClassroomSettingsScreenState();
}

class _ClassroomSettingsScreenState extends State<ClassroomSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _subjectController;
  late TextEditingController _descriptionController;
  late bool _isPublic;
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.classroom.name);
    _subjectController = TextEditingController(text: widget.classroom.subject);
    _descriptionController = TextEditingController(text: widget.classroom.description);
    _isPublic = widget.classroom.isPublic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
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
            title: Text(isArabic ? 'إعدادات الفصل' : 'Class Settings'),
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            actions: [
              TextButton(
                onPressed: () {
                  // Save changes logic
                  Navigator.pop(context);
                },
                child: Text(isArabic ? 'حفظ' : 'Save', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(isArabic ? 'معلومات الفصل' : 'Class Information', isDark),
                const SizedBox(height: 16),
                _buildTextField(isArabic ? 'اسم الفصل' : 'Class Name', _nameController, isDark),
                const SizedBox(height: 16),
                _buildTextField(isArabic ? 'المادة' : 'Subject', _subjectController, isDark),
                const SizedBox(height: 16),
                _buildTextField(isArabic ? 'الوصف' : 'Description', _descriptionController, isDark, maxLines: 3),
                const SizedBox(height: 32),
                _buildSectionTitle(isArabic ? 'الإعدادات العامة' : 'General Settings', isDark),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: Text(isArabic ? 'فصل عام' : 'Public Class', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
                    subtitle: Text(isArabic ? 'يمكن للجميع العثور على هذا الفصل' : 'Anyone can find this class', style: const TextStyle(color: Colors.grey)),
                    value: _isPublic,
                    onChanged: (val) => setState(() => _isPublic = val),
                    activeColor: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Delete logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isArabic ? 'أرشفة الفصل' : 'Archive Class', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.darkCard : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
