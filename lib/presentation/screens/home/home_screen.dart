import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../widgets/home/category_card.dart';
import '../../widgets/home/flash_sale_card.dart';
import '../../widgets/common/custom_drawer.dart';
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
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.loadCategories();
      productProvider.loadProducts();
    });
  }

  // Mock data - Replace with actual data from provider
  List<CategoryModel> get _categories {
    final productProvider = Provider.of<ProductProvider>(context);
    return productProvider.categories.isNotEmpty
        ? productProvider.categories
        : [
    CategoryModel(
      id: '1',
      name: 'Mango',
      imageUrl: 'https://via.placeholder.com/100',
    ),
    CategoryModel(
      id: '2',
      name: 'jursey',
      imageUrl: 'https://via.placeholder.com/100',
    ),
    CategoryModel(
      id: '3',
      name: 'বাংলাদেশ',
      imageUrl: 'https://via.placeholder.com/100',
    ),
    CategoryModel(
      id: '4',
      name: 'mx ope',
      imageUrl: 'https://via.placeholder.com/100',
    ),
    CategoryModel(
      id: '5',
      name: 'mx ope k...',
      imageUrl: 'https://via.placeholder.com/100',
    ),
    CategoryModel(
      id: '6',
      name: 'Banglade...',
      imageUrl: 'https://via.placeholder.com/100',
    ),
          ];
  }

  List<ProductModel> get _flashSaleProducts {
    final productProvider = Provider.of<ProductProvider>(context);
    return productProvider.flashSaleProducts.isNotEmpty
        ? productProvider.flashSaleProducts
        : [
    ProductModel(
      id: '1',
      name: 'Biman Bangladesh',
      description: 'biman Bangladesh',
      imageUrl: 'https://via.placeholder.com/80',
      unitPrice: 250,
      discountPrice: 230,
      availableQuantity: 20,
      deliveryCharge: 12,
      categoryId: '1',
      isFlashSale: true,
    ),
          ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGrey,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          AppStrings.appName,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              final itemCount = cartProvider.itemCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: AppColors.textPrimary),
                    onPressed: () {
                      context.push('/cart');
                    },
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.accentRed,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          itemCount > 9 ? '9+' : '$itemCount',
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 10,
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
            // Hero Banner
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.borderGrey,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://via.placeholder.com/400x200',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.borderGrey,
                      child: const Icon(Icons.image, size: 50),
                    );
                  },
                ),
              ),
            ),
            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    AppStrings.categories,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/all-categories');
                    },
                    child: const Text(
                      AppStrings.viewAllCategories,
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Categories Grid
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CategoryCard(
                      category: _categories[index],
                      onTap: () {
                        context.push('/category-products/${_categories[index].id}');
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Flash Sale Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    AppStrings.flashSale,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/all-flash-sales');
                    },
                    child: const Text(
                      AppStrings.viewAllFlashSale,
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Flash Sale Products
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _flashSaleProducts.map((product) {
                  return FlashSaleCard(
                    product: product,
                    onTap: () {
                      context.push('/product-detail/${product.id}');
                    },
                    onFlashSaleTap: () {
                      // Handle flash sale action - add to cart
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
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
