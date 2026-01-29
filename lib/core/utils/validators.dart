import '../constants/app_constants.dart';

class Validators {
  static bool isEmail(String value) {
    final v = value.trim();
    return v.isNotEmpty && RegExp(AppConstants.emailPattern).hasMatch(v);
  }

  static bool isMobile(String value) {
    final v = value.trim();
    return v.isNotEmpty && RegExp(AppConstants.mobilePattern).hasMatch(v);
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(AppConstants.emailPattern).hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validateEmailOrPhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Email or phone is required';
    }
    if (!isEmail(v) && !isMobile(v)) {
      return 'Please enter a valid email or 11-digit phone number';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (value.length > AppConstants.passwordMaxLength) {
      return 'Password must be less than ${AppConstants.passwordMaxLength} characters';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    if (!RegExp(AppConstants.mobilePattern).hasMatch(value)) {
      return 'Please enter a valid 11-digit mobile number';
    }
    return null;
  }

  /// Optional mobile: empty is valid; if provided, must be valid 11-digit.
  static String? validateMobileOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(AppConstants.mobilePattern).hasMatch(value.trim())) {
      return 'Please enter a valid 11-digit mobile number';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > AppConstants.nameMaxLength) {
      return 'Name must be less than ${AppConstants.nameMaxLength} characters';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Bangladesh postal code: 4 digits (e.g. 1212, 1000)
  static String? validateBangladeshPostalCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Postal code is required';
    if (!RegExp(r'^[0-9]{4}$').hasMatch(v)) {
      return 'Enter a valid 4-digit postal code';
    }
    return null;
  }
}
