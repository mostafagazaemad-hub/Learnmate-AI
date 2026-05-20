import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main_layout.dart';
import '../../core/services/storage_service.dart';
import 'dart:typed_data';

/// الشاشة الثالثة والأخيرة في رحلة تسجيل المدرس
/// تتيح للمدرس قراءة سياسة المنصة والموافقة عليها ثم حفظ بياناته النهائية
class TeacherPolicyAgreementScreen extends StatefulWidget {
  final Map<String, dynamic> profileData; // البيانات التي تم جمعها من المرحلة الثانية

  const TeacherPolicyAgreementScreen({super.key, required this.profileData});

  @override
  State<TeacherPolicyAgreementScreen> createState() => _TeacherPolicyAgreementScreenState();
}

class _TeacherPolicyAgreementScreenState extends State<TeacherPolicyAgreementScreen> {
  bool _agreedToTerms = false; // حالة تحديد خانة "أوافق على الشروط"
  bool _isLoading = false; // للتحكم في ظهور أيقونة التحميل عند إرسال البيانات

  // نص اتفاقية الاستخدام (مدونة السلوك)
  final String _policyText = '''
Welcome to LearnMate! To ensure a high-quality and safe learning environment for everyone, all instructors must adhere to the following professional guidelines. By proceeding, you agree to these terms:

1. Professionalism & Respect
Instructors must maintain the highest standards of professionalism in all interactions. Any form of harassment, discrimination, or inappropriate behavior towards students or staff is strictly prohibited and will result in immediate account termination.

2. Content Quality & Originality
You are responsible for ensuring that all course materials, assignments, and lectures hold significant educational value and are accurate. Plagiarism and unauthorized use of copyrighted materials will not be tolerated.

3. Platform Communication
To ensure safety and trust, all communication with students must remain on the LearnMate platform. Sharing personal contact details (phone numbers, social media profiles, personal emails) or soliciting off-platform transactions is a direct violation of our policy.

4. Reliability & Responsiveness
Instructors must show up on time for any scheduled live sessions. You are expected to respond to student inquiries, messages, and review submitted assignments within a reasonable timeframe (typically 24 to 48 hours).
''';

  Future<void> _submitData() async {
    if (!_agreedToTerms || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User is not logged in!");
      }

      debugPrint("Starting Firestore save for user: ${user.uid}");
      
      // 1. Upload Video to Storage if it exists
      String? videoUrl;
      if (widget.profileData['courseVideoBytes'] != null) {
        debugPrint("Uploading video to Storage...");
        videoUrl = await StorageService.instance.uploadFile(
          bytes: widget.profileData['courseVideoBytes'] as Uint8List,
          fileName: widget.profileData['courseVideoPath'] ?? 'intro_video.mp4',
          folder: 'instructor_videos',
        );
        debugPrint("Video upload result: $videoUrl");
      }

      // 2. Prepare Final Data
      final Map<String, dynamic> finalUpdate = {
        ...widget.profileData,
        'role': 'instructor',
        'agreedToTerms': true,
        'isProfileComplete': true,
        'hasSelectedRole': true,
        'registrationCompletedAt': DateTime.now().toIso8601String(),
      };

      // Remove raw bytes from Firestore data and replace with the storage URL
      finalUpdate.remove('courseVideoBytes');
      if (videoUrl != null) {
        finalUpdate['courseVideoUrl'] = videoUrl;
      }
      
      debugPrint("Final Data keys: ${finalUpdate.keys.toList()}");

      // استخدام set مع merge لضمان الاستقرار
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(finalUpdate, SetOptions(merge: true))
          .timeout(const Duration(seconds: 60), onTimeout: () {
            throw Exception("Connection Timeout: The server is taking too long to respond. Please check your connection.");
          });

      debugPrint("Firestore save successful");

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Application Submitted Successfully! Welcome to LearnMate.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // الانتقال للواجهة الرئيسية
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainLayout()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Firestore Save Error: $e");
      String errorMsg = e.toString();
      if (errorMsg.contains('permission-denied')) {
        errorMsg = "Access Denied: You don't have permission to update this profile. Please check Firestore rules.";
      } else if (errorMsg.contains('Timeout')) {
        errorMsg = "Connection Timeout: Please check your internet connection.";
      } else {
        errorMsg = "Save failed: ${errorMsg.split(':').last.trim()}";
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _submitData();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          'Agreement & Policy',
          style: GoogleFonts.lexend(color: const Color(0xFF1B2A4A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== شريط التقدم (الخطوة 3 من 3) =====
              Row(
                children: [
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF7B61FF), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 4),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF7B61FF), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 4),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF7B61FF), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 8),
                  Text('STEP 3/3', style: GoogleFonts.lexend(color: const Color(0xFF7B61FF), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              
              // ===== العنوان الرئيسي ======
              Text(
                'Code of Conduct & Policies',
                style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1B2A4A)),
              ),
              const SizedBox(height: 8),
              Text(
                'Please read and accept our professional guidelines to finalize your instructor application.',
                style: GoogleFonts.lexend(fontSize: 13, color: const Color(0xFF6B7B8D), height: 1.4),
              ),
              const SizedBox(height: 24),

              // ===== حاوية نص السياسة (قابلة للتمرير) =====
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _policyText,
                      style: GoogleFonts.lexend(fontSize: 13, color: const Color(0xFF1B2A4A), height: 1.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ===== خانة تأكيد الموافقة (Checkbox) =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      activeColor: const Color(0xFF7B61FF),
                      onChanged: (value) {
                        setState(() {
                          _agreedToTerms = value ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _agreedToTerms = !_agreedToTerms;
                        });
                      },
                      child: Text(
                        'I have read, understood, and agree to the LearnMate Instructor Code of Conduct.',
                        style: GoogleFonts.lexend(fontSize: 13, color: const Color(0xFF6B7B8D), height: 1.4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // ===== زر إرسال الطلب وحفظ البيانات =====
              GestureDetector(
                onTap: (_agreedToTerms && !_isLoading) ? _submitData : null,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: (_agreedToTerms && !_isLoading) 
                        ? [const Color(0xFF7B61FF), const Color(0xFF9D85FF)]
                        : [const Color(0xFFE5E7EB), const Color(0xFFE5E7EB)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: (_agreedToTerms && !_isLoading) ? [
                      BoxShadow(
                        color: const Color(0xFF7B61FF).withValues(alpha: 0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ] : [],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading) ...[
                          const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Text('Saving...', style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ] else ...[
                          Text(
                            'Submit Application',
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: (_agreedToTerms && !_isLoading) ? Colors.white : const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: (_agreedToTerms && !_isLoading) ? Colors.white : const Color(0xFF9CA3AF),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
