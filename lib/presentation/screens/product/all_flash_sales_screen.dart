import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product/product_card.dart';
import '../../providers/cart_provider.dart';

class AllFlashSalesScreen extends StatelessWidget {
  const AllFlashSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final flashSaleProducts = productProvider.flashSaleProducts;

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
      body: flashSaleProducts.isEmpty
          ? Center(
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
                    'No flash sale products available',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Flash Sale Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.flashSaleRed,
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
                // Products Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: flashSaleProducts.length,
                    itemBuilder: (context, index) {
                      final product = flashSaleProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          context.push('/product-detail/${product.id}');
                        },
                        onAddToCart: () {
                          cartProvider.addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart'),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
