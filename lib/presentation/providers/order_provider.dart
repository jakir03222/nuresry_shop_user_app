import 'package:flutter/foundation.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/api_service.dart';
import '../../../core/services/database_service.dart';

class OrderProvider with ChangeNotifier {
  final List<OrderModel> _orders = [];
  String _selectedStatus = 'all';
  bool _isLoading = false;
  String? _errorMessage;
  int _totalPages = 1;
  int _totalDocuments = 0;
  final int _limitPerPage = 10;

  static const List<String> statusFilters = [
    'all',
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  List<OrderModel> get orders => _orders;
  String get selectedStatus => _selectedStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalPages => _totalPages;
  int get totalDocuments => _totalDocuments;
  int get limitPerPage => _limitPerPage;

  Future<void> loadOrders({
    int page = 1,
    String? orderStatus,
    bool loadMore = false,
    bool forceRefresh = false,
  }) async {
    if (loadMore && _isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    if (!loadMore) {
      _orders.clear();
    }
    notifyListeners();

    try {
      final status = orderStatus ?? _selectedStatus;
      final filter = (status == 'all' || status.isEmpty) ? null : status;

      // Check SQLite cache first (unless force refresh or loading more)
      if (!forceRefresh && !loadMore && page == 1) {
        final cachedOrders = await DatabaseService.getOrders(status: filter);
        if (cachedOrders.isNotEmpty) {
          _orders.clear();
          _orders.addAll(
            cachedOrders.map((e) => OrderModel.fromJson(e)).toList(),
          );
          _isLoading = false;
          notifyListeners();

          // Refresh in background if stale
          final isStale = await DatabaseService.isDataStale(
            DatabaseService.tableOrders,
            maxAgeMinutes: 15,
          );
          if (isStale) {
            _refreshOrdersFromApi(page, filter);
          }
          return;
        }
      }

      // Fetch from API
      final response = await ApiService.getMyOrders(
        page: page,
        limit: _limitPerPage,
        orderStatus: filter,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final ordersList = data['orders'] as List<dynamic>? ?? [];
        final meta = data['meta'] as Map<String, dynamic>?;

        final newOrders = ordersList
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();

        if (loadMore) {
          _orders.addAll(newOrders);
        } else {
          _orders.clear();
          _orders.addAll(newOrders);
        }

        // Save to SQLite (only first page for cache)
        if (page == 1 && !loadMore) {
          await DatabaseService.saveOrders(
            ordersList.map((e) => e as Map<String, dynamic>).toList(),
          );
        }

        if (meta != null) {
          final td = meta['totalDocuments'];
          _totalDocuments = td is int ? td : (int.tryParse(td?.toString() ?? '0') ?? 0);
          final tp = meta['totalPages'];
          _totalPages = tp is int ? tp : (int.tryParse(tp?.toString() ?? '1') ?? 1);
        }
      } else {
        _errorMessage =
            response['message'] as String? ?? 'Failed to load orders';
        if (!loadMore) _orders.clear();
      }
    } catch (e) {
      // If API fails, try to load from cache
      if (!loadMore && page == 1) {
        try {
          final statusForCache = orderStatus ?? _selectedStatus;
          final filterForCache = (statusForCache == 'all' || statusForCache.isEmpty) ? null : statusForCache;
          final cachedOrders = await DatabaseService.getOrders(status: filterForCache);
          if (cachedOrders.isNotEmpty) {
            _orders.clear();
            _orders.addAll(
              cachedOrders.map((e) => OrderModel.fromJson(e)).toList(),
            );
          }
        } catch (_) {}
      }

      _errorMessage = e.toString().replaceAll('Exception: ', '');
      if (!loadMore) _orders.clear();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshOrdersFromApi(int page, String? filter) async {
    try {
      final response = await ApiService.getMyOrders(
        page: page,
        limit: _limitPerPage,
        orderStatus: filter,
      );
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final ordersList = data['orders'] as List<dynamic>? ?? [];
        await DatabaseService.saveOrders(
          ordersList.map((e) => e as Map<String, dynamic>).toList(),
        );
        // Update UI if currently viewing orders
        if (_orders.isEmpty || page == 1) {
          _orders.clear();
          _orders.addAll(
            ordersList
                .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
                .toList(),
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[OrderProvider] Background refresh failed: $e');
    }
  }

  /// Cancel order by orderId. Backend validates 6-hour rule.
  /// On success: updates in-memory list and SQLite cache so UI shows cancelled live (no pending); Cancelled tab shows correct list.
  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      final response = await ApiService.cancelOrder(orderId);
      if (response['success'] == true) {
        final now = DateTime.now();
        final index = _orders.indexWhere((o) => o.orderId == orderId);
        if (index >= 0) {
          _orders[index] = _orders[index].copyWith(
            orderStatus: 'cancelled',
            updatedAt: now,
          );
          notifyListeners();
        }
        await DatabaseService.updateOrderStatus(orderId, 'cancelled', updatedAt: now);
        return response;
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setFilter(String status) async {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    await loadOrders(page: 1, orderStatus: status == 'all' ? null : status);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
