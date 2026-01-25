import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.fetchCart();
    });
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
          'My Cart',
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
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading && cartProvider.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            );
          }

          if (cartProvider.errorMessage != null && cartProvider.items.isEmpty) {
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
                  Text(
                    cartProvider.errorMessage ?? 'Failed to load cart',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => cartProvider.fetchCart(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (cartProvider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add items to your cart',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'Browse Products',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Cart Items List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => cartProvider.fetchCart(),
                  color: AppColors.primaryBlue,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartProvider.items.length,
                    itemBuilder: (context, index) {
                      final item = cartProvider.items[index];
                      return _buildCartItem(context, item, cartProvider, priceFormat);
                    },
                  ),
                ),
              ),
              // Cart Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          priceFormat.format(cartProvider.totalPrice),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Total Items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Items',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${cartProvider.totalItems} items',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Checkout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: cartProvider.isLoading
                            ? null
                            : () {
                                context.push('/checkout');
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: cartProvider.isLoading
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
                                'Proceed to Checkout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
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
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    cartItem,
    CartProvider cartProvider,
    NumberFormat priceFormat,
  ) {
    final product = cartItem.product;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderGrey,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: CachedNetworkImage(
              imageUrl: product.imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 100,
                height: 100,
                color: AppColors.borderGrey,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 100,
                height: 100,
                color: AppColors.borderGrey,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  size: 40,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          // Product Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Price per unit
                  Text(
                    '${priceFormat.format(cartItem.price)} per unit',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Quantity Controls and Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quantity Controls
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.borderGrey,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: cartItem.quantity > 1
                                  ? () {
                                      cartProvider.updateQuantity(
                                        product.id,
                                        cartItem.quantity - 1,
                                      );
                                    }
                                  : null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '${cartItem.quantity}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: cartItem.quantity < product.availableQuantity
                                  ? () {
                                      cartProvider.updateQuantity(
                                        product.id,
                                        cartItem.quantity + 1,
                                      );
                                    }
                                  : null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Item Total
                      Text(
                        priceFormat.format(cartItem.total),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Remove Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _showRemoveDialog(
                        context,
                        product.name,
                        product.id,
                        cartProvider,
                      ),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.accentRed,
                      ),
                      label: const Text(
                        'Remove',
                        style: TextStyle(
                          color: AppColors.accentRed,
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(
    BuildContext context,
    String productName,
    String productId,
    CartProvider cartProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: Text('Remove $productName from cart?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                cartProvider.removeFromCart(productId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$productName removed from cart'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}
