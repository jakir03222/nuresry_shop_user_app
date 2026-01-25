import 'package:flutter/foundation.dart';

import '../../../data/models/carousel_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/flash_sale_model.dart';
import '../../../data/models/product_model.dart';
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
            .map(
              (json) => CategoryModel.fromJsonMap(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        _errorMessage =
            response['message'] as String? ?? 'Failed to load categories';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  ProductModel? _currentProduct;
  ProductModel? get currentProduct => _currentProduct;

  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> loadProductById(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    _currentProduct = null;
    notifyListeners();

    try {
      final response = await ApiService.getProductById(productId);

      if (response['success'] == true && response['data'] != null) {
        final productData = response['data'] as Map<String, dynamic>;
        _currentProduct = ProductModel.fromJsonMap(productData);
      } else {
        _errorMessage =
            response['message'] as String? ?? 'Failed to load product';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _currentProduct = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ProductModel> _categoryProducts = [];
  List<ProductModel> get categoryProducts => _categoryProducts;

  // Pagination metadata
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalDocuments = 0;
  int _limitPerPage = 10;
  bool _hasMoreProducts = false;
  bool _isLoadingMore = false;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalDocuments => _totalDocuments;
  int get limitPerPage => _limitPerPage;
  bool get hasMoreProducts => _hasMoreProducts;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadProductsByCategory(
    String categoryId, {
    bool loadMore = false,
  }) async {
    if (loadMore && !_hasMoreProducts) {
      return; // No more products to load
    }

    final pageToLoad = loadMore ? _currentPage + 1 : 1;

    if (loadMore) {
      _isLoadingMore = true;
    } else {
      _isLoading = true;
      _errorMessage = null;
    }
    notifyListeners();

    try {
      final response = await ApiService.getProductsByCategory(
        categoryId,
        page: pageToLoad,
        limit: 10,
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> productData = response['data'] as List<dynamic>;
        final newProducts = productData
            .map(
              (json) => ProductModel.fromJsonMap(json as Map<String, dynamic>),
            )
            .toList();

        if (loadMore) {
          _categoryProducts.addAll(newProducts);
          _currentPage = pageToLoad;
        } else {
          _categoryProducts = newProducts;
          _currentPage = 1;
        }

        // Update pagination metadata
        if (response['meta'] != null) {
          final meta = response['meta'] as Map<String, dynamic>;
          _totalDocuments = meta['totalDocuments'] ?? 0;
          _totalPages = meta['totalPages'] ?? 1;
          _limitPerPage = meta['limitPerPage'] ?? 10;
          _hasMoreProducts = _currentPage < _totalPages;
        }
      } else {
        _errorMessage =
            response['message'] as String? ?? 'Failed to load products';
        if (!loadMore) {
          _categoryProducts = [];
        }
      }

      if (loadMore) {
        _isLoadingMore = false;
      } else {
        _isLoading = false;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      if (!loadMore) {
        _categoryProducts = [];
        _isLoading = false;
      } else {
        _isLoadingMore = false;
      }
      notifyListeners();
    }
  }

  void resetCategoryProducts() {
    _categoryProducts = [];
    _currentPage = 1;
    _totalPages = 1;
    _totalDocuments = 0;
    _hasMoreProducts = false;
    _isLoadingMore = false;
    notifyListeners();
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
            .map(
              (json) => CarouselModel.fromJsonMap(json as Map<String, dynamic>),
            )
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
            .map(
              (json) =>
                  FlashSaleModel.fromJsonMap(json as Map<String, dynamic>),
            )
            .where(
              (flashSale) => flashSale.isActive,
            ) // Server side already filtered for active but we keep it safe
            .toList();

        // Sort by order
        _flashSales.sort((a, b) => a.order.compareTo(b.order));

        // Use products from the first flash sale if available in the response
        if (_flashSales.isNotEmpty) {
          final firstSale = _flashSales.first;
          if (firstSale.products.isNotEmpty) {
            _flashSaleProducts = firstSale.products;
          } else {
            // Fallback: if products were not nested, fetch them separately
            final productsResponse = await ApiService.getProductsByFlashSale(
              firstSale.id,
            );
            if (productsResponse['success'] == true &&
                productsResponse['data'] != null) {
              final List<dynamic> productData =
                  productsResponse['data'] as List<dynamic>;
              _flashSaleProducts = productData
                  .map(
                    (json) =>
                        ProductModel.fromJsonMap(json as Map<String, dynamic>),
                  )
                  .toList();
            }
          }
        }
      } else {
        _errorMessage =
            response['message'] as String? ?? 'Failed to load flash sales';
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

  // Pagination metadata for flash sale products
  int _flashSaleCurrentPage = 1;
  int _flashSaleTotalPages = 1;
  int _flashSaleTotalDocuments = 0;
  bool _hasMoreFlashSaleProducts = false;
  bool _isLoadingMoreFlashSale = false;

  int get flashSaleCurrentPage => _flashSaleCurrentPage;
  int get flashSaleTotalPages => _flashSaleTotalPages;
  int get flashSaleTotalDocuments => _flashSaleTotalDocuments;
  bool get hasMoreFlashSaleProducts => _hasMoreFlashSaleProducts;
  bool get isLoadingMoreFlashSale => _isLoadingMoreFlashSale;

  Future<void> loadFlashSaleProducts(
    String saleId, {
    bool loadMore = false,
  }) async {
    if (loadMore && !_hasMoreFlashSaleProducts) {
      return; // No more products to load
    }

    final pageToLoad = loadMore ? _flashSaleCurrentPage + 1 : 1;

    if (loadMore) {
      _isLoadingMoreFlashSale = true;
    } else {
      _isLoading = true;
      _errorMessage = null;
    }
    notifyListeners();

    try {
      // First, try to find the flash sale in the loaded flash sales
      FlashSaleModel? flashSale;
      try {
        flashSale = _flashSales.firstWhere((fs) => fs.id == saleId);
      } catch (e) {
        // Flash sale not found in cache, fetch from API
        final saleResponse = await ApiService.getFlashSaleById(saleId);
        if (saleResponse['success'] == true && saleResponse['data'] != null) {
          flashSale = FlashSaleModel.fromJsonMap(
            saleResponse['data'] as Map<String, dynamic>,
          );
        }
      }

      if (flashSale != null && flashSale.products.isNotEmpty && !loadMore) {
        // Use products directly from the flash sale model (from nested productIds)
        _flashSaleProductsList = flashSale.products;
        _flashSaleCurrentPage = 1;
        _hasMoreFlashSaleProducts = false;
      } else {
        // Fallback: fetch products from the products API filtered by flash sale
        final response = await ApiService.getProductsByFlashSale(saleId);

        if (response['success'] == true && response['data'] != null) {
          final List<dynamic> productData = response['data'] as List<dynamic>;
          final newProducts = productData
              .map(
                (json) =>
                    ProductModel.fromJsonMap(json as Map<String, dynamic>),
              )
              .toList();

          if (loadMore) {
            _flashSaleProductsList.addAll(newProducts);
            _flashSaleCurrentPage = pageToLoad;
          } else {
            _flashSaleProductsList = newProducts;
            _flashSaleCurrentPage = 1;
          }

          // Update pagination metadata if available
          if (response['meta'] != null) {
            final meta = response['meta'] as Map<String, dynamic>;
            _flashSaleTotalDocuments = meta['totalDocuments'] ?? 0;
            _flashSaleTotalPages = meta['totalPages'] ?? 1;
            _hasMoreFlashSaleProducts =
                _flashSaleCurrentPage < _flashSaleTotalPages;
          } else {
            // No pagination info, assume no more products
            _hasMoreFlashSaleProducts = false;
          }
        } else {
          _errorMessage =
              response['message'] as String? ??
              'Failed to load flash sale products';
          if (!loadMore) {
            _flashSaleProductsList = [];
          }
        }
      }

      if (loadMore) {
        _isLoadingMoreFlashSale = false;
      } else {
        _isLoading = false;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      if (!loadMore) {
        _flashSaleProductsList = [];
        _isLoading = false;
      } else {
        _isLoadingMoreFlashSale = false;
      }
      notifyListeners();
    }
  }

  void resetFlashSaleProducts() {
    _flashSaleProductsList = [];
    _flashSaleCurrentPage = 1;
    _flashSaleTotalPages = 1;
    _flashSaleTotalDocuments = 0;
    _hasMoreFlashSaleProducts = false;
    _isLoadingMoreFlashSale = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
