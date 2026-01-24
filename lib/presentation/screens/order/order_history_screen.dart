import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/order_model.dart';
import '../../providers/order_provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final NumberFormat priceFormat;
  final DateFormat dateFormat;
  final Color statusColor;

  const _OrderCard({
    required this.order,
    required this.priceFormat,
    required this.dateFormat,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final s = order.orderStatus;
    final status = s.isEmpty
        ? 'Pending'
        : s[0].toUpperCase() + s.substring(1).toLowerCase();

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
                    statusColor,
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
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateFormat.format(order.createdAt),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            order.shippingAddress.fullAddress,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} × ${item.quantity}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    priceFormat.format(item.total),
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
          const Divider(height: 20),
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
                priceFormat.format(order.total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
