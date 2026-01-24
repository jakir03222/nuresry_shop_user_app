import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/coupon_model.dart';
import '../../providers/coupon_provider.dart';
import '../../widgets/common/shimmer_loader.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CouponProvider>(context, listen: false).loadCoupons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'My Coupons',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<CouponProvider>(
        builder: (context, couponProvider, child) {
          if (couponProvider.isLoading && couponProvider.coupons.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ShimmerLoader(
                  width: double.infinity,
                  height: 120,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            );
          }

          if (couponProvider.errorMessage != null && couponProvider.coupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(couponProvider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => couponProvider.loadCoupons(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (couponProvider.coupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No coupons available at the moment'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => couponProvider.loadCoupons(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: couponProvider.coupons.length,
              itemBuilder: (context, index) {
                final coupon = couponProvider.coupons[index];
                return _CouponCard(coupon: coupon);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;

  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final isPercentage = coupon.discountType == 'percentage';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: coupon.isValid ? AppColors.primaryBlue.withOpacity(0.2) : AppColors.borderGrey,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Left side discount value
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: coupon.isValid ? AppColors.primaryBlue : AppColors.textSecondary,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isPercentage ? '${coupon.discountValue.toInt()}%' : '৳${coupon.discountValue.toInt()}',
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'OFF',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Coupon info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  coupon.code,
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (coupon.isValid)
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: coupon.code));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Coupon code "${coupon.code}" copied!'),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: AppColors.primaryBlue,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.copy, color: AppColors.textWhite, size: 12),
                                        SizedBox(width: 4),
                                        Text(
                                          'COPY',
                                          style: TextStyle(
                                            color: AppColors.textWhite,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (!coupon.isValid)
                                Text(
                                  coupon.isExpired ? 'EXPIRED' : 'INACTIVE',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (coupon.description != null)
                            Text(
                              coupon.description!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          if (coupon.minOrderAmount != null && coupon.minOrderAmount! > 0)
                            Text(
                              'Min. order: ৳${coupon.minOrderAmount!.toInt()}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Valid until: ${dateFormat.format(coupon.validUntil)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Semi-circle cuts
            Positioned(
              top: -10,
              left: 90,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundLight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              left: 90,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundLight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
