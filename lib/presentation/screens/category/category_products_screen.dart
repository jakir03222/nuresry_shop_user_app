import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product/product_card.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/shimmer_loader.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    debugPrint('[CategoryProductsScreen] initState - Category ID: ${widget.categoryId}');
    
    // Load products by category when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        debugPrint('[CategoryProductsScreen] Widget not mounted, skipping load');
        return;
      }
      debugPrint('[CategoryProductsScreen] Loading products for category: ${widget.categoryId}');
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.resetCategoryProducts();
      productProvider.loadProductsByCategory(widget.categoryId);
    });
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when 200px from bottom
      _loadMoreProducts();
    }
  }

  void _loadMoreProducts() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (productProvider.isLoadingMore || !productProvider.hasMoreProducts) {
      return;
    }
    
    productProvider.loadProductsByCategory(
      widget.categoryId,
      loadMore: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            // Safely get category name
            String categoryName = 'Products';
            try {
              final category = productProvider.categories.firstWhere(
                (cat) => cat.id == widget.categoryId,
              );
              categoryName = category.title;
            } catch (e) {
              categoryName = 'Products';
            }
            return Text(
              categoryName,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          debugPrint('[CategoryProductsScreen] Building UI - Category ID: ${widget.categoryId}');
          debugPrint('[CategoryProductsScreen] isLoading: ${productProvider.isLoading}');
          debugPrint('[CategoryProductsScreen] isLoadingMore: ${productProvider.isLoadingMore}');
          debugPrint('[CategoryProductsScreen] errorMessage: ${productProvider.errorMessage}');
          debugPrint('[CategoryProductsScreen] products count: ${productProvider.categoryProducts.length}');
          debugPrint('[CategoryProductsScreen] hasMoreProducts: ${productProvider.hasMoreProducts}');
          
          if (productProvider.isLoading) {
            final screenWidth = MediaQuery.of(context).size.width;
            final itemWidth = (screenWidth - 48) / 2; // screen width - padding - spacing
            final itemHeight = itemWidth / 0.65; // based on aspect ratio
            
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return ShimmerLoader(
                  width: itemWidth,
                  height: itemHeight,
                  borderRadius: BorderRadius.circular(12),
                );
              },
            );
          }

          if (productProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Products',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      productProvider.errorMessage ?? 'Failed to load products',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Category ID: ${widget.categoryId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        debugPrint('[CategoryProductsScreen] Retry button pressed');
                        debugPrint('[CategoryProductsScreen] Category ID: ${widget.categoryId}');
                        productProvider.resetCategoryProducts();
                        productProvider.loadProductsByCategory(widget.categoryId);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.textWhite,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final products = productProvider.categoryProducts;

          if (products.isEmpty) {
            return Center(
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
            );
          }

          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemCount: products.length + 
                       (productProvider.hasMoreProducts || productProvider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Show loading indicator at the bottom when loading more
              if (index >= products.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                );
              }
              
              final product = products[index];
              final cartProvider = Provider.of<CartProvider>(context, listen: false);
              
              return ProductCard(
                product: product,
                onTap: () {
                  context.push('/product-detail/${product.id}');
                },
                onAddToCart: () async {
                  try {
                    await cartProvider.addToCart(product);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(cartProvider.errorMessage ?? 'Failed to add to cart'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
