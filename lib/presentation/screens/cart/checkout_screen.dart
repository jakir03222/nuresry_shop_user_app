import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/address_provider.dart';
import '../../widgets/common/custom_button.dart';
import 'package:intl/intl.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String _paymentMethod = 'Cash on Delivery';
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);
      addressProvider.loadAddresses();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    final cartItems = cartProvider.items;

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Get shipping address ID
    final defaultAddress = addressProvider.defaultAddress;
    String? shippingAddressId;

    if (defaultAddress != null) {
      shippingAddressId = defaultAddress.id;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a shipping address'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Get selected product IDs from cart
    final selectedProductIds = cartItems.map((item) => item.product.id).toList();

    // Map payment method
    String paymentMethod = 'cash';
    if (_paymentMethod == 'Mobile Banking') {
      paymentMethod = 'mobile_banking';
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final response = await ApiService.createOrder(
        shippingAddressId: shippingAddressId,
        selectedProductIds: selectedProductIds,
        paymentMethod: paymentMethod,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (context.mounted) {
        setState(() {
          _isPlacingOrder = false;
        });

        if (response['success'] == true) {
          // Clear cart after successful order
          await cartProvider.clearCart();

          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Order Placed!'),
                content: Text(
                  response['message'] as String? ?? 'Your order has been placed successfully.',
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
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
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _isPlacingOrder = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error placing order: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.items;
    final totalPrice = cartProvider.totalPrice;
    final priceFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          title: const Text('Checkout'),
        ),
        body: Center(
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
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      );
    }

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                    ...cartItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
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
                                  child: const Icon(Icons.image_not_supported_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${priceFormat.format(item.product.finalPrice)} x ${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              priceFormat.format(item.totalPrice),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          priceFormat.format(totalPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Delivery Charge',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          priceFormat.format(cartItems.fold(0.0, (sum, item) => sum + item.product.deliveryCharge)),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          priceFormat.format(totalPrice + cartItems.fold(0.0, (sum, item) => sum + item.product.deliveryCharge)),
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
              const SizedBox(height: 24),
              // Shipping Address Section
              Consumer<AddressProvider>(
                builder: (context, addressProvider, _) {
                  final defaultAddress = addressProvider.defaultAddress;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Shipping Address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              context.push('/shipping-address');
                            },
                            icon: const Icon(Icons.location_on, size: 18),
                            label: const Text('Manage Addresses'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (defaultAddress != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryBlue, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Default Address',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                defaultAddress.fullAddress,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                defaultAddress.phoneNumber,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderGrey),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'No address selected. Please add a shipping address.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Order Notes (Optional)',
                  hintText: 'Any special instructions?',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              // Payment Method
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              RadioListTile<String>(
                title: const Text('Cash on Delivery'),
                value: 'Cash on Delivery',
                groupValue: _paymentMethod,
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
                activeColor: AppColors.primaryBlue,
              ),
              RadioListTile<String>(
                title: const Text('Mobile Banking'),
                value: 'Mobile Banking',
                groupValue: _paymentMethod,
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
                activeColor: AppColors.primaryBlue,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Place Order',
                isLoading: _isPlacingOrder,
                onPressed: _isPlacingOrder ? null : _placeOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
