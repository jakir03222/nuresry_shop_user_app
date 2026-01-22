import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/flash_sale_model.dart';

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
    return GestureDetector(
      onTap: onTap ?? () {
        context.push('/flash-sale-products/${flashSale.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: flashSale.image,
                fit: BoxFit.cover,
                progressIndicatorBuilder: (context, url, downloadProgress) => Container(
                  color: AppColors.borderGrey,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: downloadProgress.progress,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.flashSaleRed,
                  child: const Icon(
                    Icons.flash_on,
                    size: 50,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Discount Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.flashSaleRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      flashSale.discountText,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Title and Description
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flashSale.title,
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        flashSale.description,
                        style: TextStyle(
                          color: AppColors.textWhite.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
