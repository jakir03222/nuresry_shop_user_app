import 'package:flutter/foundation.dart';
import '../../../data/models/coupon_model.dart';
import '../../../data/services/api_service.dart';
import '../../../core/services/database_service.dart';

class CouponProvider with ChangeNotifier {
  List<CouponModel> _coupons = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CouponModel> get coupons => _coupons;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCoupons({
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check SQLite cache first (unless force refresh or pagination)
      if (!forceRefresh && page == 1) {
        final cachedCoupons = await DatabaseService.getCoupons();
        if (cachedCoupons.isNotEmpty) {
          _coupons = cachedCoupons
              .map((json) => CouponModel.fromJsonMap(json))
              .toList();
          _isLoading = false;
          notifyListeners();

          // Refresh in background if stale
          final isStale = await DatabaseService.isDataStale(
            DatabaseService.tableCoupons,
            maxAgeMinutes: 60,
          );
          if (isStale) {
            _refreshCouponsFromApi(page, limit);
          }
          return;
        }
      }

      // Fetch from API
      final response = await ApiService.getCoupons(page: page, limit: limit);

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> couponData = response['data'] as List<dynamic>;
        _coupons = couponData
            .map((json) => CouponModel.fromJsonMap(json as Map<String, dynamic>))
            .toList();

        // Save to SQLite (only first page for cache)
        if (page == 1) {
          await DatabaseService.saveCoupons(
            couponData.map((e) => e as Map<String, dynamic>).toList(),
          );
        }
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to load coupons';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If API fails, try to load from cache
      if (page == 1) {
        try {
          final cachedCoupons = await DatabaseService.getCoupons();
          if (cachedCoupons.isNotEmpty) {
            _coupons = cachedCoupons
                .map((json) => CouponModel.fromJsonMap(json))
                .toList();
          }
        } catch (_) {}
      }

      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshCouponsFromApi(int page, int limit) async {
    try {
      final response = await ApiService.getCoupons(page: page, limit: limit);
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> couponData = response['data'] as List<dynamic>;
        await DatabaseService.saveCoupons(
          couponData.map((e) => e as Map<String, dynamic>).toList(),
        );
        // Update UI
        _coupons = couponData
            .map((json) => CouponModel.fromJsonMap(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[CouponProvider] Background refresh failed: $e');
    }
  }
}
