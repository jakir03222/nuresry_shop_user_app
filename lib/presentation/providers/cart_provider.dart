import 'package:flutter/foundation.dart';
import '../../data/models/cart_model.dart';
import '../../data/models/product_model.dart';
import '../../data/services/api_service.dart';
import '../../core/services/database_service.dart';

class CartProvider with ChangeNotifier {
  CartModel? _cart;
  bool _isLoading = false;
  String? _errorMessage;

  CartModel? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalItems => _cart?.totalItems ?? 0;
  int get totalQuantity => _cart?.totalItems ?? 0;
  double get totalPrice => _cart?.totalPrice ?? 0;
  List<CartItemModel> get items => _cart?.items ?? [];

  Future<void> fetchCart({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check SQLite cache first (unless force refresh)
      if (!forceRefresh) {
        final cachedCart = await DatabaseService.getCart();
        if (cachedCart != null) {
          _cart = CartModel.fromJson(cachedCart);
          _isLoading = false;
          notifyListeners();

          // Refresh in background if stale (cart should refresh more frequently)
          final isStale = await DatabaseService.isDataStale(
            DatabaseService.tableCart,
            maxAgeMinutes: 5,
          );
          if (isStale) {
            _refreshCartFromApi();
          }
          return;
        }
      }

      // Fetch from API
      final response = await ApiService.getCart();

      if (response['success'] == true) {
        if (response['data'] != null) {
          _cart = CartModel.fromJson(response['data'] as Map<String, dynamic>);
          // Save to SQLite
          await DatabaseService.saveCart(response['data'] as Map<String, dynamic>);
        } else {
          // If success is true but data is null, it means the cart is empty
          _cart = CartModel(items: [], totalPrice: 0, totalItems: 0);
          // Clear cache
          await DatabaseService.clearCart();
        }
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to load cart';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If API fails, try to load from cache
      try {
        final cachedCart = await DatabaseService.getCart();
        if (cachedCart != null) {
          _cart = CartModel.fromJson(cachedCart);
        }
      } catch (_) {}

      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshCartFromApi() async {
    try {
      final response = await ApiService.getCart();
      if (response['success'] == true) {
        if (response['data'] != null) {
          await DatabaseService.saveCart(response['data'] as Map<String, dynamic>);
          // Update UI
          _cart = CartModel.fromJson(response['data'] as Map<String, dynamic>);
          notifyListeners();
        } else {
          await DatabaseService.clearCart();
          _cart = CartModel(items: [], totalPrice: 0, totalItems: 0);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[CartProvider] Background refresh failed: $e');
    }
  }

  Future<void> loadCart({bool useCache = false}) async {
    if (useCache) {
      await loadCartFromCache();
    }
    await fetchCart(forceRefresh: !useCache);
  }

  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    // Optimistic update - update locally first for instant UI
    try {
      // Convert product to map for database
      final productData = {
        '_id': product.id,
        'name': product.name,
        'price': product.unitPrice,
        'unitPrice': product.unitPrice,
        'discountPrice': product.discountPrice,
        'image': product.imageUrl,
        'imageUrl': product.imageUrl,
        'description': product.description,
        'categoryId': product.categoryId,
        'availableQuantity': product.availableQuantity,
        'isAvailable': product.isAvailable,
        'sku': product.sku,
        'brand': product.brand,
      };

      // Optimistically add to local database
      final updatedCartData = await DatabaseService.optimisticAddToCart(
        productData,
        quantity,
      );

      // Update UI immediately
      _cart = CartModel.fromJson(updatedCartData);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      // Sync with API in background
      _syncAddToCartWithApi(product.id, quantity);
    } catch (e) {
      debugPrint('[CartProvider] Optimistic add failed: $e');
      // If optimistic update fails, try API directly
      await _addToCartViaApi(product, quantity);
    }
  }

  Future<void> _syncAddToCartWithApi(String productId, int quantity) async {
    try {
      final response = await ApiService.addToCart(
        productId: productId,
        quantity: quantity,
      );

      if (response['success'] == true && response['data'] != null) {
        // Update with server response
        await DatabaseService.saveCart(response['data'] as Map<String, dynamic>);
        _cart = CartModel.fromJson(response['data'] as Map<String, dynamic>);
        notifyListeners();
      } else {
        // API failed, but keep optimistic update
        debugPrint('[CartProvider] API sync failed, keeping optimistic update');
      }
    } catch (e) {
      debugPrint('[CartProvider] API sync error: $e');
      // Keep optimistic update even if API fails
    }
  }

  Future<void> _addToCartViaApi(ProductModel product, int quantity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.addToCart(
        productId: product.id,
        quantity: quantity,
      );

      if (response['success'] == true) {
        await fetchCart(forceRefresh: true);
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to add to cart';
        _isLoading = false;
        notifyListeners();
        throw Exception(_errorMessage);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    // Optimistic update - update locally first for instant UI
    try {
      // Optimistically update in local database
      final updatedCartData = await DatabaseService.optimisticUpdateCartQuantity(
        productId,
        quantity,
      );

      // Update UI immediately
      _cart = CartModel.fromJson(updatedCartData);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      // Sync with API in background
      _syncUpdateQuantityWithApi(productId, quantity);
    } catch (e) {
      debugPrint('[CartProvider] Optimistic update quantity failed: $e');
      // If optimistic update fails, try API directly
      await _updateQuantityViaApi(productId, quantity);
    }
  }

  Future<void> _syncUpdateQuantityWithApi(String productId, int quantity) async {
    try {
      final response = await ApiService.updateCartItemQuantity(
        productId: productId,
        quantity: quantity,
      );

      if (response['success'] == true) {
        // Fetch updated cart from API
        await fetchCart(forceRefresh: true);
      } else {
        // API failed, but keep optimistic update
        debugPrint('[CartProvider] API sync failed, keeping optimistic update');
      }
    } catch (e) {
      debugPrint('[CartProvider] API sync error: $e');
      // Keep optimistic update even if API fails
    }
  }

  Future<void> _updateQuantityViaApi(String productId, int quantity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.updateCartItemQuantity(
        productId: productId,
        quantity: quantity,
      );

      if (response['success'] == true) {
        await fetchCart(forceRefresh: true);
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to update quantity';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String productId) async {
    // Optimistic update - remove locally first for instant UI
    try {
      // Optimistically remove from local database
      final updatedCartData = await DatabaseService.optimisticRemoveFromCart(productId);

      // Update UI immediately
      if (updatedCartData != null) {
        _cart = CartModel.fromJson(updatedCartData);
      } else {
        _cart = null;
      }
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      // Sync with API in background
      _syncRemoveFromCartWithApi(productId);
    } catch (e) {
      debugPrint('[CartProvider] Optimistic remove failed: $e');
      // If optimistic update fails, try API directly
      await _removeFromCartViaApi(productId);
    }
  }

  Future<void> _syncRemoveFromCartWithApi(String productId) async {
    try {
      final response = await ApiService.removeCartItem(productId);

      if (response['success'] == true) {
        // Fetch updated cart from API
        await fetchCart(forceRefresh: true);
      } else {
        // API failed, but keep optimistic update
        debugPrint('[CartProvider] API sync failed, keeping optimistic update');
      }
    } catch (e) {
      debugPrint('[CartProvider] API sync error: $e');
      // Keep optimistic update even if API fails
    }
  }

  Future<void> _removeFromCartViaApi(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.removeCartItem(productId);

      if (response['success'] == true) {
        await fetchCart(forceRefresh: true);
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to remove item';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.clearCart();

      if (response['success'] == true) {
        // Clear cart data immediately for live update
        _cart = null;
        _errorMessage = null;
        _isLoading = false;
        // Clear from SQLite cache
        await DatabaseService.clearCart();
        // Notify listeners immediately for live UI update
        notifyListeners();
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to clear cart';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      // Even if API fails, clear cart locally for immediate UI update
      _cart = null;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  bool isInCart(String productId) {
    if (_cart == null) return false;
    return _cart!.items.any((item) => item.product.id == productId);
  }

  Future<void> loadCartFromCache() async {
    try {
      final cachedCart = await DatabaseService.getCart();
      if (cachedCart != null) {
        _cart = CartModel.fromJson(cachedCart);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[CartProvider] Failed to load cart from cache: $e');
    }
  }

  // Clear cart data (for logout)
  void clearCartData() {
    _cart = null;
    _errorMessage = null;
    _isLoading = false;
    // Clear from SQLite cache
    DatabaseService.clearCart();
    notifyListeners();
  }
}
