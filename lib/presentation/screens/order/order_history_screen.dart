import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/payment_method_model.dart';
import '../../../data/services/api_service.dart';
import '../../providers/order_provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

/// 6-hour cancellation window: user can cancel only within 6 hours of order creation.
const _cancelWindow = Duration(hours: 6);

bool _canCancelOrder(OrderModel order) {
  if (order.orderStatus.toLowerCase() == 'cancelled') return false;
  return DateTime.now().difference(order.createdAt) <= _cancelWindow;
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.loadOrders();
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'shipped':
      case 'processing':
        return AppColors.primaryBlue;
      case 'cancelled':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(String status) {
    if (status == 'all' || status.isEmpty) return 'All';
    if (status.toLowerCase() == 'delivered') return 'Completed';
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, y • h:mm a');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Order History',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter tabs
          Consumer<OrderProvider>(
            builder: (context, orderProvider, _) {
              return Container(
                color: AppColors.backgroundWhite,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: OrderProvider.statusFilters.map((status) {
                      final isSelected = orderProvider.selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_statusLabel(status)),
                          selected: isSelected,
                          onSelected: (_) async {
                            await orderProvider.setFilter(status);
                          },
                          selectedColor: Color.lerp(
                            AppColors.primaryBlue,
                            AppColors.backgroundWhite,
                            0.85,
                          )!,
                          checkmarkColor: AppColors.primaryBlue,
                          labelStyle: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primaryBlue
                                : AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Order list
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, _) {
                if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  );
                }

                if (orderProvider.errorMessage != null &&
                    orderProvider.orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 80,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            orderProvider.errorMessage ?? 'Failed to load orders',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => orderProvider.loadOrders(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (orderProvider.orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No orders found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          orderProvider.selectedStatus == 'all'
                              ? 'Your orders will appear here'
                              : 'No ${_statusLabel(orderProvider.selectedStatus)} orders',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => orderProvider.loadOrders(),
                  color: AppColors.primaryBlue,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: orderProvider.orders.length +
                        (orderProvider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= orderProvider.orders.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryBlue,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }
                      final order = orderProvider.orders[index];
                      return _OrderCard(
                        order: order,
                        priceFormat: priceFormat,
                        dateFormat: dateFormat,
                        statusColor: _statusColor(order.orderStatus),
                        onCompletePayment: () => _showTransactionDialog(
                          context,
                          order,
                          orderProvider,
                        ),
                        onCancelOrder: () => _confirmAndCancelOrder(
                          context,
                          order,
                          orderProvider,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDialog(
    BuildContext context,
    OrderModel order,
    OrderProvider orderProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _TransactionDialog(
          order: order,
          orderProvider: orderProvider,
        );
      },
    );
  }

  Future<void> _confirmAndCancelOrder(
    BuildContext context,
    OrderModel order,
    OrderProvider orderProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: Text(
          'Are you sure you want to cancel order ${order.orderId}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    try {
      final response = await orderProvider.cancelOrder(order.orderId);
      if (!context.mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] as String? ?? 'Order cancelled',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] as String? ?? 'Cannot cancel order',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _TransactionDialog extends StatefulWidget {
  final OrderModel order;
  final OrderProvider orderProvider;

  const _TransactionDialog({
    required this.order,
    required this.orderProvider,
  });

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  final TextEditingController _transactionIdController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingPaymentMethods = false;
  List<PaymentMethodModel> _paymentMethods = [];
  PaymentMethodModel? _selectedPaymentMethod;
  String? _paymentMethodError;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _transactionIdController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    if (_hasLoaded) return;
    
    setState(() {
      _isLoadingPaymentMethods = true;
      _paymentMethodError = null;
      _hasLoaded = true;
    });

    try {
      final response = await ApiService.getPaymentMethods();

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        final methods = data
            .map((json) => PaymentMethodModel.fromJson(json as Map<String, dynamic>))
            .where((method) => method.isActive)
            .toList();

        // Try to auto-select payment method based on order's payment method
        PaymentMethodModel? autoSelected;
        final orderPaymentMethod = widget.order.paymentMethod.toLowerCase();
        for (var method in methods) {
          if (method.methodName.toLowerCase() == orderPaymentMethod) {
            autoSelected = method;
            break;
          }
        }

        if (mounted) {
          setState(() {
            _paymentMethods = methods;
            _selectedPaymentMethod = autoSelected ?? (methods.isNotEmpty ? methods.first : null);
            _isLoadingPaymentMethods = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _paymentMethodError = response['message'] as String? ?? 'Failed to load payment methods';
            _isLoadingPaymentMethods = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _paymentMethodError = e.toString().replaceAll('Exception: ', '');
          _isLoadingPaymentMethods = false;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_transactionIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter transaction ID'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await ApiService.createTransaction(
        orderId: widget.order.orderId,
        paymentMethodId: _selectedPaymentMethod!.id,
        userProvidedTransactionId: _transactionIdController.text.trim(),
      );

      if (response['success'] == true) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] as String? ?? 'Payment completed successfully',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          // Refresh orders
          widget.orderProvider.loadOrders();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] as String? ?? 'Failed to complete payment',
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Complete Payment',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ID: ${widget.order.orderId}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Payment Method: ${widget.order.paymentMethod.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ৳${widget.order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Payment Method Selection
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoadingPaymentMethods)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_paymentMethodError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Column(
                  children: [
                    Text(
                      _paymentMethodError!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadPaymentMethods,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_paymentMethods.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No payment methods available',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: DropdownButton<PaymentMethodModel>(
                  value: _selectedPaymentMethod,
                  isExpanded: true,
                  hint: const Text('Select payment method'),
                  items: _paymentMethods.map((method) {
                    return DropdownMenuItem<PaymentMethodModel>(
                      value: method,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            method.methodName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (method.accountNumber.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Account: ${method.accountNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                ),
              ),
            const SizedBox(height: 16),
            // Transaction ID
            const Text(
              'Transaction ID',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _transactionIdController,
              decoration: InputDecoration(
                hintText: 'Enter transaction ID (e.g., TXN123456789)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _selectedPaymentMethod == null
              ? null
              : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.textWhite,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textWhite,
                    ),
                  ),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderModel order;
  final NumberFormat priceFormat;
  final DateFormat dateFormat;
  final Color statusColor;
  final VoidCallback? onCompletePayment;
  final VoidCallback? onCancelOrder;

  const _OrderCard({
    required this.order,
    required this.priceFormat,
    required this.dateFormat,
    required this.statusColor,
    this.onCompletePayment,
    this.onCancelOrder,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  Timer? _cancelButtonHideTimer;

  @override
  void initState() {
    super.initState();
    if (_canCancelOrder(widget.order) && widget.onCancelOrder != null) {
      final deadline = widget.order.createdAt.add(_cancelWindow);
      final remaining = deadline.difference(DateTime.now());
      if (remaining > Duration.zero) {
        _cancelButtonHideTimer = Timer(remaining, () {
          if (mounted) setState(() {});
        });
      }
    }
  }

  @override
  void dispose() {
    _cancelButtonHideTimer?.cancel();
    super.dispose();
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final s = order.orderStatus;
    final status = s.isEmpty
        ? 'Pending'
        : s.toLowerCase() == 'delivered'
            ? 'Completed'
            : s[0].toUpperCase() + s.substring(1).toLowerCase();
    final canCancelWithin6Hours = _canCancelOrder(order);
    final showCancelButton = order.orderStatus.toLowerCase() != 'cancelled' && widget.onCancelOrder != null;

    final paymentStatusLabel = order.paymentStatus.isEmpty
        ? 'Pending'
        : order.paymentStatus[0].toUpperCase() +
            order.paymentStatus.substring(1).toLowerCase();
    final paymentMethodLabel = order.paymentMethod.isEmpty
        ? '-'
        : order.paymentMethod.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderId,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    widget.statusColor,
                    AppColors.backgroundWhite,
                    0.85,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Created & Updated
          _detailRow('Created', widget.dateFormat.format(order.createdAt)),
          _detailRow('Updated', widget.dateFormat.format(order.updatedAt)),
          const SizedBox(height: 10),
          // Payment info
          _sectionTitle('Payment'),
          _detailRow('Payment status', paymentStatusLabel),
          _detailRow('Payment method', paymentMethodLabel),
          const SizedBox(height: 10),
          // Shipping address
          _sectionTitle('Shipping address'),
          Text(
            order.shippingAddress.fullAddress,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (order.billingAddress != null) ...[
            const SizedBox(height: 8),
            _sectionTitle('Billing address'),
            Text(
              order.billingAddress!.fullAddress,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Items
          _sectionTitle('Items'),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${item.quantity} × ${widget.priceFormat.format(item.price)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.priceFormat.format(item.total),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 24),
          // Totals
          _sectionTitle('Summary'),
          _detailRow('Subtotal', widget.priceFormat.format(order.subtotal)),
          if (order.tax > 0) _detailRow('Tax', widget.priceFormat.format(order.tax)),
          if (order.shippingCost > 0)
            _detailRow('Shipping', widget.priceFormat.format(order.shippingCost)),
          if (order.discountAmount > 0)
            _detailRow('Discount', '-${widget.priceFormat.format(order.discountAmount)}'),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                widget.priceFormat.format(order.total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          // Complete Payment Button: only for non-COD (online) pending orders; COD is paid on delivery
          if (order.paymentStatus.toLowerCase() == 'pending' &&
              order.orderStatus.toLowerCase() != 'cancelled' &&
              order.paymentMethod.toLowerCase() != 'cod' &&
              widget.onCompletePayment != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onCompletePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Complete Payment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Cancel Order: enabled only within 6 hours of creation; disabled after 6 hours
          if (showCancelButton) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: canCancelWithin6Hours ? widget.onCancelOrder : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: canCancelWithin6Hours ? AppColors.error : AppColors.textSecondary,
                  side: BorderSide(
                    color: canCancelWithin6Hours ? AppColors.error : AppColors.borderGrey,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel_outlined, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Cancel Order',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (!canCancelWithin6Hours) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Cancel allowed within 6 hours of order',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
