import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/shimmer_loader.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.loadProductById(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading && productProvider.currentProduct == null) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryBlue,
                ),
              ),
            );
          }

          if (productProvider.errorMessage != null || productProvider.currentProduct == null) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: AppColors.primaryBlue,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
                  onPressed: () => context.pop(),
                ),
              ),
              body: Center(
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
                      productProvider.errorMessage ?? 'Product not found',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        productProvider.loadProductById(widget.productId);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final product = productProvider.currentProduct!;
          final cartProvider = Provider.of<CartProvider>(context, listen: false);
          final allImages = product.images != null && product.images!.isNotEmpty
              ? [product.imageUrl, ...product.images!]
              : [product.imageUrl];

          return CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: AppColors.primaryBlue,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border, color: AppColors.textWhite),
                    onPressed: () {
                      // TODO: Add to favorites
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: PageView.builder(
                    itemCount: allImages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: allImages[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ShimmerLoader(
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.borderGrey,
                          child: const Icon(Icons.image, size: 100),
                        ),
                      );
                    },
                  ),
                ),
                bottom: allImages.length > 1
                    ? PreferredSize(
                        preferredSize: const Size.fromHeight(30),
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              allImages.length,
                              (index) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _selectedImageIndex == index
                                      ? AppColors.textWhite
                                      : AppColors.textWhite.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              // Product Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name and Rating
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (product.sku != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'SKU: ${product.sku}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                if (product.brand != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Brand: ${product.brand}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (product.rating != null && product.rating! > 0)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentYellow.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: AppColors.accentYellow,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    product.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (product.reviewCount != null && product.reviewCount! > 0)
                                    Text(
                                      ' (${product.reviewCount})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Price Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Price:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (product.discountPrice != null)
                                  Text(
                                    priceFormat.format(product.unitPrice),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  )
                                else
                                  Text(
                                    priceFormat.format(product.unitPrice),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                              ],
                            ),
                            if (product.discountPrice != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Discount Price:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentRed,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                                          style: const TextStyle(
                                            color: AppColors.textWhite,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    priceFormat.format(product.finalPrice),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Available:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  product.isAvailable && product.availableQuantity > 0
                                      ? '${product.availableQuantity} pcs'
                                      : 'Out of Stock',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: product.isAvailable && product.availableQuantity > 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Delivery Charge:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  priceFormat.format(product.deliveryCharge),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Description
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              product.description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (product.tags != null && product.tags!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderGrey),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tags',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: product.tags!.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlueLight.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.primaryBlueLight,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Quantity Selector
                      if (product.isAvailable && product.availableQuantity > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderGrey),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Quantity:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: _quantity > 1
                                        ? () {
                                            setState(() {
                                              _quantity--;
                                            });
                                          }
                                        : null,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      '$_quantity',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: _quantity < product.availableQuantity
                                        ? () {
                                            setState(() {
                                              _quantity++;
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: cartProvider.isLoading
                                    ? null
                                    : () async {
                                        try {
                                          await cartProvider.addToCart(product, quantity: _quantity);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('$_quantity x ${product.name} added to cart'),
                                                backgroundColor: AppColors.success,
                                                behavior: SnackBarBehavior.floating,
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
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: AppColors.primaryBlue),
                                ),
                                child: const Text(
                                  'Add to Cart',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                text: 'Buy Now',
                                isLoading: cartProvider.isLoading,
                                onPressed: () async {
                                  try {
                                    await cartProvider.addToCart(product, quantity: _quantity);
                                    if (context.mounted) {
                                      context.push('/checkout');
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
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.accentRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accentRed),
                          ),
                          child: const Center(
                            child: Text(
                              'Out of Stock',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentRed,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
