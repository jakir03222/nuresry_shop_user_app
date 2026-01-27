import 'package:flutter/foundation.dart';
import '../../../data/models/address_model.dart';
import '../../../data/services/api_service.dart';
import '../../../core/services/database_service.dart';

class AddressProvider with ChangeNotifier {
  final List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AddressModel? get defaultAddress {
    if (_addresses.isEmpty) return null;
    try {
      return _addresses.firstWhere((addr) => addr.isDefault);
    } catch (_) {
      return _addresses.first;
    }
  }

  Future<void> loadAddresses({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check SQLite cache first (unless force refresh)
      if (!forceRefresh) {
        final cachedAddresses = await DatabaseService.getAddresses();
        if (cachedAddresses.isNotEmpty) {
          _addresses.clear();
          _addresses.addAll(
            cachedAddresses
                .map((json) => AddressModel.fromJsonMap(json)),
          );
          _isLoading = false;
          notifyListeners();

          // Refresh in background if stale
          final isStale = await DatabaseService.isDataStale(
            DatabaseService.tableAddresses,
            maxAgeMinutes: 30,
          );
          if (isStale) {
            _refreshAddressesFromApi();
          }
          return;
        }
      }

      // Fetch from API
      final response = await ApiService.getAddresses();

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        _addresses.clear();
        _addresses.addAll(
          data.map((json) => AddressModel.fromJsonMap(json as Map<String, dynamic>)),
        );

        // Save to SQLite
        await DatabaseService.saveAddresses(
          data.map((e) => e as Map<String, dynamic>).toList(),
        );
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to load addresses';
        _addresses.clear();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If API fails, try to load from cache
      try {
        final cachedAddresses = await DatabaseService.getAddresses();
        if (cachedAddresses.isNotEmpty) {
          _addresses.clear();
          _addresses.addAll(
            cachedAddresses
                .map((json) => AddressModel.fromJsonMap(json)),
          );
        }
      } catch (_) {}

      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _addresses.clear();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshAddressesFromApi() async {
    try {
      final response = await ApiService.getAddresses();
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        await DatabaseService.saveAddresses(
          data.map((e) => e as Map<String, dynamic>).toList(),
        );
        // Update UI
        _addresses.clear();
        _addresses.addAll(
          data.map((json) => AddressModel.fromJsonMap(json as Map<String, dynamic>)),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AddressProvider] Background refresh failed: $e');
    }
  }

  Future<bool> createAddress({
    required String street,
    required String city,
    required String postalCode,
    required String country,
    required String phoneNumber,
    bool isDefault = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.createAddress(
        street: street,
        city: city,
        postalCode: postalCode,
        country: country,
        phoneNumber: phoneNumber,
        isDefault: isDefault,
      );

      if (response['success'] == true) {
        await loadAddresses();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to create address';
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

  Future<bool> updateAddress({
    required String addressId,
    String? street,
    String? city,
    String? postalCode,
    String? country,
    String? phoneNumber,
    bool? isDefault,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.updateAddress(
        addressId: addressId,
        street: street,
        city: city,
        postalCode: postalCode,
        country: country,
        phoneNumber: phoneNumber,
        isDefault: isDefault,
      );

      if (response['success'] == true) {
        await loadAddresses();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to update address';
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

  Future<bool> deleteAddress(String addressId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.deleteAddress(addressId);

      if (response['success'] == true) {
        _addresses.removeWhere((addr) => addr.id == addressId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to delete address';
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
