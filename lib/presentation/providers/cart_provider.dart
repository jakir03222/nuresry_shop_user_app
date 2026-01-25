import 'package:flutter/foundation.dart';
import '../../data/models/cart_model.dart';
import '../../data/models/product_model.dart';
import '../../data/services/api_service.dart';

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

  Future<void> fetchCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getCart();

      if (response['success'] == true) {
        if (response['data'] != null) {
          _cart = CartModel.fromJson(response['data'] as Map<String, dynamic>);
        } else {
          // If success is true but data is null, it means the cart is empty
          _cart = CartModel(items: [], totalPrice: 0, totalItems: 0);
        }
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to load cart';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCart({bool useCache = false}) async {
    if (useCache) {
      await loadCartFromCache();
    }
    await fetchCart();
  }

  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.addToCart(
        productId: product.id,
        quantity: quantity,
      );

      if (response['success'] == true) {
        // Refresh cart after adding item
        await fetchCart();
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.updateCartItemQuantity(
        productId: productId,
        quantity: quantity,
      );

      if (response['success'] == true) {
        await fetchCart();
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.removeCartItem(productId);

      if (response['success'] == true) {
        await fetchCart();
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
    // Implementation for local storage can be added here
  }

  // Clear cart data (for logout)
  void clearCartData() {
    _cart = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
