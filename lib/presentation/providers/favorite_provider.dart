import 'package:flutter/foundation.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';

class FavoriteProvider with ChangeNotifier {
  final List<String> _favoriteIds = [];
  final List<ProductModel> _wishlistProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<String> get favoriteIds => _favoriteIds;
  List<ProductModel> get wishlistProducts => _wishlistProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get wishlistCount => _wishlistProducts.length;
  
  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId) || 
           _wishlistProducts.any((p) => p.id == productId);
  }

  Future<void> loadWishlist() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getMyWishlist();

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final productIds = data['productIds'] as List<dynamic>? ?? [];
        
        _wishlistProducts.clear();
        _favoriteIds.clear();
        
        for (final productJson in productIds) {
          final productMap = productJson as Map<String, dynamic>;
          final product = ProductModel.fromJsonMap(productMap);
          _wishlistProducts.add(product);
          _favoriteIds.add(product.id);
        }
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to load wishlist';
        _wishlistProducts.clear();
        _favoriteIds.clear();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _wishlistProducts.clear();
      _favoriteIds.clear();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> removeFromWishlist(String productId) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.removeFromWishlist(productId);

      if (response['success'] == true) {
        _wishlistProducts.removeWhere((p) => p.id == productId);
        _favoriteIds.remove(productId);
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to remove from wishlist';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearWishlist() async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.clearWishlist();

      if (response['success'] == true) {
        _wishlistProducts.clear();
        _favoriteIds.clear();
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to clear wishlist';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Add to Wishlist via API
  Future<bool> addToWishlist(String productId) async {
    if (_favoriteIds.contains(productId)) {
      return true; // Already in wishlist
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.addToWishlist(productId);

      if (response['success'] == true) {
        // Reload wishlist to get updated product data
        await loadWishlist();
        return true;
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to add to wishlist';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Toggle favorite (calls API for both add and remove)
  Future<void> toggleFavorite(String productId) async {
    if (_favoriteIds.contains(productId)) {
      // Remove from wishlist via API
      await removeFromWishlist(productId);
    } else {
      // Add to wishlist via API
      await addToWishlist(productId);
    }
  }

  void addToFavorites(String productId) {
    if (!_favoriteIds.contains(productId)) {
      _favoriteIds.add(productId);
      notifyListeners();
    }
  }

  void removeFromFavorites(String productId) {
    _favoriteIds.remove(productId);
    _wishlistProducts.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  void clearFavorites() {
    _favoriteIds.clear();
    _wishlistProducts.clear();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all wishlist data (for logout)
  void clearAllData() {
    _favoriteIds.clear();
    _wishlistProducts.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
