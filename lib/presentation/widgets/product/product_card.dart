import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/cart_provider.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 110,
                        color: AppColors.borderGrey,
                        child: const Icon(
                          Icons.image,
                          size: 50,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
                // Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<FavoriteProvider>(
                    builder: (context, favoriteProvider, child) {
                      final isFavorite = favoriteProvider.isFavorite(product.id);
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? AppColors.accentRed : AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            favoriteProvider.toggleFavorite(product.id);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      );
                    },
                  ),
                ),
                // Discount Badge
                if (product.discountPrice != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Flash Sale Badge
                if (product.isFlashSale)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.flashSaleRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FLASH',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.description,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Price Section
                    Row(
                      children: [
                        if (product.discountPrice != null)
                          Text(
                            priceFormat.format(product.unitPrice),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        if (product.discountPrice != null)
                          const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            priceFormat.format(product.finalPrice),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Stock and Rating
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 11,
                          color: product.availableQuantity > 0
                              ? AppColors.success
                              : AppColors.accentRed,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${product.availableQuantity} pcs',
                            style: TextStyle(
                              fontSize: 10,
                              color: product.availableQuantity > 0
                                  ? AppColors.success
                                  : AppColors.accentRed,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.rating != null) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.star,
                            size: 11,
                            color: AppColors.accentYellow,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    // Add to Cart Button
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, child) {
                        final isInCart = cartProvider.isInCart(product.id);
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: product.availableQuantity > 0
                                ? () {
                                    if (onAddToCart != null) {
                                      onAddToCart!();
                                    } else {
                                      cartProvider.addToCart(product);
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInCart
                                  ? AppColors.success
                                  : AppColors.primaryBlue,
                              foregroundColor: AppColors.textWhite,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              isInCart ? 'In Cart' : 'Add to Cart',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
