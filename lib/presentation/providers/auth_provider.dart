import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/sync_service.dart';

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

  Future<bool> signIn({
    required String emailOrPhone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.login(
        emailOrPhone: emailOrPhone,
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
        // Save email if available (may be null if logged in with phone)
        final userEmail = userData['email'] as String?;
        if (userEmail != null && userEmail.isNotEmpty) {
          await StorageService.saveUserEmail(userEmail);
        }
        await StorageService.saveUserRole(role);
        await StorageService.saveUserStatus(status);

        // Create user model
        _user = UserModel.fromJsonMap(userData);
        _isAuthenticated = true;
        _isLoading = false;
        
        // Save user profile to SQLite cache
        await DatabaseService.saveUserProfile(userData);
        
        // Trigger background sync to cache all user data for offline use
        SyncService().syncAllData();
        
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
    required String emailOrPhone,
    required String password,
    File? profileImage,
  }) async {
    if (emailOrPhone.trim().isEmpty) {
      _errorMessage = 'Email or phone is required';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    
    debugPrint('[AuthProvider.signUp] Starting signup process...');
    debugPrint('[AuthProvider.signUp] Parameters:');
    debugPrint('  - name: $name');
    debugPrint('  - emailOrPhone: $emailOrPhone');
    debugPrint('  - password length: ${password.length}');
    debugPrint('  - profileImage: ${profileImage?.path ?? 'null'}');
    
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      debugPrint('[AuthProvider.signUp] Calling ApiService.signUp...');
      final response = await ApiService.signUp(
        name: name,
        emailOrPhone: emailOrPhone,
        password: password,
        profileImage: profileImage,
      );

      debugPrint('[AuthProvider.signUp] API Response received:');
      debugPrint('  - success: ${response['success']}');
      debugPrint('  - message: ${response['message']}');
      debugPrint('  - data: ${response['data']}');

      if (response['success'] == true) {
        _successMessage = response['message'] as String? ?? 'Account created successfully. Please verify your email.';
        _isLoading = false;
        debugPrint('[AuthProvider.signUp] Signup successful! Message: $_successMessage');
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] as String? ?? 'Sign up failed';
        _isLoading = false;
        debugPrint('[AuthProvider.signUp] Signup failed: $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      debugPrint('[AuthProvider.signUp] Exception caught:');
      debugPrint('  - Error: $e');
      debugPrint('  - Stack Trace: $stackTrace');
      debugPrint('  - Error Message: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail({
    required String otp,
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.verifyEmail(
        otp: otp,
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
      final response = await ApiService.forgotPassword(
        email: email,
      );

      if (response['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to send reset link';
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

  /// Sign out: Clears ALL user data from SharedPreferences and SQLite database
  Future<void> signOut() async {
    debugPrint('[AuthProvider] ========== LOGOUT START ==========');
    
    // Clear all SharedPreferences (tokens, user info)
    await StorageService.clearAll();
    debugPrint('[AuthProvider] SharedPreferences cleared');
    
    // Clear ALL SQLite database tables (user data + cached data)
    // This ensures fast app reload after re-login
    await DatabaseService.clearAllData();
    debugPrint('[AuthProvider] SQLite database cleared');
    
    // Clear auth state
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    _successMessage = null;
    _isLoading = false;
    
    debugPrint('[AuthProvider] ========== LOGOUT COMPLETE ==========');
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

  // Load user profile - with SQLite cache
  Future<void> loadProfile({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check SQLite cache first (unless force refresh)
      if (!forceRefresh) {
        final cachedProfile = await DatabaseService.getUserProfile();
        if (cachedProfile != null) {
          _user = UserModel.fromJsonMap(cachedProfile);
          _isLoading = false;
          notifyListeners();

          // Check if data is stale, refresh in background
          final isStale = await DatabaseService.isDataStale(
            DatabaseService.tableUser,
            maxAgeMinutes: 15,
          );
          if (isStale) {
            // Refresh in background without blocking UI
            _refreshProfileFromApi();
          }
          return;
        }
      }

      // Fetch from API
      final response = await ApiService.getProfile();

      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'] as Map<String, dynamic>;
        _user = UserModel.fromJsonMap(userData);
        
        // Save to SQLite cache
        await DatabaseService.saveUserProfile(userData);
        
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to load profile';
        debugPrint('[loadProfile] API error: success=false, message=$_errorMessage');
        _isLoading = false;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      // If API fails, try to load from cache
      try {
        final cachedProfile = await DatabaseService.getUserProfile();
        if (cachedProfile != null) {
          _user = UserModel.fromJsonMap(cachedProfile);
        }
      } catch (_) {}

      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('[loadProfile] Exception: $e');
      debugPrint('[loadProfile] stackTrace: $stackTrace');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshProfileFromApi() async {
    try {
      final response = await ApiService.getProfile();
      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'] as Map<String, dynamic>;
        await DatabaseService.saveUserProfile(userData);
        // Update UI if currently viewing profile
        _user = UserModel.fromJsonMap(userData);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AuthProvider] Background profile refresh failed: $e');
    }
  }

  // Update user profile (avatarId = selected avatar; profilePicture = gallery image)
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? mobile,
    String? avatarId,
    File? profilePicture,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.updateProfile(
        name: name,
        email: email,
        mobile: mobile,
        avatarId: avatarId,
        profilePicture: profilePicture,
      );

      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'] as Map<String, dynamic>;
        _user = UserModel.fromJsonMap(userData);
        
        // Save updated profile to SQLite cache
        await DatabaseService.saveUserProfile(userData);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to update profile';
        debugPrint('[updateProfile] API error: success=false, message=$_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('[updateProfile] Exception: $e');
      debugPrint('[updateProfile] stackTrace: $stackTrace');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
