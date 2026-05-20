import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'teacher_policy_agreement_screen.dart';

/// الشاشة الثانية في عملية تسجيل المدرس: استكمال الملف الشخصي الأكاديمي والمهني
class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  // المتغيرات الخاصة بالنموذج (Form) لحفظ المدخلات
  double _yearsOfExperience = 5.0; // عدد سنوات الخبرة الافتراضي
  String _selectedEmployment = 'University Prof'; // المسمى الوظيفي المحدد
  bool _hasNoFormalCertificate = false; // خيار "ليس لدي شهادة رسمية"
  bool _hasNoCourses = false; // خيار "ليس لدي كورسات"
  final TextEditingController _courseController = TextEditingController(); // متحكم حقل إضافة الكورس
  
  // خيارات المسميات الوظيفية
  final List<String> _employmentStatuses = [
    'University Prof', 'Freelance Tutor', 'School Teacher', 'Researcher'
  ];
  final List<String> _courses = []; // قائمة الكورسات التي أضافها المدرس
  String? _courseVideoPath; // مسار الفيديو التعريفي
  Uint8List? _courseVideoBytes; // محتوى الفيديو (للرفع)
  final TextEditingController _courseWebsiteController = TextEditingController(); // رابط موقع الكورسات
  final TextEditingController _degreesController = TextEditingController(); // الشهادات
  final TextEditingController _specializationController = TextEditingController(); // التخصص الأساسي (الإجباري)
  bool _hasAttemptedSubmit = false; // لتفعيل وضع التحقق (Validation) عند الضغط على زر الحفظ

  @override
  void dispose() {
    _courseController.dispose();
    _courseWebsiteController.dispose();
    _degreesController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _pickCourseVideo() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.video,
      );

      final bool isWeb = identical(0, 0.0); // Simple way to check for web
      if (result != null) {
        final file = result.files.single;
        if (file.path != null || (isWeb && file.bytes != null)) {
          setState(() {
            _courseVideoPath = file.path ?? file.name;
            _courseVideoBytes = file.bytes;
          });
        }
      }
    } catch (e) {
      debugPrint("Error picking video: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An error occurred while selecting the video.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF7B61FF).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF7B61FF), size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B2A4A)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.lexend(fontSize: 12, color: const Color(0xFF6B7B8D)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String hint, 
    required String label, 
    bool isRequired = false, 
    bool isError = false, 
    String? errorText,
    int maxLines = 1, 
    Widget? suffixIcon,
    TextEditingController? controller,
    void Function(String)? onFieldSubmitted,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1B2A4A)),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
            if (isError && errorText != null) ...[
              const Spacer(),
              const Icon(Icons.error_outline, color: Colors.red, size: 14),
              const SizedBox(width: 4),
              Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 10), textAlign: TextAlign.right),
            ]
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isError ? Colors.red.shade300 : const Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isError ? Colors.red.shade300 : const Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isError ? Colors.red : const Color(0xFF7B61FF), width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(vertical: maxLines == 1 ? 14 : 16, horizontal: 12),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B2A4A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Teacher Profile',
          style: GoogleFonts.lexend(color: const Color(0xFF1B2A4A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== شريط التقدم (الخطوة 2 من 3) =====
              Row(
                children: [
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF7B61FF), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 4),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF7B61FF), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 4),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 8),
                  Text('STEP 2/3', style: GoogleFonts.lexend(color: const Color(0xFF7B61FF), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              
              // ===== العنوان الرئيسي =====
              Text(
                'Complete your profile',
                style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1B2A4A)),
              ),
              const SizedBox(height: 8),
              Text(
                'Help us match you with the right students by providing\nyour academic details.',
                style: GoogleFonts.lexend(fontSize: 13, color: const Color(0xFF6B7B8D), height: 1.4),
              ),
              const SizedBox(height: 32),
              
              // ===== قسم الخلفية الأكاديمية (الشهادات والتخصص) =====
              _buildSectionHeader(Icons.school, 'Academic Background', 'Your credentials and focus areas'),
              const SizedBox(height: 20),
              
              // --- حقل التخصص الأساسي (إجباري) ---
              _buildTextField(
                label: 'Primary Specialization',
                hint: 'e.g. Theoretical Physics',
                isRequired: true,
                controller: _specializationController,
                onChanged: (_) {
                  if (_hasAttemptedSubmit) {
                    setState(() {});
                  }
                },
                isError: _hasAttemptedSubmit && _specializationController.text.trim().isEmpty,
                errorText: 'Required',
              ),
              const SizedBox(height: 20),

              // --- حقل الشهادات (إجباري إلا إذا حدد "ليس لدي شهادة") ---
              _buildTextField(
                label: 'Degrees & Certifications',
                hint: 'e.g. Ph.D. in Astrophysics, Harvard\nUniversity',
                isRequired: true,
                controller: _degreesController,
                onChanged: (_) {
                  if (_hasAttemptedSubmit) {
                    setState(() {});
                  }
                },
                isError: _hasAttemptedSubmit && 
                         !_hasNoFormalCertificate && 
                         _degreesController.text.trim().isEmpty,
                errorText: 'Please list your highest\ndegree',
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _hasNoFormalCertificate,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      activeColor: const Color(0xFF7B61FF),
                      onChanged: (value) {
                        setState(() {
                          _hasNoFormalCertificate = value ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'I don\'t have a formal certificate',
                    style: GoogleFonts.lexend(fontSize: 14, color: const Color(0xFF1B2A4A)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // ===== PROFESSIONAL EXPERIENCE =====
              _buildSectionHeader(Icons.work_outline, 'Professional Experience', 'Your journey in education'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Years of Experience',
                    style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1B2A4A)),
                  ),
                  Text(
                    '${_yearsOfExperience.toInt()} Years',
                    style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF7B61FF)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: const Color(0xFF7B61FF),
                  inactiveTrackColor: const Color(0xFF7B61FF).withValues(alpha: 0.1),
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 2),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                ),
                child: Slider(
                  value: _yearsOfExperience,
                  min: 0,
                  max: 20,
                  divisions: 20,
                  onChanged: (value) {
                    setState(() {
                      _yearsOfExperience = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Current Employment Status',
                style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1B2A4A)),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final double itemWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _employmentStatuses.map((status) {
                      bool isSelected = _selectedEmployment == status;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedEmployment = status;
                          });
                        },
                        child: Container(
                          width: itemWidth,
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF7B61FF) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF7B61FF) : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
              ),
              const SizedBox(height: 32),
              
              // ===== MY COURSES =====
              _buildSectionHeader(Icons.menu_book_outlined, 'My Courses', 'Subjects you are qualified to teach'),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _courseController,
                label: '',
                hint: 'Add a subject and press Enter...',
                onFieldSubmitted: (value) {
                  if (value.trim().isNotEmpty && !_courses.contains(value.trim())) {
                    setState(() {
                      _courses.add(value.trim());
                      _courseController.clear();
                    });
                  }
                },
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF7B61FF)),
                  onPressed: () {
                    final value = _courseController.text;
                    if (value.trim().isNotEmpty && !_courses.contains(value.trim())) {
                      setState(() {
                        _courses.add(value.trim());
                        _courseController.clear();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (_courses.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _courses.map((course) {
                    return Chip(
                      label: Text(
                        course,
                        style: GoogleFonts.lexend(fontSize: 12, color: const Color(0xFF7B61FF), fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: const Color(0xFF7B61FF).withValues(alpha: 0.08),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF7B61FF)),
                      onDeleted: () {
                        setState(() {
                          _courses.remove(course);
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
              Text(
                'You can add more courses later from your profile.',
                style: GoogleFonts.lexend(fontSize: 12, color: const Color(0xFF6B7B8D), fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _hasNoCourses,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      activeColor: const Color(0xFF7B61FF),
                      onChanged: (value) {
                        setState(() {
                          _hasNoCourses = value ?? false;
                          if (_hasNoCourses) {
                            _courses.clear();
                            _courseVideoPath = null;
                            _courseVideoBytes = null;
                            _courseWebsiteController.clear();
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'I don\'t have courses',
                    style: GoogleFonts.lexend(fontSize: 14, color: const Color(0xFF1B2A4A)),
                  ),
                ],
              ),

              // ===== خيارات إضافية تظهر عند وجود كورسات =====
              if (_courses.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B61FF).withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7B61FF).withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Course Information',
                        style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1B2A4A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Optional - Help students discover your content',
                        style: GoogleFonts.lexend(fontSize: 11, color: const Color(0xFF6B7B8D)),
                      ),
                      const SizedBox(height: 16),

                      // --- خيار 1: رفع فيديو ---
                      GestureDetector(
                        onTap: _pickCourseVideo,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _courseVideoPath != null ? const Color(0xFF7B61FF).withValues(alpha: 0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _courseVideoPath != null ? const Color(0xFF7B61FF) : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7B61FF).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.video_library_outlined, color: Color(0xFF7B61FF), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add an introductory video',
                                      style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1B2A4A)),
                                    ),
                                    Text(
                                      _courseVideoPath != null ? '✓ Video selected' : 'MP4, MOV - up to 100MB',
                                      style: GoogleFonts.lexend(
                                        fontSize: 11,
                                        color: _courseVideoPath != null ? const Color(0xFF7B61FF) : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_courseVideoPath != null)
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _courseVideoPath = null;
                                    _courseVideoBytes = null;
                                  }),
                                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                                )
                              else
                                const Icon(Icons.upload_outlined, color: Color(0xFF7B61FF), size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // --- خيار 2: رابط الموقع ---
                      TextFormField(
                        controller: _courseWebsiteController,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          hintText: 'https://example.com/my-courses',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                          labelText: 'Course Website URL',
                          labelStyle: GoogleFonts.lexend(fontSize: 13, color: const Color(0xFF1B2A4A)),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          prefixIcon: const Icon(Icons.link, color: Color(0xFF7B61FF), size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF7B61FF)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              
              // ===== ACHIEVEMENTS =====
              _buildSectionHeader(Icons.emoji_events_outlined, 'Achievements', 'Recognition and awards'),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Awards & Honors',
                hint: 'e.g. Best Educator Award 2023',
              ),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== زر الحفظ والمتابعة =====
              GestureDetector(
                onTap: () {
                  setState(() {
                    _hasAttemptedSubmit = true;
                  });
                  // التحقق من صحة الحقول الإجبارية قبل الانتقال للخطوة التالية
                  bool specValid = _specializationController.text.trim().isNotEmpty;
                  bool degreesValid = (_hasNoFormalCertificate || _degreesController.text.trim().isNotEmpty);
                  
                  if (specValid && degreesValid) {
                    // 1. تجميع كل بيانات واختيارات المدرس من هذه الشاشة
                    final profileData = {
                      'specialization': _specializationController.text.trim(),
                      'degrees': _hasNoFormalCertificate ? 'None' : _degreesController.text.trim(),
                      'yearsOfExperience': _yearsOfExperience,
                      'employmentStatus': _selectedEmployment,
                      'courses': _courses,
                      'courseVideoPath': _courseVideoPath,
                      'courseVideoBytes': _courseVideoBytes,
                      'courseWebsite': _courseWebsiteController.text.trim(),
                    };
                    
                    // 2. التوجيه لشاشة الموافقة على الشروط مع تمرير البيانات
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeacherPolicyAgreementScreen(profileData: profileData),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFF9D85FF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B61FF).withValues(alpha: 0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Save & Continue',
                          style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'STEP 2 OF 3 - PROFESSIONAL VERIFICATION',
                style: GoogleFonts.lexend(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6B7B8D),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
