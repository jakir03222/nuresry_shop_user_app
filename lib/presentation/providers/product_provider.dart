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
  List<ProductModel> _bestSellingProducts = [];
  List<CategoryModel> _categories = [];
  List<CarouselModel> _carousels = [];
  List<FlashSaleModel> _flashSales = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  List<ProductModel> get flashSaleProducts => _flashSaleProducts;
  List<ProductModel> get bestSellingProducts => _bestSellingProducts;
  bool _isLoadingBestSelling = false;
  bool get isLoadingBestSelling => _isLoadingBestSelling;
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
                .map((json) {
                  try {
                    return CategoryModel.fromJsonMap(json);
                  } catch (e) {
                    debugPrint(
                      '[ProductProvider] Error parsing cached category: $e',
                    );
                    return null;
                  }
                })
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
          debugPrint(
            '[ProductProvider] Error loading categories from cache: $e',
          );
          // Continue to API fetch if cache fails
        }
      }

      // Fetch from API
      final response = await ApiService.getCategories();

      if (response['success'] == true) {
        final categoryData = response['data'] as List<dynamic>? ?? [];
        _categories = categoryData
            .map(
              (json) => CategoryModel.fromJsonMap(json as Map<String, dynamic>),
            )
            .toList();

        // Save to SQLite or clear cache when API returns empty (deleted)
        if (categoryData.isEmpty) {
          await DatabaseService.clearCategories();
        } else {
          await DatabaseService.saveCategories(
            categoryData.map((e) => e as Map<String, dynamic>).toList(),
          );
        }
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
              .map((json) {
                try {
                  return CategoryModel.fromJsonMap(json);
                } catch (e) {
                  debugPrint(
                    '[ProductProvider] Error parsing cached category in fallback: $e',
                  );
                  return null;
                }
              })
              .whereType<CategoryModel>()
              .toList();
        }
      } catch (cacheError) {
        debugPrint(
          '[ProductProvider] Error loading categories from cache fallback: $cacheError',
        );
      }

      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshCategoriesFromApi() async {
    try {
      final response = await ApiService.getCategories();
      if (response['success'] == true) {
        final categoryData = response['data'] as List<dynamic>? ?? [];
        if (categoryData.isEmpty) {
          await DatabaseService.clearCategories();
        } else {
          await DatabaseService.saveCategories(
            categoryData.map((e) => e as Map<String, dynamic>).toList(),
          );
        }
        _categories = categoryData
            .map(
              (json) =>
                  CategoryModel.fromJsonMap(json as Map<String, dynamic>),
            )
            .toList();
        notifyListeners();
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

  FlashSaleModel? getFlashSaleById(String id) {
    try {
      return _flashSales.firstWhere((fs) => fs.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> loadProductById(
    String productId, {
    bool forceRefresh = false,
  }) async {
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
    debugPrint(
      '[ProductProvider.loadProductsByCategory] ========== START ==========',
    );
    debugPrint(
      '[ProductProvider.loadProductsByCategory] Category ID: $categoryId',
    );
    debugPrint('[ProductProvider.loadProductsByCategory] Load More: $loadMore');

    if (loadMore && !_hasMoreProducts) {
      debugPrint(
        '[ProductProvider.loadProductsByCategory] No more products to load',
      );
      return; // No more products to load
    }

    final pageToLoad = loadMore ? _currentPage + 1 : 1;
    debugPrint(
      '[ProductProvider.loadProductsByCategory] Page to load: $pageToLoad',
    );

    if (loadMore) {
      _isLoadingMore = true;
      debugPrint(
        '[ProductProvider.loadProductsByCategory] Setting isLoadingMore = true',
      );
    } else {
      _isLoading = true;
      _errorMessage = null;
      debugPrint(
        '[ProductProvider.loadProductsByCategory] Setting isLoading = true, cleared error',
      );
    }
    notifyListeners();

    try {
      debugPrint(
        '[ProductProvider.loadProductsByCategory] Calling API: getProductsByCategory',
      );
      debugPrint('[ProductProvider.loadProductsByCategory] Parameters:');
      debugPrint('  - categoryId: $categoryId');
      debugPrint('  - page: $pageToLoad');
      debugPrint('  - limit: 10');

      final response = await ApiService.getProductsByCategory(
        categoryId,
        page: pageToLoad,
        limit: 10,
      );

      debugPrint(
        '[ProductProvider.loadProductsByCategory] API Response received',
      );
      debugPrint(
        '[ProductProvider.loadProductsByCategory] Response success: ${response['success']}',
      );
      debugPrint(
        '[ProductProvider.loadProductsByCategory] Response message: ${response['message']}',
      );
      debugPrint(
        '[ProductProvider.loadProductsByCategory] Response has data: ${response['data'] != null}',
      );

      if (response['meta'] != null) {
        debugPrint(
          '[ProductProvider.loadProductsByCategory] Pagination meta: ${response['meta']}',
        );
      }

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> productData = response['data'] as List<dynamic>;
        debugPrint(
          '[ProductProvider.loadProductsByCategory] Products count: ${productData.length}',
        );

        int successCount = 0;
        int errorCount = 0;

        final newProducts = productData
            .map((json) {
              try {
                final product = ProductModel.fromJsonMap(
                  json as Map<String, dynamic>,
                );
                successCount++;
                debugPrint(
                  '[ProductProvider.loadProductsByCategory] ✓ Parsed product: ${product.id} - ${product.name}',
                );
                if (product.tags != null && product.tags!.isNotEmpty) {
                  debugPrint(
                    '[ProductProvider.loadProductsByCategory]   Tags: ${product.tags}',
                  );
                }
                return product;
              } catch (e, stackTrace) {
                errorCount++;
                debugPrint(
                  '[ProductProvider.loadProductsByCategory] ✗ Error parsing product: $e',
                );
                debugPrint(
                  '[ProductProvider.loadProductsByCategory] Product data: $json',
                );
                debugPrint(
                  '[ProductProvider.loadProductsByCategory] Stack trace: $stackTrace',
                );
                return null;
              }
            })
            .whereType<ProductModel>()
            .toList();

        debugPrint('[ProductProvider.loadProductsByCategory] Parsing summary:');
        debugPrint('  - Total products: ${productData.length}');
        debugPrint('  - Successfully parsed: $successCount');
        debugPrint('  - Failed to parse: $errorCount');
        debugPrint('  - Final products list: ${newProducts.length}');

        if (loadMore) {
          _categoryProducts.addAll(newProducts);
          _currentPage = pageToLoad;
          debugPrint(
            '[ProductProvider.loadProductsByCategory] Added ${newProducts.length} products (loadMore)',
          );
          debugPrint(
            '[ProductProvider.loadProductsByCategory] Total products now: ${_categoryProducts.length}',
          );
        } else {
          _categoryProducts = newProducts;
          _currentPage = 1;
          debugPrint(
            '[ProductProvider.loadProductsByCategory] Set ${newProducts.length} products (initial load)',
          );
        }

        // Update pagination metadata
        if (response['meta'] != null) {
          final meta = response['meta'] as Map<String, dynamic>;

          // Safely convert to int - handle both int and string types
          int safeToInt(dynamic value, [int defaultValue = 0]) {
            if (value == null) return defaultValue;
            if (value is int) return value;
            if (value is double) return value.toInt();
            if (value is String) {
              return int.tryParse(value) ?? defaultValue;
            }
            if (value is num) return value.toInt();
            return defaultValue;
          }

          _totalDocuments = safeToInt(meta['totalDocuments'], 0);
          _totalPages = safeToInt(meta['totalPages'], 1);
          _limitPerPage = safeToInt(meta['limitPerPage'], 10);
          _hasMoreProducts = _currentPage < _totalPages;

          debugPrint(
            '[ProductProvider.loadProductsByCategory] Pagination updated:',
          );
          debugPrint('  - Total documents: $_totalDocuments');
          debugPrint('  - Total pages: $_totalPages');
          debugPrint('  - Current page: $_currentPage');
          debugPrint('  - Has more: $_hasMoreProducts');
        } else {
          debugPrint(
            '[ProductProvider.loadProductsByCategory] No pagination meta in response',
          );
        }
      } else {
        _errorMessage =
            response['message'] as String? ?? 'Failed to load products';
        debugPrint(
          '[ProductProvider.loadProductsByCategory] ✗ API Error: $_errorMessage',
        );
        debugPrint(
          '[ProductProvider.loadProductsByCategory] Full response: $response',
        );

        if (!loadMore) {
          _categoryProducts = [];
          debugPrint(
            '[ProductProvider.loadProductsByCategory] Cleared products list',
          );
        }
      }

      if (loadMore) {
        _isLoadingMore = false;
        debugPrint(
          '[ProductProvider.loadProductsByCategory] Set isLoadingMore = false',
        );
      } else {
        _isLoading = false;
        debugPrint(
          '[ProductProvider.loadProductsByCategory] Set isLoading = false',
        );
      }
      notifyListeners();
      debugPrint(
        '[ProductProvider.loadProductsByCategory] ========== SUCCESS ==========',
      );
    } catch (e, stackTrace) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('[ProductProvider.loadProductsByCategory] ✗✗✗ EXCEPTION ✗✗✗');
      debugPrint('[ProductProvider.loadProductsByCategory] Error: $e');
      debugPrint(
        '[ProductProvider.loadProductsByCategory] Stack trace: $stackTrace',
      );
      debugPrint(
        '[ProductProvider.loadProductsByCategory] Error message: $_errorMessage',
      );

      if (!loadMore) {
        _categoryProducts = [];
        _isLoading = false;
        debugPrint(
          '[ProductProvider.loadProductsByCategory] Cleared products and set isLoading = false',
        );
      } else {
        _isLoadingMore = false;
        debugPrint(
          '[ProductProvider.loadProductsByCategory] Set isLoadingMore = false',
        );
      }
      notifyListeners();
      debugPrint(
        '[ProductProvider.loadProductsByCategory] ========== ERROR ==========',
      );
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

  // All products (GET /products)
  List<ProductModel> _allProducts = [];
  bool _isLoadingAllProducts = false;
  List<ProductModel> get allProducts => _allProducts;
  bool get isLoadingAllProducts => _isLoadingAllProducts;

  Future<void> loadAllProducts({int page = 1, int limit = 1000}) async {
    _isLoadingAllProducts = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getAllProducts(
        page: page,
        limit: limit,
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> productData = response['data'] as List<dynamic>;
        _allProducts = productData
            .map((json) {
              try {
                return ProductModel.fromJsonMap(json as Map<String, dynamic>);
              } catch (e) {
                debugPrint(
                  '[ProductProvider.loadAllProducts] Error parsing product: $e',
                );
                return null;
              }
            })
            .whereType<ProductModel>()
            .toList();

        if (response['meta'] != null) {
          final meta = response['meta'] as Map<String, dynamic>;
          int safeToInt(dynamic value, [int defaultValue = 0]) {
            if (value == null) return defaultValue;
            if (value is int) return value;
            if (value is double) return value.toInt();
            if (value is String) return int.tryParse(value) ?? defaultValue;
            if (value is num) return value.toInt();
            return defaultValue;
          }

          debugPrint(
            '[ProductProvider.loadAllProducts] meta: totalDocuments=${safeToInt(meta['totalDocuments'])}, totalPages=${safeToInt(meta['totalPages'])}',
          );
        }
      } else {
        _errorMessage =
            response['message'] as String? ?? 'Failed to load products';
        _allProducts = [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _allProducts = [];
      debugPrint('[ProductProvider.loadAllProducts] Error: $e');
    }

    _isLoadingAllProducts = false;
    notifyListeners();
  }

  void resetAllProducts() {
    _allProducts = [];
    _errorMessage = null;
    notifyListeners();
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
              .map((json) => CarouselModel.fromJsonMap(json))
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

      if (response['success'] == true) {
        final carouselData = response['data'] as List<dynamic>? ?? [];
        _carousels = carouselData
            .map(
              (json) => CarouselModel.fromJsonMap(json as Map<String, dynamic>),
            )
            .where((carousel) => carousel.isActive)
            .toList();

        // Sort by order
        _carousels.sort((a, b) => a.order.compareTo(b.order));

        // Save to SQLite or clear cache when API returns empty (deleted)
        if (carouselData.isEmpty) {
          await DatabaseService.clearCarousels();
        } else {
          await DatabaseService.saveCarousels(
            carouselData.map((e) => e as Map<String, dynamic>).toList(),
          );
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If API fails, try to load from cache
      try {
        final cachedCarousels = await DatabaseService.getCarousels();
        if (cachedCarousels.isNotEmpty) {
          _carousels = cachedCarousels
              .map((json) => CarouselModel.fromJsonMap(json))
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
      if (response['success'] == true) {
        final carouselData = response['data'] as List<dynamic>? ?? [];
        if (carouselData.isEmpty) {
          await DatabaseService.clearCarousels();
        } else {
          await DatabaseService.saveCarousels(
            carouselData.map((e) => e as Map<String, dynamic>).toList(),
          );
        }
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
              .map((json) => FlashSaleModel.fromJsonMap(json))
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
                  .map((json) => ProductModel.fromJsonMap(json))
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

      if (response['success'] == true) {
        final flashSaleData = response['data'] as List<dynamic>? ?? [];
        _flashSales = flashSaleData
            .map(
              (json) =>
                  FlashSaleModel.fromJsonMap(json as Map<String, dynamic>),
            )
            .where((flashSale) => flashSale.isActive)
            .toList();

        // Sort by order
        _flashSales.sort((a, b) => a.order.compareTo(b.order));

        // Save to SQLite or clear cache when API returns empty (deleted)
        if (flashSaleData.isEmpty) {
          await DatabaseService.clearFlashSales();
          _flashSaleProducts = [];
        } else {
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
              await DatabaseService.saveProducts(
                productData.map((e) => e as Map<String, dynamic>).toList(),
              );
            }
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
              .map((json) => FlashSaleModel.fromJsonMap(json))
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
      if (response['success'] == true) {
        final flashSaleData = response['data'] as List<dynamic>? ?? [];
        if (flashSaleData.isEmpty) {
          await DatabaseService.clearFlashSales();
          _flashSales = [];
          _flashSaleProducts = [];
        } else {
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
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ProductProvider] Background refresh failed: $e');
    }
  }

  /// Load best selling products for home screen (uses all products with limit).
  Future<void> loadBestSellingProducts() async {
    _isLoadingBestSelling = true;
    notifyListeners();
    try {
      final response = await ApiService.getAllProducts(page: 1, limit: 20);
      if (response['success'] == true && response['data'] != null) {
        final raw = response['data'];
        List<dynamic> productData = [];
        if (raw is List) {
          productData = raw;
        } else if (raw is Map) {
          if (raw['data'] is List) {
            productData = raw['data'] as List<dynamic>;
          } else if (raw['products'] is List) {
            productData = raw['products'] as List<dynamic>;
          } else if (raw['results'] is List) {
            productData = raw['results'] as List<dynamic>;
          }
        }
        _bestSellingProducts = productData
            .map((json) {
              try {
                return ProductModel.fromJsonMap(json as Map<String, dynamic>);
              } catch (_) {
                return null;
              }
            })
            .whereType<ProductModel>()
            .toList();
      }
    } catch (e) {
      debugPrint('[ProductProvider] loadBestSellingProducts failed: $e');
      _bestSellingProducts = [];
    }
    _isLoadingBestSelling = false;
    notifyListeners();
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
            // Safely convert to int - handle both int and string types
            int safeToInt(dynamic value, [int defaultValue = 0]) {
              if (value == null) return defaultValue;
              if (value is int) return value;
              if (value is double) return value.toInt();
              if (value is String) {
                return int.tryParse(value) ?? defaultValue;
              }
              if (value is num) return value.toInt();
              return defaultValue;
            }

            _flashSaleTotalDocuments = safeToInt(meta['totalDocuments'], 0);
            _flashSaleTotalPages = safeToInt(meta['totalPages'], 1);
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
    String? searchTerm,
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
        searchTerm: searchTerm,
        page: pageToLoad,
        limit: 10,
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> productData = response['data'] as List<dynamic>;
        final newProducts = productData
            .map((json) {
              try {
                return ProductModel.fromJsonMap(json as Map<String, dynamic>);
              } catch (e) {
                debugPrint(
                  '[ProductProvider.searchProductsByTags] Error parsing product: $e',
                );
                return null;
              }
            })
            .whereType<ProductModel>()
            .toList();

        // API handles filtering by searchTerm and tags, so use products directly
        if (loadMore) {
          _searchResults.addAll(newProducts);
          _searchCurrentPage = pageToLoad;
        } else {
          _searchResults = newProducts;
          _searchCurrentPage = 1;
        }

        // Update pagination metadata
        if (response['meta'] != null) {
          final meta = response['meta'] as Map<String, dynamic>;
          // Safely convert to int - handle both int and string types
          int safeToInt(dynamic value, [int defaultValue = 0]) {
            if (value == null) return defaultValue;
            if (value is int) return value;
            if (value is double) return value.toInt();
            if (value is String) {
              return int.tryParse(value) ?? defaultValue;
            }
            if (value is num) return value.toInt();
            return defaultValue;
          }

          _searchTotalDocuments = safeToInt(meta['totalDocuments'], 0);
          _searchTotalPages = safeToInt(meta['totalPages'], 1);
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
