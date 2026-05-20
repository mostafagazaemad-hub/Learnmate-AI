import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_colors.dart';
import 'login_screen.dart';
import 'teacher_profile_screen.dart';
import '../main_layout.dart';
import 'role_selection_dialog.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); 
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool isStudent = true;
  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showRoleSelection() {
    RoleSelectionDialog.show(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.lexend(fontSize: 13)),
        backgroundColor: const Color(0xFFB00020),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.instance.signInWithGoogle();
      if (!mounted) return;
      if (result.isSuccess) {
        if (result.needsRoleSelection) {
          _showRoleSelection();
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainLayout()),
            (route) => false,
          );
        }
      } else {
        _showError(result.errorMessage ?? 'Sign-in failed.');
      }
    } catch (e) {
      if (mounted) {
        print("SignupScreen _signInWithGoogle exception: $e");
        _showError('Sign-in failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4A90E2).withOpacity(0.05),
              const Color(0xFF7B61FF).withOpacity(0.05),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7B61FF).withOpacity(0.06),
                ),
              ),
            ),
            
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: screenHeight * 0.04),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF4A90E2), Color(0xFF7B61FF)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7B61FF).withOpacity(0.25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: CustomPaint(painter: _MiniRobotPainter()),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Create Account',
                                style: GoogleFonts.lexend(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B2A4A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Join our learning community today',
                                style: GoogleFonts.lexend(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6B7B8D),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.035),
                        Text(
                          'I AM A...',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B2A4A),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildRoleSelector(),

                        const SizedBox(height: 24),
                        _buildLabel('Full Name'),
                        _buildTextField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          hintText: 'John Doe',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (value) => value != null && value.isNotEmpty ? null : 'Please enter your name',
                          onSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
                        ),

                        const SizedBox(height: 18),

                        _buildLabel('Email Address'),
                        _buildTextField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          hintText: 'name@example.com',
                          prefixIcon: Icons.email_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter email';
                            if (!value.contains('@')) return 'Please enter a valid email';
                            return null;
                          },
                          onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                        ),

                        const SizedBox(height: 18),

                        _buildLabel('Password'),
                        _buildTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          hintText: 'Min. 8 characters',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          validator: (value) => value != null && value.length >= 8 ? null : 'Min. 8 characters required',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),

                        const SizedBox(height: 20),
                        _buildTermsCheckbox(),

                        const SizedBox(height: 28),
                        _buildSignUpButton(),

                        const SizedBox(height: 24),
                        _buildDivider(),

                        const SizedBox(height: 24),

                        _buildGoogleButton(),

                        const SizedBox(height: 28),
                        _buildFooter(),
                        
                        SizedBox(height: bottomPadding + 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.lexend(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1B2A4A),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildRoleTab('Student', Icons.school_outlined, isStudent, () => setState(() => isStudent = true)),
          _buildRoleTab('Teacher', Icons.verified_user_outlined, !isStudent, () => setState(() => isStudent = false)),
        ],
      ),
    );
  }

  Widget _buildRoleTab(String label, IconData icon, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? const Color(0xFF7B61FF) : const Color(0xFF6B7B8D)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.lexend(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? const Color(0xFF1B2A4A) : const Color(0xFF6B7B8D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
            activeColor: const Color(0xFF7B61FF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.lexend(fontSize: 12, color: const Color(0xFF6B7B8D), height: 1.5),
              children: const [
                TextSpan(text: 'I agree to the '),
                TextSpan(text: 'Terms of Service', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF7B61FF))),
                TextSpan(text: ' and '),
                TextSpan(text: 'Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF7B61FF))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return GestureDetector(
      onTap: (_agreeToTerms && !_isLoading)
          ? () async {
              if (!_formKey.currentState!.validate()) return;
              setState(() => _isLoading = true);

              final result = await AuthService.instance.signUpWithEmail(
                email: _emailController.text,
                password: _passwordController.text,
                displayName: _nameController.text,
              );

              if (!mounted) return;

              if (result.isSuccess && result.user != null) {
                final user = result.user!;
                final userModel = UserModel(
                  uid: user.uid,
                  email: user.email ?? '',
                  displayName: _nameController.text.trim(),
                  role: isStudent ? UserRole.student : UserRole.teacher,
                  createdAt: DateTime.now(),
                );
                final nav = Navigator.of(context);

                try {
                  await FirestoreService.instance.createUser(userModel);
                } catch (_) {
                  // Handle error
                }

                setState(() => _isLoading = false);

                if (!isStudent) {
                  nav.pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const TeacherProfileScreen()),
                  );
                } else {
                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const MainLayout()),
                    (route) => false,
                  );
                }
              } else {
                setState(() => _isLoading = false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.errorMessage ?? 'Registration failed.',
                      style: GoogleFonts.lexend(fontSize: 13),
                    ),
                    backgroundColor: const Color(0xFFB00020),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _agreeToTerms
                ? [const Color(0xFF7B61FF), const Color(0xFF9D85FF)]
                : [
                    const Color(0xFF7B61FF).withOpacity(0.4),
                    const Color(0xFF9D85FF).withOpacity(0.4)
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _agreeToTerms
              ? [
                  BoxShadow(
                      color: const Color(0xFF7B61FF).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6))
                ]
              : [],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  'Create Account',
                  style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('or continue with', style: GoogleFonts.lexend(fontSize: 12, color: const Color(0xFF9CA3AF)))),
        Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _signInWithGoogle,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7B61FF)),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.g_mobiledata, size: 36, color: Color(0xFF4285F4)),
                    const SizedBox(width: 8),
                    Text(
                      'Google',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B2A4A),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account? ', style: GoogleFonts.lexend(fontSize: 14, color: const Color(0xFF6B7B8D))),
        GestureDetector(
          onTap: _navigateToLogin,
          child: Text('Login', style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF7B61FF))),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF9CA3AF), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5)),
      ),
    );
  }
}

class _MiniRobotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width / 72;
    final headRect = Rect.fromCenter(center: Offset(cx, cy + 2 * s), width: 36 * s, height: 30 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(headRect, Radius.circular(10 * s)), Paint()..color = Colors.white.withOpacity(0.9));

    canvas.drawCircle(Offset(cx - 7 * s, cy), 4.5 * s, Paint()..color = const Color(0xFF2196F3));
    canvas.drawCircle(Offset(cx + 7 * s, cy), 4.5 * s, Paint()..color = const Color(0xFF2196F3));
    
    final smilePaint = Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 1.5 * s..strokeCap = StrokeCap.round;
    final smilePath = Path()..moveTo(cx - 5 * s, cy + 8 * s)..quadraticBezierTo(cx, cy + 12 * s, cx + 5 * s, cy + 8 * s);
    canvas.drawPath(smilePath, smilePaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
