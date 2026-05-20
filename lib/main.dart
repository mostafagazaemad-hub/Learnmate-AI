import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'firebase_options.dart';
import 'core/theme/app_colors.dart';
import 'core/services/settings_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'views/main_layout.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/role_selection_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('--- Starting App Initialization ---');
  
  // Register WebView platform for Flutter Web
  if (kIsWeb) {
    try {
      WebViewPlatform.instance = WebWebViewPlatform();
      debugPrint('WebView Platform registered for Web');
    } catch (e) {
      debugPrint('WebView registration failed: $e');
    }
  }
  
  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
    
    debugPrint('Initializing SettingsService...');
    await SettingsService().init();
    debugPrint('SettingsService initialized');
  } catch (e) {
    debugPrint('CRITICAL: Initialization failed: $e');
  }
  
  debugPrint('Running App...');
  runApp(const LearnMateAI());
}

class LearnMateAI extends StatelessWidget {
  const LearnMateAI({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService(),
      builder: (context, _) {
        final settings = SettingsService();
        final isDark = settings.isDarkMode;

        return MaterialApp(
          title: 'LearnMate AI',
          debugShowCheckedModeBanner: false,
          locale: settings.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.white,
              elevation: 0,
              centerTitle: false,
              iconTheme: IconThemeData(color: AppColors.textPrimary),
              titleTextStyle: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.darkBackground,
            cardColor: AppColors.darkCard,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.darkCard,
              elevation: 0,
              centerTitle: false,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
              bodyMedium: TextStyle(color: AppColors.darkTextPrimary),
              titleLarge: TextStyle(color: AppColors.darkTextPrimary),
            ),
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(), // Start from Splash Screen
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Show splash for 0.5 seconds for faster testing
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Background pattern or soft gradient
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/cubes.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated-like Logo
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40),
                    ],
                  ),
                  child: const Icon(Icons.school_rounded, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 32),
                const Text(
                  'LearnMate AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Intelligent Study Partner',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 60),
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'POWERED BY ADVANCED AI',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authSnapshot.hasData) {
          final user = authSnapshot.data!;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                if (data != null && 
                    (data['hasSelectedRole'] == true || data['role'] != null)) {
                  return const MainLayout();
                }
              }
              
              return Scaffold(
                backgroundColor: SettingsService().isDarkMode ? AppColors.darkBackground : AppColors.background,
                body: const Center(
                  child: RoleSelectionDialog(),
                ),
              );
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
