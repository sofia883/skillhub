class AppConstants {
  // Development mode - set to true to bypass Firebase authentication
  static const bool devMode = false;

  // App Name
  static const String appName = 'Skill Hub';
  static const String appDescription = 'Find skills and offer your services';
  static const String appVersion = '1.0.0';

  // Auth Screen Text
  static const String welcome = 'Welcome to Skill Hub';
  static const String welcomeDescription =
      'Connect with skilled professionals and offer your expertise';
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = 'Don\'t have an account? ';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String createAccount = 'Create Account';
  static const String loginSuccess = 'Login successful';
  static const String signupSuccess = 'Account created successfully';

  // Validation Messages
  static const String emailEmpty = 'Email cannot be empty';
  static const String emailInvalid = 'Please enter a valid email';
  static const String passwordEmpty = 'Password cannot be empty';
  static const String passwordShort = 'Password must be at least 6 characters';
  static const String passwordsDontMatch = 'Passwords don\'t match';

  // Error Messages
  static const String authFailed = 'Authentication failed';
  static const String networkError = 'Network error. Please try again';
  static const String unknownError = 'Something went wrong. Please try again';
  static const String accountNotFound =
      'No account found with this email. Please sign up first.';
  static const String createFailed =
      'Failed to create account. Please try again.';
  static const String loginFailed = 'Failed to login. Please try again.';

  // API related constants
  static const String baseUrl = 'https://skill-hub-api.example.com';

  // Shared preferences keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';

  // Routes
  static const String homeRoute = '/home';
  static const String authRoute = '/auth';
  static const String welcomeRoute = '/welcome';
  static const String profileRoute = '/profile';
  static const String skillDetailRoute = '/skill-detail';
  static const String addSkillRoute = '/add-skill';

  // Assets
  static const String logoAsset = 'assets/images/logo.png';
  static const String placeholderImageAsset = 'assets/images/placeholder.png';
}
