import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/flash_sale_model.dart';

/// Flash sale promotion card - matches reference design:
/// - White card with shadow and rounded corners
/// - Product/deal image on top
/// - Discount badge (top-left): light grey bg, dark border - X% or X৳
/// - Title below image
/// - Discount text as price area
/// - "Add to cart" button with cart icon (same color as other cards)
class FlashSalePromotionCard extends StatelessWidget {
  final FlashSaleModel flashSale;
  final VoidCallback? onTap;

  const FlashSalePromotionCard({
    super.key,
    required this.flashSale,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flashSale = this.flashSale;

    // Discount badge text: percentage shows "X%", fixed shows "X৳"
    final discountBadgeText = flashSale.discountType == 'percentage'
        ? '${flashSale.discountValue}%'
        : '${flashSale.discountValue}${AppConstants.currencySymbol}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image section - tap goes to flash sale products
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Stack(
                clipBehavior: Clip.antiAlias,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: flashSale.image,
                      width: double.infinity,
                      height: 130,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 130,
                        color: AppColors.borderGrey,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 130,
                        color: AppColors.borderGrey,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  // Discount badge - top-left, light grey with dark border
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.textSecondary.withOpacity(0.6),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        discountBadgeText,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content - title and discount text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  flashSale.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  flashSale.discountText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.flashSaleOrange,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Add to cart button
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(
                  Icons.shopping_cart,
                  size: 18,
                  color: AppColors.textWhite,
                ),
                label: const Text(
                  'Add to cart',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: Size.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
