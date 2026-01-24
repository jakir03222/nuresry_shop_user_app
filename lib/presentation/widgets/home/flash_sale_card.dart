import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../providers/cart_provider.dart';

class FlashSaleCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onFlashSaleTap;

  const FlashSaleCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFlashSaleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
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
                          child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textGrey),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          color: AppColors.flashSaleRed,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.flash_on, color: AppColors.textWhite, size: 12),
                            SizedBox(width: 2),
                            Text(
                              'SALE',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Row(
                        children: [
                          if (product.discountPrice != null)
                            Text(
                              '${product.unitPrice.toStringAsFixed(0)}${AppConstants.currencySymbol}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          if (product.discountPrice != null) const SizedBox(width: 8),
                          Text(
                            '${product.finalPrice.toStringAsFixed(0)}${AppConstants.currencySymbol}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.flashSaleRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppStrings.available} ${product.availableQuantity} ${AppStrings.pcs}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${AppStrings.deliveryCharge} ${product.deliveryCharge.toStringAsFixed(0)}${AppConstants.currencySymbol}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final cartProvider = Provider.of<CartProvider>(context, listen: false);
                        await cartProvider.addToCart(product, quantity: 1);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to cart'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          final cartProvider = Provider.of<CartProvider>(context, listen: false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(cartProvider.errorMessage ?? 'Failed to add'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Add to Cart'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final cartProvider = Provider.of<CartProvider>(context, listen: false);
                        await cartProvider.addToCart(product, quantity: 1);
                        if (context.mounted) {
                          context.push('/checkout');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          final cartProvider = Provider.of<CartProvider>(context, listen: false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(cartProvider.errorMessage ?? 'Failed to process'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.flashSaleRed,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

