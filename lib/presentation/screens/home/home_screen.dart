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
import '../../widgets/product/product_card.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _currentSearchQuery = '';
  bool _isSearching = false;

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.resetSearchResults();
      setState(() {
        _currentSearchQuery = '';
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _currentSearchQuery = query.trim();
      _isSearching = true;
    });

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.resetSearchResults();
    productProvider.searchProductsByTags(searchTerm: _currentSearchQuery);
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: _isSearching
            ? Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name or tags...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                            onPressed: _clearSearch,
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    // Debounce search - perform search after user stops typing
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value && mounted) {
                        _performSearch(value);
                      }
                    });
                  },
                  onSubmitted: _performSearch,
                ),
              )
            : Text(
                AppStrings.appName,
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
        centerTitle: !_isSearching,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.textWhite),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
              tooltip: 'Search Products',
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textWhite),
              onPressed: _clearSearch,
              tooltip: 'Close Search',
            ),
        ],
      ),
      body: _isSearching ? _buildSearchResults() : _buildHomeContent(),
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
        selectedItemColor: AppColors.primary,
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

  Widget _buildHomeContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return SingleChildScrollView(
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
                      color: AppColors.primary,
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
                      color: AppColors.primary,
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
              
              if (categories.isEmpty) {
                return SizedBox(
                  height: categoryHeight,
                  child: Center(
                    child: Text(
                      'No categories available',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }
              
              // Calculate card width for horizontal list
              final cardWidth = (screenWidth * 0.35).clamp(120.0, 160.0);
              
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
                    return SizedBox(
                      width: cardWidth,
                      child: CategoryCard(
                        category: category,
                        onTap: () {
                          context.push('/category-products/$categoryId');
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
     
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
                      color: AppColors.primary,
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
                            color: AppColors.primary,
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
    );
  }

  Widget _buildSearchResults() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading && productProvider.searchResults.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const ShimmerLoader(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          );
        }

        if (productProvider.errorMessage != null &&
            productProvider.searchResults.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    productProvider.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _performSearch(_currentSearchQuery),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (_currentSearchQuery.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Search products by name or tags',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Enter product name or tags like "rose", "flower", "outdoor"',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        if (productProvider.searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try different search terms',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Search results count
            if (productProvider.searchTotalDocuments > 0)
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Row(
                  children: [
                    Text(
                      'Found ${productProvider.searchTotalDocuments} products',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            // Products grid
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(screenWidth * 0.04),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: productProvider.searchResults.length +
                    (productProvider.isLoadingMoreSearch ? 2 : 0),
                itemBuilder: (context, index) {
                  if (index >= productProvider.searchResults.length) {
                    return const ShimmerLoader(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    );
                  }

                  final product = productProvider.searchResults[index];
                  final cartProvider = Provider.of<CartProvider>(context, listen: false);
                  
                  return ProductCard(
                    product: product,
                    onTap: () {
                      context.push('/product-detail/${product.id}');
                    },
                    onAddToCart: () async {
                      try {
                        await cartProvider.addToCart(product);
                        if (mounted) {
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
                        if (mounted) {
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
              ),
            ),
          ],
        );
      },
    );
  }
}
