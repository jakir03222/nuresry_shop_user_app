import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/custom_button.dart';
import 'package:intl/intl.dart';

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
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      // Load cart from cache first, then sync with API
      cartProvider.loadCart(useCache: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final cartItems = cartProvider.items;
        final totalPrice = cartProvider.totalPrice;

        if (cartProvider.errorMessage != null && cartItems.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: AppColors.primaryBlue,
              elevation: 0,
              title: const Text(
                'Cart',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    cartProvider.errorMessage ?? 'Failed to load cart',
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => cartProvider.loadCart(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (cartItems.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: AppColors.primaryBlue,
              elevation: 0,
              title: const Text(
                'Cart',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
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
              'Cart',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => cartProvider.loadCart(),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear Cart'),
                      content: const Text('Are you sure you want to clear all items?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            try {
                              await cartProvider.clearCart();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      cartProvider.errorMessage ?? 'Failed to clear cart',
                                    ),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentRed,
                          ),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: item.product.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: 80,
                                height: 80,
                                color: AppColors.borderGrey,
                                child: const Icon(Icons.image_outlined, color: AppColors.textSecondary),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                width: 80,
                                height: 80,
                                color: AppColors.borderGrey,
                                child: const Icon(Icons.image, color: AppColors.textSecondary),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  priceFormat.format(item.unitPrice),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: item.quantity > 1
                                          ? () async {
                                              try {
                                                await cartProvider.updateQuantity(
                                                  item.product.id,
                                                  item.quantity - 1,
                                                );
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        cartProvider.errorMessage ?? 'Failed to update quantity',
                                                      ),
                                                      backgroundColor: AppColors.error,
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () async {
                                        try {
                                          await cartProvider.updateQuantity(
                                            item.product.id,
                                            item.quantity + 1,
                                          );
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  cartProvider.errorMessage ?? 'Failed to update quantity',
                                                ),
                                                backgroundColor: AppColors.error,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: AppColors.accentRed,
                                onPressed: () async {
                                  try {
                                    await cartProvider.removeFromCart(item.product.id);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            cartProvider.errorMessage ?? 'Failed to remove item',
                                          ),
                                          backgroundColor: AppColors.error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              Text(
                                priceFormat.format(item.totalPrice),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (cartProvider.subtotal > 0 && cartProvider.subtotal != cartProvider.total)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                            Text(
                              priceFormat.format(cartProvider.subtotal),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          priceFormat.format(totalPrice),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Proceed to Checkout',
                      onPressed: () => context.push('/checkout'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
