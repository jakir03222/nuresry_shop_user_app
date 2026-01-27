import 'package:flutter/foundation.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import '../../../core/services/database_service.dart';

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

  Future<void> loadWishlist({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check SQLite cache first (unless force refresh)
      if (!forceRefresh) {
        final cachedWishlist = await DatabaseService.getWishlist();
        if (cachedWishlist.isNotEmpty) {
          _wishlistProducts.clear();
          _favoriteIds.clear();
          
          for (final productJson in cachedWishlist) {
            final product = ProductModel.fromJsonMap(productJson);
            _wishlistProducts.add(product);
            _favoriteIds.add(product.id);
          }
          
          _isLoading = false;
          notifyListeners();

          // Refresh in background if stale
          final isStale = await DatabaseService.isDataStale(
            DatabaseService.tableWishlist,
            maxAgeMinutes: 15,
          );
          if (isStale) {
            _refreshWishlistFromApi();
          }
          return;
        }
      }

      // Fetch from API
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

        // Save to SQLite
        await DatabaseService.saveWishlist([data]);
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to load wishlist';
        _wishlistProducts.clear();
        _favoriteIds.clear();
      }
    } catch (e) {
      // If API fails, try to load from cache
      try {
        final cachedWishlist = await DatabaseService.getWishlist();
        if (cachedWishlist.isNotEmpty) {
          _wishlistProducts.clear();
          _favoriteIds.clear();
          for (final productJson in cachedWishlist) {
            final product = ProductModel.fromJsonMap(productJson);
            _wishlistProducts.add(product);
            _favoriteIds.add(product.id);
          }
        }
      } catch (_) {}

      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _wishlistProducts.clear();
      _favoriteIds.clear();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshWishlistFromApi() async {
    try {
      final response = await ApiService.getMyWishlist();
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        await DatabaseService.saveWishlist([data]);
        // Update UI
        final productIds = data['productIds'] as List<dynamic>? ?? [];
        _wishlistProducts.clear();
        _favoriteIds.clear();
        for (final productJson in productIds) {
          final productMap = productJson as Map<String, dynamic>;
          final product = ProductModel.fromJsonMap(productMap);
          _wishlistProducts.add(product);
          _favoriteIds.add(product.id);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[FavoriteProvider] Background refresh failed: $e');
    }
  }

  Future<bool> removeFromWishlist(String productId) async {
    // Optimistic update - remove locally first
    try {
      await DatabaseService.optimisticRemoveFromWishlist(productId);

      // Update UI immediately
      _wishlistProducts.removeWhere((p) => p.id == productId);
      _favoriteIds.remove(productId);
      _errorMessage = null;
      notifyListeners();

      // Sync with API in background
      _syncRemoveFromWishlistWithApi(productId);
      return true;
    } catch (e) {
      debugPrint('[FavoriteProvider] Optimistic remove failed: $e');
      // If optimistic update fails, try API directly
      return await _removeFromWishlistViaApi(productId);
    }
  }

  Future<void> _syncRemoveFromWishlistWithApi(String productId) async {
    try {
      final response = await ApiService.removeFromWishlist(productId);

      if (response['success'] == true) {
        // Already updated locally, just verify
        debugPrint('[FavoriteProvider] Successfully synced remove with API');
      } else {
        // API failed, but keep optimistic update
        debugPrint('[FavoriteProvider] API sync failed, keeping optimistic update');
        // Optionally reload wishlist to sync with server
        await loadWishlist(forceRefresh: true);
      }
    } catch (e) {
      debugPrint('[FavoriteProvider] API sync error: $e');
      // Keep optimistic update even if API fails
    }
  }

  Future<bool> _removeFromWishlistViaApi(String productId) async {
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

  // Add to Wishlist - Optimistic update
  Future<bool> addToWishlist(String productId) async {
    if (_favoriteIds.contains(productId)) {
      return true; // Already in wishlist
    }

    // Get product data from cache or create minimal product
    Map<String, dynamic> productData;
    try {
      final cachedProduct = await DatabaseService.getProductById(productId);
      if (cachedProduct != null) {
        productData = cachedProduct;
      } else {
        // Create minimal product data
        productData = {'_id': productId, 'id': productId};
      }
    } catch (e) {
      productData = {'_id': productId, 'id': productId};
    }

    // Optimistic update - add locally first
    try {
      await DatabaseService.optimisticAddToWishlist(productData);

      // Update UI immediately
      if (!_favoriteIds.contains(productId)) {
        _favoriteIds.add(productId);
        try {
          final product = ProductModel.fromJsonMap(productData);
          _wishlistProducts.add(product);
        } catch (e) {
          debugPrint('[FavoriteProvider] Error parsing product: $e');
        }
      }
      _errorMessage = null;
      notifyListeners();

      // Sync with API in background
      _syncAddToWishlistWithApi(productId);
      return true;
    } catch (e) {
      debugPrint('[FavoriteProvider] Optimistic add failed: $e');
      // If optimistic update fails, try API directly
      return await _addToWishlistViaApi(productId);
    }
  }

  Future<void> _syncAddToWishlistWithApi(String productId) async {
    try {
      final response = await ApiService.addToWishlist(productId);

      if (response['success'] == true) {
        // Reload wishlist to get updated product data
        await loadWishlist(forceRefresh: true);
      } else {
        // API failed, but keep optimistic update
        debugPrint('[FavoriteProvider] API sync failed, keeping optimistic update');
      }
    } catch (e) {
      debugPrint('[FavoriteProvider] API sync error: $e');
      // Keep optimistic update even if API fails
    }
  }

  Future<bool> _addToWishlistViaApi(String productId) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.addToWishlist(productId);

      if (response['success'] == true) {
        await loadWishlist(forceRefresh: true);
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

  // Toggle favorite - Optimistic update
  Future<void> toggleFavorite(String productId) async {
    if (_favoriteIds.contains(productId)) {
      // Remove from wishlist - optimistic
      await removeFromWishlist(productId);
    } else {
      // Add to wishlist - optimistic
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
