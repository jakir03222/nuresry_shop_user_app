import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../providers/cart_provider.dart';

class FlashSaleDetailScreen extends StatelessWidget {
  final ProductModel product;

  const FlashSaleDetailScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          AppStrings.flashSale,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(width: 16),
                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '${AppStrings.unitPrice} ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (product.discountPrice != null)
                                Text(
                                  '${product.unitPrice.toStringAsFixed(0)}${AppConstants.currencySymbol} ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.priceOriginal,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                '${product.finalPrice.toStringAsFixed(0)}${AppConstants.currencySymbol}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.priceDiscount,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${AppStrings.available} ${product.availableQuantity} ${AppStrings.pcs}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${AppStrings.deliveryCharge} ${product.deliveryCharge.toStringAsFixed(0)}${AppConstants.currencySymbol}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Flash Sale Button
              CustomButton(
                text: AppStrings.flashSale,
                backgroundColor: AppColors.flashSaleRed,
                onPressed: () {
                  final cartProvider = Provider.of<CartProvider>(context, listen: false);
                  cartProvider.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to cart'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
