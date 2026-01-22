import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserStatus = 'user_status';

  // Save Access Token
  static Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, token);
  }

  // Get Access Token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  // Save Refresh Token
  static Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRefreshToken, token);
  }

  // Get Refresh Token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  // Save User Email
  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
  }

  // Get User Email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  // Save User Role
  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserRole, role);
  }

  // Get User Role
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole);
  }

  // Save User Status
  static Future<void> saveUserStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserStatus, status);
  }

  // Get User Status
  static Future<String?> getUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserStatus);
  }

  // Clear All Data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyUserStatus);
  }
}
