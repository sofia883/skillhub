import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/user_repository.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/auth/presentation/pages/signup_screen.dart';
import 'features/auth/presentation/pages/welcome_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // For development, allow app to continue even without Firebase properly configured
    print('Firebase initialization failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // Use SignupScreen directly
      home: const LoginScreen(),
    );
  }

  Widget _handleAuthState() {
    final userRepository = UserRepository();
    final currentUser = userRepository.getCurrentUser();

    // If user is already logged in, show welcome screen
    if (currentUser != null) {
      return const WelcomeScreen();
    }

    // Otherwise show login screen
    return const LoginScreen();
  }
}
