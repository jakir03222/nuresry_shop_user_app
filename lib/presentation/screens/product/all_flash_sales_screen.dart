import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/product_provider.dart';
import '../../widgets/home/flash_sale_promotion_card.dart';
import '../../widgets/common/shimmer_loader.dart';

class AllFlashSalesScreen extends StatelessWidget {
  const AllFlashSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.flashSaleRed,
        elevation: 0,
        title: const Text(
          'Flash Sale',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading && productProvider.flashSales.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: const ShimmerLoader(
                    width: double.infinity,
                    height: 180,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                );
              },
            );
          }

          if (productProvider.flashSales.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.flash_off,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No flash sales available',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Flash Sale Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.flashSaleRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '🔥 LIMITED TIME OFFER 🔥',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Hurry up! These deals won\'t last long',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Flash Sales List
                ...productProvider.flashSales.map((flashSale) {
                  return FlashSalePromotionCard(
                    flashSale: flashSale,
                    onTap: () {
                      context.push('/flash-sale-products/${flashSale.id}');
                    },
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
