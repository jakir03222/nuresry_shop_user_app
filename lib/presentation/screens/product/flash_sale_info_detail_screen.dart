import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/flash_sale_model.dart';
import '../../../data/services/api_service.dart';
import '../../providers/product_provider.dart';

/// Screen showing single flash sale details (title, description, image, discount, dates, etc.)
class FlashSaleInfoDetailScreen extends StatefulWidget {
  final String saleId;

  const FlashSaleInfoDetailScreen({super.key, required this.saleId});

  @override
  State<FlashSaleInfoDetailScreen> createState() =>
      _FlashSaleInfoDetailScreenState();
}

class _FlashSaleInfoDetailScreenState extends State<FlashSaleInfoDetailScreen> {
  FlashSaleModel? _flashSale;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFlashSale();
  }

  Future<void> _loadFlashSale() async {
    // Try provider first (instant)
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final fromProvider = productProvider.getFlashSaleById(widget.saleId);
    if (fromProvider != null) {
      setState(() {
        _flashSale = fromProvider;
        _isLoading = false;
      });
      return;
    }

    // Fetch from API
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService.getFlashSaleById(widget.saleId);
      if (!mounted) return;
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _flashSale = FlashSaleModel.fromJsonMap(
            response['data'] as Map<String, dynamic>,
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] as String? ?? 'Failed to load';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.flashSaleRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Flash Sale Details',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.flashSaleRed),
      );
    }
    if (_errorMessage != null || _flashSale == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Flash sale not found',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final flashSale = _flashSale!;
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          if (flashSale.image.isNotEmpty)
            Container(
              width: double.infinity,
              height: 220,
              color: AppColors.borderGrey,
              child: CachedNetworkImage(
                imageUrl: flashSale.image,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.image_not_supported_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Discount badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.flashSaleRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    flashSale.discountText,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  flashSale.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                if (flashSale.description.isNotEmpty)
                  Text(
                    flashSale.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 20),
                // Details card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGrey),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow(
                        'Discount Type',
                        flashSale.discountType == 'percentage'
                            ? 'Percentage'
                            : 'Fixed Amount',
                      ),
                      _detailRow(
                        'Discount Value',
                        flashSale.discountType == 'percentage'
                            ? '${flashSale.discountValue}%'
                            : '${flashSale.discountValue}${AppConstants.currencySymbol}',
                      ),
                      _detailRow(
                        'Start Date',
                        dateFormat.format(flashSale.startDate),
                      ),
                      _detailRow(
                        'End Date',
                        dateFormat.format(flashSale.endDate),
                      ),
                      _detailRow(
                        'Status',
                        flashSale.isActive ? 'Active' : 'Inactive',
                      ),
                      _detailRow('Featured', flashSale.featured ? 'Yes' : 'No'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // View Products button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/flash-sale-products/${flashSale.id}');
                    },
                    icon: const Icon(
                      Icons.shopping_bag,
                      color: AppColors.textWhite,
                    ),
                    label: const Text(
                      'View Products',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
