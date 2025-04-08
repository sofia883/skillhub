class AppConstants {
  // App Info
  static const String appName = 'Skill Hub';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String baseUrl = 'https://api.skillhub.com';

  // Auth Constants
  static const int minimumPasswordLength = 8;

  // Validation Messages
  static const String emailEmpty = 'Email is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String passwordEmpty = 'Password is required';
  static const String passwordTooShort =
      'Password must be at least 8 characters';
  static const String nameEmpty = 'Name is required';
}
