import 'package:flutter/foundation.dart';
import '../../../data/models/coupon_model.dart';
import '../../../data/services/api_service.dart';

class CouponProvider with ChangeNotifier {
  List<CouponModel> _coupons = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CouponModel> get coupons => _coupons;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCoupons({int page = 1, int limit = 10}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getCoupons(page: page, limit: limit);

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> couponData = response['data'] as List<dynamic>;
        _coupons = couponData
            .map((json) => CouponModel.fromJsonMap(json as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to load coupons';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }
}
