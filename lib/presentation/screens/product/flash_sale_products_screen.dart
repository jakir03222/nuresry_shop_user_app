import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/flash_sale_model.dart';
import '../../../data/services/api_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/shimmer_loader.dart';
import '../../widgets/product/product_card.dart';

class FlashSaleProductsScreen extends StatefulWidget {
  final String saleId;

  const FlashSaleProductsScreen({super.key, required this.saleId});

  @override
  State<FlashSaleProductsScreen> createState() =>
      _FlashSaleProductsScreenState();
}

class _FlashSaleProductsScreenState extends State<FlashSaleProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  FlashSaleModel? _flashSale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadFlashSaleDetails();
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      productProvider.resetFlashSaleProducts();
      productProvider.loadFlashSaleProducts(widget.saleId);
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
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    if (productProvider.isLoadingMoreFlashSale ||
        !productProvider.hasMoreFlashSaleProducts) {
      return;
    }

    productProvider.loadFlashSaleProducts(widget.saleId, loadMore: true);
  }

  Future<void> _loadFlashSaleDetails() async {
    try {
      final response = await ApiService.getFlashSaleById(widget.saleId);
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _flashSale = FlashSaleModel.fromJsonMap(
            response['data'] as Map<String, dynamic>,
          );
        });
      }
    } catch (e) {
      // Handle error silently or show message
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Flash Sale Image with Overlay Text
          if (_flashSale != null && _flashSale!.image.isNotEmpty)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_flashSale!.image),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Back Button and Title Row
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 40,
                        left: 8,
                        right: 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppColors.textWhite,
                              ),
                              onPressed: () {
                                context.pop();
                              },
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _flashSale!.title,
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48), // Balance the back button
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _flashSale!.discountText,
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _flashSale!.description,
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Products Grid
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading &&
                    productProvider.flashSaleProductsList.isEmpty) {
                  final itemWidth =
                      (screenWidth - 48) /
                      2; // screen width - padding - spacing
                  final itemHeight = itemWidth / 0.65; // based on aspect ratio

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet ? 3 : 2,
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
                          productProvider.errorMessage ??
                              'Failed to load products',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            productProvider.loadFlashSaleProducts(
                              widget.saleId,
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final products = productProvider.flashSaleProductsList;

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
                          'No products available in this flash sale',
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
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount:
                      products.length +
                      (productProvider.hasMoreFlashSaleProducts ||
                              productProvider.isLoadingMoreFlashSale
                          ? 1
                          : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator at the bottom when loading more
                    if (index >= products.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            color: AppColors.flashSaleRed,
                          ),
                        ),
                      );
                    }

                    final product = products[index];
                    final cartProvider = Provider.of<CartProvider>(
                      context,
                      listen: false,
                    );

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
                                content: Text(
                                  cartProvider.errorMessage ??
                                      'Failed to add to cart',
                                ),
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
          ),
        ],
      ),
    );
  }
}
