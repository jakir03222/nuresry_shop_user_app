import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/home/category_card.dart';
import '../../widgets/home/flash_sale_promotion_card.dart';
import '../../widgets/home/flash_sale_card.dart';
import '../../widgets/home/carousel_slider.dart';
import '../../widgets/common/shimmer_loader.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      productProvider.loadCarousels();
      productProvider.loadCategories();
      productProvider.loadFlashSales();
      // Load cart from cache first, then sync with API
      cartProvider.loadCart(useCache: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGrey,
        elevation: 0,
        title: Text(
          AppStrings.appName,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: isTablet ? 22 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: AppColors.textPrimary,
              size: isTablet ? 28 : 24,
            ),
            onPressed: () {},
          ),
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              final totalQuantity = cartProvider.totalQuantity;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shopping_cart,
                      color: AppColors.textPrimary,
                      size: isTablet ? 28 : 24,
                    ),
                    onPressed: () {
                      context.push('/cart');
                    },
                  ),
                  if (totalQuantity > 0)
                    Positioned(
                      right: isTablet ? 10 : 8,
                      top: isTablet ? 10 : 8,
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 6 : 4),
                        decoration: const BoxDecoration(
                          color: AppColors.accentRed,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: isTablet ? 20 : 16,
                          minHeight: isTablet ? 20 : 16,
                        ),
                        child: Text(
                          totalQuantity > 9 ? '9+' : '$totalQuantity',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: isTablet ? 12 : 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Carousels Section Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.carousels,
                    style: TextStyle(
                      fontSize: isTablet ? 22 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/all-carousels'),
                    child: Text(
                      AppStrings.getAllCarousels,
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Carousel Slider
            Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading && productProvider.carousels.isEmpty) {
                  return Container(
                    height: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.borderGrey,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return CarouselSliderWidget(
                  carousels: productProvider.carousels,
                );
              },
            ),
            SizedBox(height: screenHeight * 0.02),
            // Categories Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.categories,
                    style: TextStyle(
                      fontSize: isTablet ? 22 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/all-categories');
                    },
                    child: Text(
                      AppStrings.viewAllCategories,
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            // Categories Grid
            Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                final categoryHeight = isTablet ? 180.0 : 150.0;
                
                if (productProvider.isLoading && productProvider.categories.isEmpty) {
                  return SizedBox(
                    height: categoryHeight,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: const CategoryShimmer(),
                        );
                      },
                    ),
                  );
                }
                final categories = productProvider.categories;
                return SizedBox(
                  height: categoryHeight,
                  width: double.infinity,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final categoryId = category.id;
                      return CategoryCard(
                        category: category,
                        onTap: () {
                          context.push('/category-products/$categoryId');
                        },
                      );
                    },
                  ),
                );
              },
            ),
            SizedBox(height: screenHeight * 0.03),
            // Flash Sale Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.flashSale,
                    style: TextStyle(
                      fontSize: isTablet ? 22 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/all-flash-sales');
                    },
                    child: Text(
                      AppStrings.viewAllFlashSale,
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            // Flash Sales from API
            Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading && productProvider.flashSales.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: Column(
                      children: List.generate(2, (index) => const ShimmerLoader(
                        width: double.infinity,
                        height: 180,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      )),
                    ),
                  );
                }
                
                if (productProvider.flashSales.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Column(
                    children: productProvider.flashSales.map((flashSale) {
                      return FlashSalePromotionCard(
                        flashSale: flashSale,
                        onTap: () {
                          context.push('/flash-sale-products/${flashSale.id}');
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            // Flash Sale Products Header
            Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.flashSaleProducts.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Flash Sale Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (productProvider.flashSales.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            context.push('/flash-sale-products/${productProvider.flashSales.first.id}');
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            // Flash Sale Products List
            Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.flashSaleProducts.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Column(
                    children: productProvider.flashSaleProducts.map((product) {
                      return FlashSaleCard(
                        product: product,
                        onTap: () {
                          context.push('/product-detail/${product.id}');
                        },
                        onFlashSaleTap: () {
                          context.push('/flash-sale-products/${productProvider.flashSales.first.id}');
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            SizedBox(height: screenHeight * 0.03),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.push('/cart');
              break;
            case 2:
              context.push('/profile');
              break;
          }
        },
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: AppStrings.cart,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }
}
