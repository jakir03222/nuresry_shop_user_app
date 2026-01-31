import 'package:flutter/foundation.dart';
import '../../data/services/api_service.dart';
import 'database_service.dart';
import 'connectivity_service.dart';
import 'storage_service.dart';

/// Sync Service: Handles online/offline data synchronization
/// - Fetches data from API when online
/// - Falls back to SQLite cache when offline
/// - Syncs data in background when connection is restored
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ConnectivityService _connectivity = ConnectivityService();
  
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Initialize sync service
  Future<void> initialize() async {
    _connectivity.initialize();
    
    // Listen for connectivity changes
    _connectivity.connectivityStream.listen((isOnline) {
      if (isOnline) {
        debugPrint('[SyncService] Back online - starting background sync');
        syncAllData();
      }
    });
    
    debugPrint('[SyncService] Initialized');
  }

  /// Dispose resources
  void dispose() {
    _connectivity.dispose();
  }

  /// Check if online
  bool get isOnline => _connectivity.isOnline;

  /// Sync all data from API to SQLite (background sync when online)
  Future<void> syncAllData() async {
    if (_isSyncing) {
      debugPrint('[SyncService] Already syncing, skipping...');
      return;
    }

    final hasAuth = await StorageService.getAccessToken() != null;
    if (!hasAuth) {
      debugPrint('[SyncService] No auth token, skipping sync');
      return;
    }

    final isOnline = await _connectivity.checkConnectivity();
    if (!isOnline) {
      debugPrint('[SyncService] Offline, skipping sync');
      return;
    }

    _isSyncing = true;
    debugPrint('[SyncService] ========== STARTING FULL SYNC ==========');

    try {
      // Sync in parallel for speed
      await Future.wait([
        _syncCategories(),
        _syncProducts(),
        _syncCarousels(),
        _syncFlashSales(),
        _syncCart(),
        _syncWishlist(),
        _syncAddresses(),
        _syncOrders(),
        _syncCoupons(),
        _syncUserProfile(),
      ]);
      
      debugPrint('[SyncService] ========== FULL SYNC COMPLETE ==========');
    } catch (e) {
      debugPrint('[SyncService] Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ========== Individual Sync Methods ==========

  Future<void> _syncCategories() async {
    try {
      final response = await ApiService.getCategories();
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        await DatabaseService.saveCategories(
          data.map((e) => e as Map<String, dynamic>).toList(),
        );
        debugPrint('[SyncService] Synced ${data.length} categories');
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to sync categories: $e');
    }
  }

  Future<void> _syncProducts() async {
    try {
      final response = await ApiService.getAllProducts(page: 1, limit: 1000);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        await DatabaseService.saveProducts(
          data.map((e) => e as Map<String, dynamic>).toList(),
        );
        debugPrint('[SyncService] Synced ${data.length} products');
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to sync products: $e');
    }
  }

  Future<void> _syncCarousels() async {
    try {
      final response = await ApiService.getCarousels();
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        await DatabaseService.saveCarousels(
          data.map((e) => e as Map<String, dynamic>).toList(),
        );
        debugPrint('[SyncService] Synced ${data.length} carousels');
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to sync carousels: $e');
    }
  }

  Future<void> _syncFlashSales() async {
    try {
      final response = await ApiService.getActiveFlashSales();
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        await DatabaseService.saveFlashSales(
          data.map((e) => e as Map<String, dynamic>).toList(),
        );
        debugPrint('[SyncService] Synced ${data.length} flash sales');
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to sync flash sales: $e');
    }
  }

  Future<void> _syncCart() async {
    try {
      final response = await ApiService.getCart();
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        await DatabaseService.saveCart(data);
        debugPrint('[SyncService] Synced cart');
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to sync cart: $e');
    }
  }

  Future<void> _syncWishlist() async {
    try {
      final response = await ApiService.getMyWishlist();
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        await DatabaseService.saveWishlist(
          data.map((e) => e as Map<String, dynamic>).toList(),
        );
        debugPrint('[SyncService] Synced wishlist');
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to sync wishlist: $e');
    }
  }

  Future<void> _syncAddresses() async {
    try {
      final response = await ApiService.getAddresses();
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        await DatabaseService.saveAddresses(
          data.map((e) => e as Map<String, dynamic>).toList(),
        );
        debugPrint('[SyncService] Synced ${data.length} addresses');
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to sync addresses: $e');
    }
  }

  Future<void> _syncOrders() async {
    try {
      final response = await ApiService.getMyOrders(page: 1, limit: 100);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        await DatabaseService.saveOrders(
          data.map((e) => e as Map<String, dynamic>).toList(),
        );
        debugPrint('[SyncService] Synced ${data.length} orders');
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to sync orders: $e');
    }
  }

  Future<void> _syncCoupons() async {
    try {
      final response = await ApiService.getCoupons(page: 1, limit: 100);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        await DatabaseService.saveCoupons(
          data.map((e) => e as Map<String, dynamic>).toList(),
        );
        debugPrint('[SyncService] Synced ${data.length} coupons');
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to sync coupons: $e');
    }
  }

  Future<void> _syncUserProfile() async {
    try {
      final response = await ApiService.getProfile();
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        await DatabaseService.saveUserProfile(data);
        debugPrint('[SyncService] Synced user profile');
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to sync user profile: $e');
    }
  }

  // ========== Data Fetch Methods (Cache-first with API fallback) ==========

  /// Get categories: cache-first, then API if stale/missing
  Future<List<Map<String, dynamic>>> getCategories({bool forceRefresh = false}) async {
    // Try cache first (unless force refresh)
    if (!forceRefresh) {
      final cached = await DatabaseService.getCategories();
      if (cached.isNotEmpty) {
        // Check if stale, refresh in background
        final isStale = await DatabaseService.isDataStale(
          DatabaseService.tableCategories,
          maxAgeMinutes: 30,
        );
        if (isStale && _connectivity.isOnline) {
          _syncCategories(); // Background refresh
        }
        return cached;
      }
    }

    // Fetch from API if online
    if (_connectivity.isOnline) {
      try {
        final response = await ApiService.getCategories();
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as List<dynamic>;
          final list = data.map((e) => e as Map<String, dynamic>).toList();
          await DatabaseService.saveCategories(list);
          return list;
        }
      } catch (e) {
        debugPrint('[SyncService] getCategories API error: $e');
      }
    }

    // Fallback to cache
    return await DatabaseService.getCategories();
  }

  /// Get products: cache-first, then API if stale/missing
  Future<List<Map<String, dynamic>>> getProducts({
    String? categoryId,
    String? flashSaleId,
    bool forceRefresh = false,
  }) async {
    // Try cache first
    if (!forceRefresh) {
      final cached = await DatabaseService.getProducts(
        categoryId: categoryId,
        flashSaleId: flashSaleId,
      );
      if (cached.isNotEmpty) {
        final isStale = await DatabaseService.isDataStale(
          DatabaseService.tableProducts,
          maxAgeMinutes: 15,
        );
        if (isStale && _connectivity.isOnline) {
          _syncProducts();
        }
        return cached;
      }
    }

    // Fetch from API
    if (_connectivity.isOnline) {
      try {
        final response = await ApiService.getAllProducts(page: 1, limit: 1000);
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as List<dynamic>;
          final list = data.map((e) => e as Map<String, dynamic>).toList();
          await DatabaseService.saveProducts(list);
          
          // Filter if needed
          if (categoryId != null || flashSaleId != null) {
            return await DatabaseService.getProducts(
              categoryId: categoryId,
              flashSaleId: flashSaleId,
            );
          }
          return list;
        }
      } catch (e) {
        debugPrint('[SyncService] getProducts API error: $e');
      }
    }

    return await DatabaseService.getProducts(
      categoryId: categoryId,
      flashSaleId: flashSaleId,
    );
  }

  /// Get cart: cache-first, then API
  Future<Map<String, dynamic>?> getCart({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await DatabaseService.getCart();
      if (cached != null) {
        if (_connectivity.isOnline) {
          _syncCart();
        }
        return cached;
      }
    }

    if (_connectivity.isOnline) {
      try {
        final response = await ApiService.getCart();
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          await DatabaseService.saveCart(data);
          return data;
        }
      } catch (e) {
        debugPrint('[SyncService] getCart API error: $e');
      }
    }

    return await DatabaseService.getCart();
  }

  /// Get orders: cache-first, then API
  Future<List<Map<String, dynamic>>> getOrders({
    String? status,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await DatabaseService.getOrders(status: status);
      if (cached.isNotEmpty) {
        if (_connectivity.isOnline) {
          _syncOrders();
        }
        return cached;
      }
    }

    if (_connectivity.isOnline) {
      try {
        final response = await ApiService.getMyOrders(
          page: 1,
          limit: 100,
          orderStatus: status,
        );
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as List<dynamic>;
          final list = data.map((e) => e as Map<String, dynamic>).toList();
          await DatabaseService.saveOrders(list);
          return list;
        }
      } catch (e) {
        debugPrint('[SyncService] getOrders API error: $e');
      }
    }

    return await DatabaseService.getOrders(status: status);
  }
}
