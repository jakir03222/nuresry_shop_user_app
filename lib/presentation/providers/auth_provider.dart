import 'package:flutter/foundation.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isAuthenticated => _isAuthenticated;

  // Check if user is already logged in (load from storage)
  Future<void> checkAuthStatus() async {
    try {
      final accessToken = await StorageService.getAccessToken();
      final userEmail = await StorageService.getUserEmail();
      final userRole = await StorageService.getUserRole();
      final userStatus = await StorageService.getUserStatus();

      if (accessToken != null && userEmail != null) {
        // User has saved tokens, restore session
        _isAuthenticated = true;
        
        // Create user model from saved data
        // Note: We'll need to fetch full user data or reconstruct from saved info
        _user = UserModel(
          id: '', // Will be updated when we fetch user profile
          name: '', // Will be updated when we fetch user profile
          email: userEmail,
          role: userRole ?? 'user',
          isEmailVerified: true, // Assume verified if logged in
          status: userStatus ?? 'active',
          isDeleted: false,
        );
        
        notifyListeners();
      }
    } catch (e) {
      // If there's an error loading auth status, clear everything
      await StorageService.clearAll();
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.login(
        email: email,
        password: password,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final userData = data['user'] as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String;

        // Check role and status
        final role = userData['role'] as String? ?? 'user';
        final status = userData['status'] as String? ?? 'active';

        if (role != 'user') {
          _errorMessage = 'Access denied. Only users can login.';
          _isLoading = false;
          _isAuthenticated = false;
          notifyListeners();
          return false;
        }

        if (status != 'active') {
          _errorMessage = 'Your account is not active. Please contact support.';
          _isLoading = false;
          _isAuthenticated = false;
          notifyListeners();
          return false;
        }

        // Save tokens and user data
        await StorageService.saveAccessToken(accessToken);
        await StorageService.saveRefreshToken(refreshToken);
        await StorageService.saveUserEmail(userData['email'] as String);
        await StorageService.saveUserRole(role);
        await StorageService.saveUserStatus(status);

        // Create user model
        _user = UserModel.fromJsonMap(userData);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] as String? ?? 'Login failed';
        _isLoading = false;
        _isAuthenticated = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.signUp(
        name: name,
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        _successMessage = response['message'] as String? ?? 'Account created successfully. Please verify your email.';
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] as String? ?? 'Sign up failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail({
    required String token,
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.verifyEmail(
        token: token,
        email: email,
      );

      if (response['success'] == true) {
        _successMessage = response['message'] as String? ?? 'Email verified successfully';
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] as String? ?? 'Email verification failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void signOut() async {
    await StorageService.clearAll();
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
