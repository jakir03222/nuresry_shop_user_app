import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.25).clamp(80.0, 120.0); // 25% of screen width, min 80, max 120
    final imageSize = (cardWidth * 0.6).clamp(50.0, 70.0); // 60% of card width, min 50, max 70
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth.clamp(80.0, 120.0), // Min 80, Max 120
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image Container with gradient border
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.1),
                    AppColors.primaryBlueLight.withOpacity(0.1),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: category.image,
                  fit: BoxFit.cover,
                  progressIndicatorBuilder: (context, url, downloadProgress) => Container(
                    color: AppColors.borderGrey,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: downloadProgress.progress,
                        strokeWidth: 2,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.borderGrey,
                    child: Icon(
                      Icons.category,
                      color: AppColors.textSecondary,
                      size: imageSize * 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Category Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.title,
                style: TextStyle(
                  fontSize: (screenWidth * 0.03).clamp(10.0, 13.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
