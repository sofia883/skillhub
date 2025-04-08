import '../constants/app_constants.dart';

class FormValidators {
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.emailEmpty;
    }

    // Simple email validation regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return AppConstants.emailInvalid;
    }

    return null;
  }

  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.passwordEmpty;
    }

    if (value.length < 6) {
      return AppConstants.passwordShort;
    }

    return null;
  }

  static String? confirmPasswordValidator(String? value, String password) {
    if (value == null || value.isEmpty) {
      return AppConstants.passwordEmpty;
    }

    if (value != password) {
      return AppConstants.passwordsDontMatch;
    }

    return null;
  }
}
