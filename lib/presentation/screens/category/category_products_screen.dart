import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product/product_card.dart';
import '../../providers/cart_provider.dart';

class CategoryProductsScreen extends StatelessWidget {
  final String categoryId;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    
    // Safely get category name
    String categoryName = 'Category';
    try {
      final category = productProvider.categories.firstWhere(
        (cat) => cat.id == categoryId,
      );
      categoryName = category.name;
    } catch (e) {
      // If category not found, use default name
      categoryName = 'Products';
    }
    
    final products = productProvider.getProductsByCategory(categoryId);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          categoryName,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No products found in this category',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
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
    );
  }
}
