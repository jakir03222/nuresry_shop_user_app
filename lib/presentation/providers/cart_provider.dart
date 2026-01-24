import 'package:flutter/foundation.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class CartItem {
  final String? itemId; // _id from API cart item
  final ProductModel product;
  int quantity;
  final double unitPrice; // price per unit from API

  CartItem({
    this.itemId,
    required this.product,
    this.quantity = 1,
    double? unitPrice,
  }) : unitPrice = unitPrice ?? product.finalPrice;

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        itemId: itemId,
        product: product,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice,
      );
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final bool _isLoading = false;
  String? _errorMessage;
  String? _cartId;
  double _subtotal = 0;
  double _total = 0;

  List<CartItem> get items => _items;
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get cartId => _cartId;
  double get subtotal => _subtotal;
  double get total => _total;
  
  double get totalPrice => _total > 0 ? _total : _items.fold(0, (sum, item) => sum + item.totalPrice);

  // Load cart from cache (SharedPreferences)
  Future<void> loadCartFromCache() async {
    try {
      final cachedData = await StorageService.getCartData();
      if (cachedData != null) {
        _parseCartData(cachedData);
        notifyListeners();
      }
    } catch (e) {
      // Ignore cache errors, will load from API
    }
  }

  // Parse cart data from API response or cache
  void _parseCartData(Map<String, dynamic> data) {
    _cartId = data['_id'] as String?;
    _subtotal = (data['subtotal'] ?? 0).toDouble();
    _total = (data['total'] ?? 0).toDouble();
    _items.clear();

    final itemsList = data['items'] as List<dynamic>? ?? [];
    for (final raw in itemsList) {
      final map = raw as Map<String, dynamic>;
      final productIdData = map['productId'];
      if (productIdData == null) continue;
      final productMap = productIdData is Map<String, dynamic>
          ? productIdData
          : <String, dynamic>{'_id': productIdData};
      final product = ProductModel.fromJsonMap(productMap);
      final qty = (map['quantity'] ?? 1) as int;
      final price = (map['price'] ?? product.finalPrice).toDouble();
      _items.add(CartItem(
        itemId: map['_id'] as String?,
        product: product,
        quantity: qty,
        unitPrice: price,
      ));
    }
  }

  void _recomputeTotals() {
    _subtotal = _items.fold(0, (sum, i) => sum + i.totalPrice);
    _total = _subtotal;
  }

  // Save cart data to cache
  Future<void> _saveCartToCache(Map<String, dynamic> data) async {
    try {
      await StorageService.saveCartData(data);
    } catch (e) {
      // Ignore cache save errors
    }
  }

  Future<void> loadCart({bool useCache = true}) async {
    // Load from cache only when empty (avoid overwriting optimistic updates)
    if (useCache && _items.isEmpty) {
      await loadCartFromCache();
    }

    // Sync with API in background - never show loading for cart fetch
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getCart();

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        _parseCartData(data);
        await _saveCartToCache(data);
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to load cart';
        if (!useCache) {
          _items.clear();
          _subtotal = 0;
          _total = 0;
        }
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      if (!useCache) {
        _items.clear();
        _subtotal = 0;
        _total = 0;
      }
      notifyListeners();
    }
  }

  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    final quantityToAdd = existingIndex >= 0 ? _items[existingIndex].quantity + quantity : quantity;

    // Optimistic update: show in cart instantly
    if (existingIndex >= 0) {
      _items[existingIndex].quantity = quantityToAdd;
    } else {
      _items.add(CartItem(product: product, quantity: quantityToAdd));
    }
    _recomputeTotals();
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.addToCart(
        productId: product.id,
        quantity: quantityToAdd,
      );

      if (response['success'] == true) {
        // Keep optimistic state; sync when user opens cart/home
      } else {
        _revertAddToCart(product.id, quantity, existingIndex >= 0);
        _errorMessage = response['message'] as String? ?? 'Failed to add to cart';
        notifyListeners();
        throw Exception(_errorMessage);
      }
    } catch (e) {
      _revertAddToCart(product.id, quantity, existingIndex >= 0);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  void _revertAddToCart(String productId, int addedQuantity, bool existed) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index < 0) return;
    if (existed) {
      _items[index].quantity -= addedQuantity;
      if (_items[index].quantity <= 0) _items.removeAt(index);
    } else {
      _items.removeAt(index);
    }
    _recomputeTotals();
  }

  Future<void> removeFromCart(String productId) async {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index < 0) return;

    final removed = _items[index];
    _items.removeAt(index);
    _recomputeTotals();
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.removeCartItem(productId);

      if (response['success'] == true) {
        // Keep optimistic state; sync when user opens cart/home
      } else {
        _items.insert(index, removed);
        _recomputeTotals();
        _errorMessage = response['message'] as String? ?? 'Failed to remove item';
        notifyListeners();
        throw Exception(_errorMessage);
      }
    } catch (e) {
      _items.insert(index, removed);
      _recomputeTotals();
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(productId);
      return;
    }

    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index < 0) return;

    final item = _items[index];
    final oldQuantity = item.quantity;

    // Optimistic update: show new quantity instantly
    item.quantity = quantity;
    _recomputeTotals();
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.updateCartItemQuantity(
        productId: productId,
        quantity: quantity,
      );

      if (response['success'] == true) {
        // Keep optimistic state; sync when user opens cart/home
      } else {
        item.quantity = oldQuantity;
        _recomputeTotals();
        _errorMessage = response['message'] as String? ?? 'Failed to update quantity';
        notifyListeners();
        throw Exception(_errorMessage);
      }
    } catch (e) {
      item.quantity = oldQuantity;
      _recomputeTotals();
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearCart() async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.clearCart();

      if (response['success'] == true) {
        _items.clear();
        _subtotal = 0;
        _total = 0;
        _cartId = null;
        await StorageService.clearCartData();
        notifyListeners();
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to clear cart';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getQuantity(String productId) {
    try {
      final item = _items.firstWhere((item) => item.product.id == productId);
      return item.quantity;
    } catch (_) {
      return 0;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
