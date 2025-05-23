import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_hub/features/auth/presentation/pages/login_screen.dart';
import 'package:skill_hub/features/auth/presentation/pages/welcome_screen.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/services/connectivity_service.dart';
import 'core/widgets/network_aware_widget.dart';
import 'core/widgets/main_container.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/widgets/offline_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize connectivity service
  await ConnectivityService().initialize();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('Firebase initialized successfully');

    // Initialize Firestore settings for offline support
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true, // Enable offline persistence
      cacheSizeBytes:
          Settings.CACHE_SIZE_UNLIMITED, // Allow unlimited cache size
    );

    // Sign in anonymously to get a user ID for Firestore security rules
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      debugPrint(
          '✅ Signed in anonymously with user ID: ${userCredential.user?.uid}');
    } catch (e) {
      debugPrint('⚠️ Failed to sign in anonymously: $e');
      // Continue anyway, we'll try to use Firestore without authentication
    }

    // Test Firestore connection
    try {
      // Create a test document to verify connection
      await FirebaseFirestore.instance
          .collection('test_collection')
          .doc('test_document')
          .set({
        'timestamp': FieldValue.serverTimestamp(),
        'testValue': 'This is a test document',
        'appStarted': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 10));

      debugPrint('✅ Firestore connection successful - data can be saved');

      // Try to read the document back to verify read access
      final testDoc = await FirebaseFirestore.instance
          .collection('test_collection')
          .doc('test_document')
          .get()
          .timeout(const Duration(seconds: 10));

      if (testDoc.exists) {
        debugPrint('✅ Firestore read successful - data can be retrieved');
        debugPrint('✅ Test document data: ${testDoc.data()}');
      } else {
        debugPrint('⚠️ Firestore document not found - check security rules');
      }

      // Check if skills collection exists
      final skillsCollection = await FirebaseFirestore.instance
          .collection('skills')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      debugPrint('✅ Skills collection access successful');
      debugPrint('✅ Number of skills found: ${skillsCollection.docs.length}');
    } catch (firestoreError) {
      debugPrint('⚠️ Firestore test failed: $firestoreError');
      debugPrint('⚠️ The app will run in offline mode only');
      debugPrint(
          '⚠️ Check your Firebase configuration and internet connection');

      // Show more detailed error information
      if (firestoreError is FirebaseException) {
        debugPrint('Firebase error code: ${firestoreError.code}');
        debugPrint('Firebase error message: ${firestoreError.message}');
      }
    }
  } catch (e) {
    // For development, allow app to continue even without Firebase properly configured
    debugPrint('❌ Firebase initialization failed: $e');
    debugPrint('❌ The app will run in offline mode only');
    debugPrint(
        '❌ Make sure to update firebase_options.dart with your project details');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _connectivityService = ConnectivityService();
  bool _showOfflineIndicator = false;
  String? _lastRoute;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadLastRoute();
    _setupConnectivityListener();
  }

  Future<void> _loadLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastRoute = prefs.getString('last_route');
    });
  }

  void _setupConnectivityListener() {
    _connectivityService.connectivityStream.listen((status) {
      setState(() {
        _showOfflineIndicator = status == ConnectivityStatus.offline;
      });
    });
  }

  Future<void> _saveCurrentRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_route', route);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              child ?? const SizedBox(),
              if (_showOfflineIndicator)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: OfflineIndicator(
                    onRetry: () => _connectivityService.checkConnectivity(),
                  ),
                ),
            ],
          ),
        );
      },
      home: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            // User is logged in
            return const MainContainer();
          } else {
            // User is not logged in
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}
