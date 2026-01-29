import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/database_service.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/payment_method_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/address_provider.dart';
import '../../../data/models/address_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  AddressModel? _selectedAddress;
  PaymentMethodModel? _selectedPaymentMethod;
  /// When Online Banking is selected, methods from API (GET /payment-methods).
  List<PaymentMethodModel> _onlineBankingMethods = [];
  PaymentMethodModel? _selectedOnlineBankingMethod;
  bool _isLoadingOnlineBanking = false;
  String? _onlineBankingError;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  List<PaymentMethodModel> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      // Load addresses first, then set default address selected
      await addressProvider.loadAddresses();
      if (mounted && addressProvider.defaultAddress != null) {
        setState(() {
          _selectedAddress = addressProvider.defaultAddress;
        });
      }
      if (!mounted) return;
      cartProvider.fetchCart();
      // Cash on Delivery and Online Banking on same screen (checkbox options)
      setState(() {
        _paymentMethods = _checkoutPaymentOptions;
        if (_paymentMethods.isNotEmpty) {
          _selectedPaymentMethod = _paymentMethods.first;
        }
      });
    });
  }

  /// Checkout screen: Cash on Delivery and Online Banking (same screen checkbox/radio options).
  static List<PaymentMethodModel> get _checkoutPaymentOptions => [
        PaymentMethodModel(
          id: 'cod',
          methodName: 'Cash on Delivery',
          accountNumber: '',
          isActive: true,
          displayOrder: 0,
        ),
        PaymentMethodModel(
          id: 'bkash',
          methodName: 'Online Banking',
          accountNumber: '',
          isActive: true,
          displayOrder: 1,
        ),
      ];


  /// Load payment methods from API (GET {{baseUrl}}/payment-methods) when Online Banking is selected.
  Future<void> _loadOnlineBankingMethods() async {
    setState(() {
      _isLoadingOnlineBanking = true;
      _onlineBankingError = null;
      _selectedOnlineBankingMethod = null;
    });
    try {
      final response = await ApiService.getPaymentMethods();
      if (!mounted) return;
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        final methods = data
            .map((json) => PaymentMethodModel.fromJson(json as Map<String, dynamic>))
            .where((m) => m.isActive)
            .toList();
        methods.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        setState(() {
          _onlineBankingMethods = methods;
          _isLoadingOnlineBanking = false;
          _onlineBankingError = null;
          if (methods.isNotEmpty) _selectedOnlineBankingMethod = methods.first;
        });
      } else {
        setState(() {
          _onlineBankingMethods = [];
          _isLoadingOnlineBanking = false;
          _onlineBankingError = response['message'] as String? ?? 'Failed to load payment methods';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _onlineBankingMethods = [];
        _isLoadingOnlineBanking = false;
        _onlineBankingError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// True if payment is Cash on Delivery (no transaction ID needed).
  bool _isCashOnDelivery(PaymentMethodModel method) {
    final name = method.methodName.toLowerCase();
    return name == 'cod' ||
        name == 'cash on delivery' ||
        name.contains('cash on delivery') ||
        name.contains('cod');
  }

  /// Shows dialog to enter transaction ID for online payment (bkash, nagad, rocket).
  /// Returns transaction ID string or null if cancelled / empty.
  Future<String?> _showTransactionIdDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Enter ${_selectedOnlineBankingMethod?.methodName ?? _selectedPaymentMethod?.methodName ?? 'Payment'} Transaction ID'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'e.g. TXN123456789',
              labelText: 'Transaction ID',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final id = controller.text.trim();
                if (id.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter transaction ID'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop(id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePlaceOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a shipping address'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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

    // When Online Banking selected, user must pick one method from API (bKash etc.)
    if (!_isCashOnDelivery(_selectedPaymentMethod!) &&
        (_selectedOnlineBankingMethod == null || _onlineBankingMethods.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method (e.g. bKash) or wait for list to load'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // For online payment (bkash, nagad, rocket): get transaction ID from user
    String? transactionId;
    if (!_isCashOnDelivery(_selectedPaymentMethod!)) {
      transactionId = await _showTransactionIdDialog(context);
      if (transactionId == null || transactionId.trim().isEmpty) {
        return; // User cancelled or left empty
      }
      if (!mounted) return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get selected product IDs from cart
      final selectedProductIds = cartProvider.items.map((item) => item.product.id).toList();
      final paymentMethodKey = _isCashOnDelivery(_selectedPaymentMethod!)
          ? 'cod'
          : _selectedOnlineBankingMethod!.methodName.toLowerCase();

      final response = await ApiService.createOrder(
        shippingAddressId: _selectedAddress!.id,
        selectedProductIds: selectedProductIds,
        paymentMethod: paymentMethodKey,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        transactionId: transactionId,
        discountCode: null,
      );

      if (response['success'] == true) {
        if (context.mounted) {
          // Delete cart items after order: call DELETE {{baseUrl}}/carts/:productId for each product
          try {
            for (final productId in selectedProductIds) {
              try {
                await ApiService.removeCartItem(productId);
              } catch (_) {
                // Continue removing other items
              }
            }
            cartProvider.clearCartData();
            await DatabaseService.clearCart();
          } catch (e) {
            debugPrint('Cart delete failed, clearing locally: $e');
            cartProvider.clearCartData();
          }
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] as String? ?? 'Order placed successfully',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Navigate to order history
          // Cart is already cleared and UI will show empty state automatically
          context.go('/order-history');
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] as String? ?? 'Failed to place order',
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() {
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (context.mounted) {
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
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer2<CartProvider, AddressProvider>(
        builder: (context, cartProvider, addressProvider, child) {
          if (cartProvider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Browse Products'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Cart Items
                      ...cartProvider.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              // Product Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: item.product.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 60,
                                    height: 60,
                                    color: AppColors.borderGrey,
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: 60,
                                    height: 60,
                                    color: AppColors.borderGrey,
                                    child: const Icon(
                                      Icons.image,
                                      size: 30,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Qty: ${item.quantity} × ${priceFormat.format(item.price)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Item Total
                              Text(
                                priceFormat.format(item.total),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 24),
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            priceFormat.format(cartProvider.totalPrice),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Shipping Address
                Container(
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
                          const Text(
                            'Shipping Address',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => context.push('/shipping-address'),
                            icon: const Icon(
                              Icons.add,
                              size: 18,
                              color: AppColors.primaryBlue,
                            ),
                            label: const Text(
                              'Add New',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 14,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (addressProvider.isLoading && addressProvider.addresses.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (addressProvider.addresses.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.location_off,
                                size: 40,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'No address found',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => context.push('/shipping-address'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                ),
                                child: const Text('Add Address'),
                              ),
                            ],
                          ),
                        )
                      else
                        ...[
                          // Auto-select default address when list is shown and none selected
                          Builder(
                            builder: (_) {
                              if (_selectedAddress == null &&
                                  addressProvider.addresses.isNotEmpty) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted && _selectedAddress == null) {
                                    setState(() {
                                      _selectedAddress =
                                          addressProvider.defaultAddress;
                                    });
                                  }
                                });
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          ...addressProvider.addresses.map((address) {
                          final isSelected = _selectedAddress?.id == address.id;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedAddress = address;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryBlueLight.withOpacity(0.1)
                                    : AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : AppColors.borderGrey,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Radio<AddressModel>(
                                    value: address,
                                    groupValue: _selectedAddress,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedAddress = value;
                                      });
                                    },
                                    activeColor: AppColors.primaryBlue,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (address.isDefault)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.success.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Default',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          address.fullAddress,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Phone: ${address.phoneNumber}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Payment Method
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Cash on Delivery and Online Banking (checkbox/radio options on same screen)
                      ..._paymentMethods.map((method) {
                          final isSelected = _selectedPaymentMethod?.id == method.id;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPaymentMethod = method;
                                if (method.id == 'bkash') {
                                  _loadOnlineBankingMethods();
                                } else {
                                  _selectedOnlineBankingMethod = null;
                                  _onlineBankingMethods = [];
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryBlueLight.withOpacity(0.1)
                                    : AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : AppColors.borderGrey,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Radio<PaymentMethodModel>(
                                        value: method,
                                        groupValue: _selectedPaymentMethod,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedPaymentMethod = value;
                                          });
                                        },
                                        activeColor: AppColors.primaryBlue,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              method.methodName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            if (method.description != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                method.description!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (method.accountNumber.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundWhite,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.account_balance_wallet,
                                            size: 16,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Account: ${method.accountNumber}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (method.instructions != null && method.instructions!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlueLight.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: AppColors.primaryBlue,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              method.instructions!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      // When Online Banking selected: show API payment methods (GET /payment-methods)
                      if (_selectedPaymentMethod?.id == 'bkash') ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Select payment method',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingOnlineBanking)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
                          )
                        else if (_onlineBankingError != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _onlineBankingError!,
                                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _loadOnlineBankingMethods,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        else if (_onlineBankingMethods.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'No payment methods available',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          )
                        else
                          ..._onlineBankingMethods.map((method) {
                            final isSelected = _selectedOnlineBankingMethod?.id == method.id;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedOnlineBankingMethod = method;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryBlueLight.withOpacity(0.2)
                                      : AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryBlue : AppColors.borderGrey,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Radio<PaymentMethodModel>(
                                      value: method,
                                      groupValue: _selectedOnlineBankingMethod,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedOnlineBankingMethod = value;
                                        });
                                      },
                                      activeColor: AppColors.primaryBlue,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            method.methodName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          if (method.accountNumber.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '${method.accountNumber}${method.accountName != null ? " • ${method.accountName}" : ""}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                          if (method.description != null && method.description!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              method.description!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Order Notes
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Notes (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add any special instructions...',
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
                const SizedBox(height: 24),
                // Place Order Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handlePlaceOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                        : const Text(
                            'Place Order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
