import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Connectivity Service: Detects online/offline status
/// Use this to check network availability before API calls
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Stream controller for connectivity changes
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _checkTimer;

  /// Initialize connectivity monitoring
  void initialize() {
    // Check immediately
    checkConnectivity();
    
    // Periodic check every 10 seconds
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      checkConnectivity();
    });
    
    debugPrint('[ConnectivityService] Initialized');
  }

  /// Dispose resources
  void dispose() {
    _checkTimer?.cancel();
    _connectivityController.close();
  }

  /// Check current connectivity by pinging a reliable server
  Future<bool> checkConnectivity() async {
    try {
      // Try to reach Google DNS (fast and reliable)
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      final connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (_isOnline != connected) {
        _isOnline = connected;
        _connectivityController.add(_isOnline);
        debugPrint('[ConnectivityService] Status changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      }
      
      return _isOnline;
    } on SocketException catch (_) {
      if (_isOnline) {
        _isOnline = false;
        _connectivityController.add(_isOnline);
        debugPrint('[ConnectivityService] Status changed: OFFLINE (SocketException)');
      }
      return false;
    } on TimeoutException catch (_) {
      if (_isOnline) {
        _isOnline = false;
        _connectivityController.add(_isOnline);
        debugPrint('[ConnectivityService] Status changed: OFFLINE (Timeout)');
      }
      return false;
    } catch (e) {
      debugPrint('[ConnectivityService] Error checking connectivity: $e');
      return _isOnline;
    }
  }

  /// Quick check without updating state (for single API call)
  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
