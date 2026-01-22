import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/flash_sale_model.dart';
import '../../../data/services/api_service.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product/product_card.dart';
import '../../widgets/common/shimmer_loader.dart';

class FlashSaleProductsScreen extends StatefulWidget {
  final String saleId;

  const FlashSaleProductsScreen({
    super.key,
    required this.saleId,
  });

  @override
  State<FlashSaleProductsScreen> createState() => _FlashSaleProductsScreenState();
}

class _FlashSaleProductsScreenState extends State<FlashSaleProductsScreen> {
  FlashSaleModel? _flashSale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFlashSaleDetails();
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.loadFlashSaleProducts(widget.saleId);
    });
  }

  Future<void> _loadFlashSaleDetails() async {
    try {
      final response = await ApiService.getFlashSaleById(widget.saleId);
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _flashSale = FlashSaleModel.fromJsonMap(response['data'] as Map<String, dynamic>);
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
      appBar: AppBar(
        backgroundColor: AppColors.flashSaleRed,
        elevation: 0,
        title: Text(
          _flashSale?.title ?? 'Flash Sale',
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Flash Sale Banner
          if (_flashSale != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.flashSaleRed,
              ),
              child: Column(
                children: [
                  Text(
                    _flashSale!.discountText,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 24,
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
                  ),
                ],
              ),
            ),
          // Products Grid
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading && productProvider.flashSaleProductsList.isEmpty) {
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
                      return const ShimmerLoader(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      );
                    },
                  );
                }

                if (productProvider.flashSaleProductsList.isEmpty) {
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
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: productProvider.flashSaleProductsList.length,
                  itemBuilder: (context, index) {
                    final product = productProvider.flashSaleProductsList[index];
                    final cartProvider = Provider.of<CartProvider>(context, listen: false);

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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
