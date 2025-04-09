import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_hub/features/home/presentation/pages/home_screen.dart';
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
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('Firebase initialized successfully');

    // Initialize Firestore settings for offline support
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true, // Enable offline persistence
      cacheSizeBytes:
          Settings.CACHE_SIZE_UNLIMITED, // Allow unlimited cache size
    );

    // We'll skip anonymous auth as it's causing errors
    // The app will still work in offline mode

    // Don't wait for the test document to be created
    FirebaseFirestore.instance
        .collection('test_collection')
        .doc('test_document')
        .set({'timestamp': FieldValue.serverTimestamp()})
        .timeout(const Duration(seconds: 3))
        .then((_) => print('Firestore connection test successful'))
        .catchError(
            (e) => print('Firestore test failed but app will continue: $e'));
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
      home: const LoginScreen(),
    );
  }
}
