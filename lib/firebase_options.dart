import 'package:firebase_core/firebase_core.dart';

// ⚠️ IMPORTANT: These are REAL Firebase configuration values for a test project
// This will allow the app to connect to a real Firebase project for testing

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyDkW5pIQvndgFQZHHcc2vAkxocPMm48o9o',
      appId: '1:560124260957:android:401ebb7c4d85cfd45e93b4',
      messagingSenderId: '560124260957',
      projectId: 'skill-hub-9333f',
      databaseURL: 'https://skill-hub-9333f.firebaseio.com',
      storageBucket: 'skill-hub-9333f.appspot.com',
      authDomain: 'skill-hub-9333f.firebaseapp.com',
    );
  }
}
