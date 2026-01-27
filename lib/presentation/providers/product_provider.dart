import 'package:flutter/foundation.dart';

import '../../../data/models/carousel_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/flash_sale_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import '../../../core/services/database_service.dart';

class ProductProvider with ChangeNotifier {
  final List<ProductModel> _products = [];
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

  Future<void> loadCategories({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check SQLite cache first (unless force refresh)
      if (!forceRefresh) {
        try {
          final cachedCategories = await DatabaseService.getCategories();
          if (cachedCategories.isNotEmpty) {
            _categories = cachedCategories
                .map(
                  (json) {
                    try {
                      return CategoryModel.fromJsonMap(json);
                    } catch (e) {
                      debugPrint('[ProductProvider] Error parsing cached category: $e');
                      return null;
                    }
                  },
                )
                .whereType<CategoryModel>()
                .toList();
            
            if (_categories.isNotEmpty) {
              _isLoading = false;
              notifyListeners();

              // Check if data is stale, refresh in background
              final isStale = await DatabaseService.isDataStale(
                DatabaseService.tableCategories,
                maxAgeMinutes: 30,
              );
              if (isStale) {
                // Refresh in background without blocking UI
                _refreshCategoriesFromApi();
              }
              return;
            }
          }
        } catch (e) {
          debugPrint('[ProductProvider] Error loading categories from cache: $e');
          // Continue to API fetch if cache fails
        }
      }

      // Fetch from API
      final response = await ApiService.getCategories();

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> categoryData = response['data'] as List<dynamic>;
        _categories = categoryData
            .map(
              (json) => CategoryModel.fromJsonMap(json as Map<String, dynamic>),
            )
            .toList();

        // Save to SQLite
        await DatabaseService.saveCategories(categoryData
            .map((e) => e as Map<String, dynamic>)
            .toList());
      } else {
        _errorMessage =
            response['message'] as String? ?? 'Failed to load categories';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If API fails, try to load from cache
      try {
        final cachedCategories = await DatabaseService.getCategories();
        if (cachedCategories.isNotEmpty) {
          _categories = cachedCategories
              .map(
                (json) {
                  try {
                    return CategoryModel.fromJsonMap(json);
                  } catch (e) {
                    debugPrint('[ProductProvider] Error parsing cached category in fallback: $e');
                    return null;
                  }
                },
              )
              .whereType<CategoryModel>()
              .toList();
        }
      } catch (cacheError) {
        debugPrint('[ProductProvider] Error loading categories from cache fallback: $cacheError');
      }

      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshCategoriesFromApi() async {
    try {
      final response = await ApiService.getCategories();
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> categoryData = response['data'] as List<dynamic>;
        await DatabaseService.saveCategories(
          categoryData.map((e) => e as Map<String, dynamic>).toList(),
        );
        // Update UI if currently viewing categories
        if (_categories.isNotEmpty) {
          _categories = categoryData
              .map(
                (json) => CategoryModel.fromJsonMap(json as Map<String, dynamic>),
              )
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[ProductProvider] Background refresh failed: $e');
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

  Future<void> loadProductById(String productId, {bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentProduct = null;
    notifyListeners();

    try {
      // Check SQLite cache first (unless force refresh)
      if (!forceRefresh) {
        final cachedProduct = await DatabaseService.getProductById(productId);
        if (cachedProduct != null) {
          _currentProduct = ProductModel.fromJsonMap(cachedProduct);
          _isLoading = false;
          notifyListeners();

          // Refresh in background if stale
          final isStale = await DatabaseService.isDataStale(
            DatabaseService.tableProducts,
            maxAgeMinutes: 30,
          );
          if (isStale) {
            _refreshProductFromApi(productId);
          }
          return;
        }
      }

      // Fetch from API
      final response = await ApiService.getProductById(productId);

      if (response['success'] == true && response['data'] != null) {
        final productData = response['data'] as Map<String, dynamic>;
        _currentProduct = ProductModel.fromJsonMap(productData);

        // Save to SQLite
        await DatabaseService.saveProducts([productData]);
      } else {
        _errorMessage =
            response['message'] as String? ?? 'Failed to load product';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If API fails, try to load from cache
      try {
        final cachedProduct = await DatabaseService.getProductById(productId);
        if (cachedProduct != null) {
          _currentProduct = ProductModel.fromJsonMap(cachedProduct);
        }
      } catch (_) {}

      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _currentProduct = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshProductFromApi(String productId) async {
    try {
      final response = await ApiService.getProductById(productId);
      if (response['success'] == true && response['data'] != null) {
        final productData = response['data'] as Map<String, dynamic>;
        await DatabaseService.saveProducts([productData]);
        // Update UI if currently viewing this product
        if (_currentProduct?.id == productId) {
          _currentProduct = ProductModel.fromJsonMap(productData);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[ProductProvider] Background refresh failed: $e');
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

  Future<void> loadCarousels({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check SQLite cache first (unless force refresh)
      if (!forceRefresh) {
        final cachedCarousels = await DatabaseService.getCarousels();
        if (cachedCarousels.isNotEmpty) {
          _carousels = cachedCarousels
              .map(
                (json) => CarouselModel.fromJsonMap(json),
              )
              .where((carousel) => carousel.isActive)
              .toList();
          _carousels.sort((a, b) => a.order.compareTo(b.order));
          _isLoading = false;
          notifyListeners();

          // Refresh in background if stale
          final isStale = await DatabaseService.isDataStale(
            DatabaseService.tableCarousels,
            maxAgeMinutes: 30,
          );
          if (isStale) {
            _refreshCarouselsFromApi();
          }
          return;
        }
      }

      // Fetch from API
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

        // Save to SQLite
        await DatabaseService.saveCarousels(
          carouselData.map((e) => e as Map<String, dynamic>).toList(),
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If API fails, try to load from cache
      try {
        final cachedCarousels = await DatabaseService.getCarousels();
        if (cachedCarousels.isNotEmpty) {
          _carousels = cachedCarousels
              .map(
                (json) => CarouselModel.fromJsonMap(json),
              )
              .where((carousel) => carousel.isActive)
              .toList();
          _carousels.sort((a, b) => a.order.compareTo(b.order));
        }
      } catch (_) {}

      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshCarouselsFromApi() async {
    try {
      final response = await ApiService.getCarousels();
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> carouselData = response['data'] as List<dynamic>;
        await DatabaseService.saveCarousels(
          carouselData.map((e) => e as Map<String, dynamic>).toList(),
        );
        // Update UI
        _carousels = carouselData
            .map(
              (json) => CarouselModel.fromJsonMap(json as Map<String, dynamic>),
            )
            .where((carousel) => carousel.isActive)
            .toList();
        _carousels.sort((a, b) => a.order.compareTo(b.order));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ProductProvider] Background refresh failed: $e');
    }
  }

  Future<void> loadFlashSales({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check SQLite cache first (unless force refresh)
      if (!forceRefresh) {
        final cachedFlashSales = await DatabaseService.getFlashSales();
        if (cachedFlashSales.isNotEmpty) {
          _flashSales = cachedFlashSales
              .map(
                (json) =>
                    FlashSaleModel.fromJsonMap(json),
              )
              .where((flashSale) => flashSale.isActive)
              .toList();
          _flashSales.sort((a, b) => a.order.compareTo(b.order));

          // Load products for first flash sale from cache
          if (_flashSales.isNotEmpty) {
            final firstSale = _flashSales.first;
            final cachedProducts = await DatabaseService.getProducts(
              flashSaleId: firstSale.id,
            );
            if (cachedProducts.isNotEmpty) {
              _flashSaleProducts = cachedProducts
                  .map(
                    (json) =>
                        ProductModel.fromJsonMap(json),
                  )
                  .toList();
            }
          }

          _isLoading = false;
          notifyListeners();

          // Refresh in background if stale
          final isStale = await DatabaseService.isDataStale(
            DatabaseService.tableFlashSales,
            maxAgeMinutes: 30,
          );
          if (isStale) {
            _refreshFlashSalesFromApi();
          }
          return;
        }
      }

      // Fetch from API
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
            )
            .toList();

        // Sort by order
        _flashSales.sort((a, b) => a.order.compareTo(b.order));

        // Save to SQLite
        await DatabaseService.saveFlashSales(
          flashSaleData.map((e) => e as Map<String, dynamic>).toList(),
        );

        // Use products from the first flash sale if available in the response
        if (_flashSales.isNotEmpty) {
          final firstSale = _flashSales.first;
          if (firstSale.products.isNotEmpty) {
            _flashSaleProducts = firstSale.products;
            // Save products to cache - convert ProductModel to Map for database
            final productsToSave = <Map<String, dynamic>>[];
            for (var product in firstSale.products) {
              productsToSave.add({
                '_id': product.id,
                'name': product.name,
                'price': product.unitPrice,
                'image': product.imageUrl,
                'flashSaleId': firstSale.id,
                'description': product.description,
                'unitPrice': product.unitPrice,
                'discountPrice': product.discountPrice,
                'availableQuantity': product.availableQuantity,
                'categoryId': product.categoryId,
                'isAvailable': product.isAvailable,
                'isFeatured': product.isFeatured,
                'ratingAverage': product.rating,
                'ratingCount': product.reviewCount,
                'sku': product.sku,
                'brand': product.brand,
                'tags': product.tags,
                'images': product.images,
              });
            }
            await DatabaseService.saveProducts(productsToSave);
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
              // Save products to cache
              await DatabaseService.saveProducts(productData
                  .map((e) => e as Map<String, dynamic>)
                  .toList());
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
      // If API fails, try to load from cache
      try {
        final cachedFlashSales = await DatabaseService.getFlashSales();
        if (cachedFlashSales.isNotEmpty) {
          _flashSales = cachedFlashSales
              .map(
                (json) =>
                    FlashSaleModel.fromJsonMap(json),
              )
              .where((flashSale) => flashSale.isActive)
              .toList();
          _flashSales.sort((a, b) => a.order.compareTo(b.order));
        }
      } catch (_) {}

      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshFlashSalesFromApi() async {
    try {
      final response = await ApiService.getActiveFlashSales();
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> flashSaleData = response['data'] as List<dynamic>;
        await DatabaseService.saveFlashSales(
          flashSaleData.map((e) => e as Map<String, dynamic>).toList(),
        );
        // Update UI
        _flashSales = flashSaleData
            .map(
              (json) =>
                  FlashSaleModel.fromJsonMap(json as Map<String, dynamic>),
            )
            .where((flashSale) => flashSale.isActive)
            .toList();
        _flashSales.sort((a, b) => a.order.compareTo(b.order));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ProductProvider] Background refresh failed: $e');
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

  // Search Products by Tags
  List<ProductModel> _searchResults = [];
  List<ProductModel> get searchResults => _searchResults;

  // Pagination metadata for search
  int _searchCurrentPage = 1;
  int _searchTotalPages = 1;
  int _searchTotalDocuments = 0;
  bool _hasMoreSearchResults = false;
  bool _isLoadingMoreSearch = false;

  int get searchCurrentPage => _searchCurrentPage;
  int get searchTotalPages => _searchTotalPages;
  int get searchTotalDocuments => _searchTotalDocuments;
  bool get hasMoreSearchResults => _hasMoreSearchResults;
  bool get isLoadingMoreSearch => _isLoadingMoreSearch;

  Future<void> searchProductsByTags({
    String? tags,
    bool loadMore = false,
  }) async {
    if (loadMore && !_hasMoreSearchResults) {
      return; // No more results to load
    }

    final pageToLoad = loadMore ? _searchCurrentPage + 1 : 1;

    if (loadMore) {
      _isLoadingMoreSearch = true;
    } else {
      _isLoading = true;
      _errorMessage = null;
    }
    notifyListeners();

    try {
      final response = await ApiService.searchProductsByTags(
        tags: tags,
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

        // Filter products by tags if tags are provided
        List<ProductModel> filteredProducts = newProducts;
        if (tags != null && tags.isNotEmpty) {
          final searchTags = tags.toLowerCase().split(',').map((t) => t.trim()).toList();
          filteredProducts = newProducts.where((product) {
            if (product.tags == null || product.tags!.isEmpty) return false;
            final productTags = product.tags!.map((t) => t.toLowerCase()).toList();
            return searchTags.any((searchTag) => 
              productTags.any((productTag) => productTag.contains(searchTag))
            );
          }).toList();
        }

        if (loadMore) {
          _searchResults.addAll(filteredProducts);
          _searchCurrentPage = pageToLoad;
        } else {
          _searchResults = filteredProducts;
          _searchCurrentPage = 1;
        }

        // Update pagination metadata
        if (response['meta'] != null) {
          final meta = response['meta'] as Map<String, dynamic>;
          _searchTotalDocuments = meta['totalDocuments'] ?? 0;
          _searchTotalPages = meta['totalPages'] ?? 1;
          _hasMoreSearchResults = _searchCurrentPage < _searchTotalPages;
        } else {
          _hasMoreSearchResults = false;
        }
      } else {
        _errorMessage =
            response['message'] as String? ?? 'Failed to search products';
        if (!loadMore) {
          _searchResults = [];
        }
      }

      if (loadMore) {
        _isLoadingMoreSearch = false;
      } else {
        _isLoading = false;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      if (!loadMore) {
        _searchResults = [];
        _isLoading = false;
      } else {
        _isLoadingMoreSearch = false;
      }
      notifyListeners();
    }
  }

  void resetSearchResults() {
    _searchResults = [];
    _searchCurrentPage = 1;
    _searchTotalPages = 1;
    _searchTotalDocuments = 0;
    _hasMoreSearchResults = false;
    _isLoadingMoreSearch = false;
    notifyListeners();
  }
}
