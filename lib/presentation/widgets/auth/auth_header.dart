import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? illustration;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.35,
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
          if (illustration != null)
            Positioned(
              right: 0,
              top: 40,
              child: illustration!,
            ),
        ],
      ),
    );
  }
}
