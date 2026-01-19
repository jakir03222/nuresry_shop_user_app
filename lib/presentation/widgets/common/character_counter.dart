import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CharacterCounter extends StatelessWidget {
  final int currentLength;
  final int maxLength;

  const CharacterCounter({
    super.key,
    required this.currentLength,
    required this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$currentLength/$maxLength',
      style: TextStyle(
        fontSize: 12,
        color: currentLength > maxLength
            ? AppColors.error
            : AppColors.textSecondary,
      ),
    );
  }
}
