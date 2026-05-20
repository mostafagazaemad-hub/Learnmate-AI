import 'dart:async';  
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/google_sign_in_button.dart';
import '../../core/services/auth_service.dart';
import 'signup_screen.dart';
import 'role_selection_dialog.dart';
import '../main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _emailController  = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        print("LoginScreen _signInWithGoogle exception: $e");
        _showError('Sign-in failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.instance.signInWithEmail(
        email: email,
        password: password,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
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
        _showError(result.errorMessage ?? 'Login failed.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('An unexpected error occurred. Please try again.');
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double horizontalPadding = 24.0;

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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: screenHeight * 0.06),
    
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
                            'LearnMate',
                            style: GoogleFonts.lexend(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B2A4A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your intelligent study companion',
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6B7B8D),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.05),

                    _buildLabel('Email or Phone Number'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        hintText: 'name@example.com',
                        prefixIcon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Password'),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.lexend(
                                color: const Color(0xFF7B61FF),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        hintText: 'Min. 8 characters',
                        prefixIcon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    _buildLoginButton(),
                    
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: GoogleFonts.lexend(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildGoogleButton(),
                    
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.lexend(
                            color: const Color(0xFF6B7B8D),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignupScreen()),
                            );
                          },
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF7B61FF),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    Text.rich(
                      TextSpan(
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                          height: 1.5,
                        ),
                        children: const [
                          TextSpan(text: 'By signing in, you agree to our '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(color: Color(0xFF7B61FF), fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(color: Color(0xFF7B61FF), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
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

  InputDecoration _inputDecoration({required String hintText, required IconData prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.lexend(color: const Color(0xFF9CA3AF), fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF9CA3AF), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
      ),
    );
  }



  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _signInWithEmail,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF7B61FF),
              Color(0xFF9D85FF),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B61FF).withOpacity(0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Login',
                  style: GoogleFonts.lexend(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
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
}


class _MiniRobotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width / 72; 

    final headRect = Rect.fromCenter(
      center: Offset(cx, cy + 2 * s),
      width: 36 * s,
      height: 30 * s,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, Radius.circular(10 * s)),
      Paint()..color = Colors.white.withOpacity(0.90),
    );


    final eyeGlow = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF4FC3F7),
          Color(0xFF2196F3),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(cx - 7 * s, cy),
        radius: 5 * s,
      ));


    canvas.drawCircle(
      Offset(cx - 7 * s, cy),
      6 * s,
      Paint()..color = const Color(0xFFE8F0FE),
    );
    canvas.drawCircle(Offset(cx - 7 * s, cy), 4.5 * s, eyeGlow);
    canvas.drawCircle(
      Offset(cx - 6 * s, cy - 1 * s),
      2 * s,
      Paint()..color = const Color(0xFF0D47A1),
    );
    canvas.drawCircle(
      Offset(cx - 5 * s, cy - 2 * s),
      1 * s,
      Paint()..color = Colors.white,
    );


    final eyeGlow2 = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF4FC3F7),
          Color(0xFF2196F3),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(cx + 7 * s, cy),
        radius: 5 * s,
      ));
    canvas.drawCircle(
      Offset(cx + 7 * s, cy),
      6 * s,
      Paint()..color = const Color(0xFFE8F0FE),
    );
    canvas.drawCircle(Offset(cx + 7 * s, cy), 4.5 * s, eyeGlow2);
    canvas.drawCircle(
      Offset(cx + 8 * s, cy - 1 * s),
      2 * s,
      Paint()..color = const Color(0xFF0D47A1),
    );
    canvas.drawCircle(
      Offset(cx + 9 * s, cy - 2 * s),
      1 * s,
      Paint()..color = Colors.white,
    );


    final smilePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(cx - 6 * s, cy + 8 * s)
      ..quadraticBezierTo(cx, cy + 13 * s, cx + 6 * s, cy + 8 * s);
    canvas.drawPath(smilePath, smilePaint);


    canvas.drawLine(
      Offset(cx, cy - 13 * s),
      Offset(cx, cy - 20 * s),
      Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..strokeWidth = 2 * s
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(cx, cy - 22 * s),
      3 * s,
      Paint()..color = Colors.white.withOpacity(0.85),
    );
    canvas.drawCircle(
      Offset(cx - 1 * s, cy - 23 * s),
      1 * s,
      Paint()..color = Colors.white,
    );

 
    final earPaint = Paint()..color = Colors.white.withOpacity(0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - 20 * s, cy + 1 * s),
          width: 4 * s,
          height: 10 * s,
        ),
        Radius.circular(2 * s),
      ),
      earPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + 20 * s, cy + 1 * s),
          width: 4 * s,
          height: 10 * s,
        ),
        Radius.circular(2 * s),
      ),
      earPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24; 
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = 10 * s;

  
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -0.9, 
      1.6,  
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8 * s
        ..strokeCap = StrokeCap.butt,
    );


    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      0.7,
      1.0,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8 * s
        ..strokeCap = StrokeCap.butt,
    );

   
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      1.7,
      0.9,
      false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8 * s
        ..strokeCap = StrokeCap.butt,
    );

   
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      2.6,
      0.8,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8 * s
        ..strokeCap = StrokeCap.butt,
    );

    
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(cx - 1 * s, cy - 1.8 * s, radius + 1.5 * s, 3.6 * s),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
