import 'package:flutter/foundation.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/api_service.dart';

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
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      if (!loadMore) _orders.clear();
    }

    _isLoading = false;
    notifyListeners();
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
