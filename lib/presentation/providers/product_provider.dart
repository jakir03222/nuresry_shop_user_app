import 'package:flutter/foundation.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/carousel_model.dart';
import '../../../data/models/flash_sale_model.dart';
import '../../../data/services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<ProductModel> _products = [];
  List<ProductModel> _flashSaleProducts = [];
  List<CategoryModel> _categories = [];
  List<CarouselModel> _carousels = [];
  List<FlashSaleModel> _flashSales = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  List<ProductModel> get flashSaleProducts => _flashSaleProducts;
  List<CategoryModel> get categories => _categories;
  List<CarouselModel> get carousels => _carousels;
  List<FlashSaleModel> get flashSales => _flashSales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;


  Future<void> loadCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getCategories();

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> categoryData = response['data'] as List<dynamic>;
        _categories = categoryData
            .map((json) => CategoryModel.fromJsonMap(json as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to load categories';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  List<ProductModel> getProductsByCategory(String categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  Future<void> loadCarousels() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getCarousels();

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> carouselData = response['data'] as List<dynamic>;
        _carousels = carouselData
            .map((json) => CarouselModel.fromJsonMap(json as Map<String, dynamic>))
            .where((carousel) => carousel.isActive)
            .toList();
        
        // Sort by order
        _carousels.sort((a, b) => a.order.compareTo(b.order));
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFlashSales() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getActiveFlashSales();

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> flashSaleData = response['data'] as List<dynamic>;
        _flashSales = flashSaleData
            .map((json) => FlashSaleModel.fromJsonMap(json as Map<String, dynamic>))
            .where((flashSale) => flashSale.isActive && flashSale.isCurrentlyActive)
            .toList();
        
        // Sort by order
        _flashSales.sort((a, b) => a.order.compareTo(b.order));
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to load flash sales';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ProductModel> _flashSaleProductsList = [];
  List<ProductModel> get flashSaleProductsList => _flashSaleProductsList;

  Future<void> loadFlashSaleProducts(String saleId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getProductsByFlashSale(saleId);

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> productData = response['data'] as List<dynamic>;
        _flashSaleProductsList = productData
            .map((json) => ProductModel.fromJsonMap(json as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = response['message'] as String? ?? 'Failed to load flash sale products';
        _flashSaleProductsList = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _flashSaleProductsList = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
