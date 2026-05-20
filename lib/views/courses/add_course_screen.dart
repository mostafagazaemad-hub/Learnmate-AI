import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/settings_service.dart';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final SettingsService _settings = SettingsService();
  
  String _category = 'Science';
  XFile? _thumbnail;
  PlatformFile? _videoFile;
  bool _isLoading = false;

  final List<String> _categories = ['Science', 'Math', 'History', 'Technology', 'Art', 'Language'];

  @override
  void initState() {
    super.initState();
    _fetchTeacherWebsite();
  }

  Future<void> _fetchTeacherWebsite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('website') && data['website'] != null && data['website'].toString().isNotEmpty) {
          setState(() {
            _websiteController.text = data['website'];
          });
        }
      }
    }
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _thumbnail = pickedFile);
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.video,
      withData: kIsWeb,
    );
    if (result != null && result.files.single.name.isNotEmpty) {
      setState(() => _videoFile = result.files.single);
    }
  }

  Future<void> _saveCourse(bool isArabic) async {
    if (!_formKey.currentState!.validate()) return;
    if (_thumbnail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'يرجى اختيار صورة مصغرة' : 'Please select a thumbnail')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Upload Thumbnail to Firebase Storage
      final thumbBytes = await _thumbnail!.readAsBytes();
      final thumbnailUrl = await StorageService.instance.uploadFile(
        bytes: thumbBytes,
        fileName: _thumbnail!.name,
        folder: 'course_thumbnails'
      );

      // 2. Upload Video to Firebase Storage (if selected)
      String? videoUrl;
      if (_videoFile != null) {
        videoUrl = await StorageService.instance.uploadFile(
          bytes: _videoFile!.bytes,
          path: kIsWeb ? null : _videoFile!.path,
          fileName: _videoFile!.name,
          folder: 'course_videos'
        );
      }

      // 3. Save Course Data to Firestore
      final courseData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'thumbnailUrl': thumbnailUrl,
        'courseVideoUrl': videoUrl,
        'courseWebsite': _websiteController.text.trim(),
        'instructorId': user.uid,
        'instructorName': user.displayName ?? (isArabic ? 'مدرس' : 'Teacher'),
        'createdAt': FieldValue.serverTimestamp(),
        'rating': 0.0,
        'studentsCount': 0,
      };

      await FirebaseFirestore.instance.collection('courses').add(courseData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArabic ? 'تمت إضافة الكورس بنجاح!' : 'Course added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArabic ? 'خطأ في الحفظ: $e' : 'Error saving course: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isArabic ? 'إضافة كورس جديد' : 'Add New Course',
              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImagePicker(isDark, isArabic),
                      const SizedBox(height: 32),
                      _buildTextField(isArabic ? 'عنوان الكورس' : 'Course Title', _titleController, Icons.title, isDark, isArabic),
                      const SizedBox(height: 20),
                      _buildTextField(isArabic ? 'الوصف' : 'Description', _descriptionController, Icons.description_outlined, isDark, isArabic, maxLines: 4),
                      const SizedBox(height: 20),
                      _buildTextField(isArabic ? 'رابط الموقع (اختياري)' : 'Website Link (Optional)', _websiteController, Icons.link, isDark, isArabic),
                      const SizedBox(height: 20),
                      _buildCategoryDropdown(isDark, isArabic),
                      const SizedBox(height: 32),
                      _buildVideoPicker(isDark, isArabic),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _saveCourse(isArabic),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            isArabic ? 'نشر الكورس' : 'Publish Course',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        );
      }
    );
  }

  Widget _buildImagePicker(bool isDark, bool isArabic) {
    return GestureDetector(
      onTap: _pickThumbnail,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
        ),
        child: _thumbnail != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: kIsWeb 
                  ? Image.network(_thumbnail!.path, fit: BoxFit.cover)
                  : Image.file(File(_thumbnail!.path), fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 48, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    isArabic ? 'أضف صورة مصغرة للكورس' : 'Add Course Thumbnail',
                    style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, bool isDark, bool isArabic, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) => (value == null || value.isEmpty) && !label.contains('Optional') ? (isArabic ? 'هذا الحقل مطلوب' : 'Required') : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(bool isDark, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'الفئة' : 'Category',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              isExpanded: true,
              dropdownColor: isDark ? AppColors.darkCard : Colors.white,
              items: _categories.map((String cat) {
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Text(cat, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _category = val!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPicker(bool isDark, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'فيديو الكورس' : 'Course Video',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickVideo,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.video_library_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _videoFile == null 
                      ? (isArabic ? 'اختر ملف فيديو' : 'Select Video File')
                      : _videoFile!.name,
                    style: TextStyle(color: isDark ? Colors.white70 : AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
