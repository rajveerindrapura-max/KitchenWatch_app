import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';

class SampleDataBadge extends StatelessWidget {
  const SampleDataBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutralTealLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: AppColors.neutralTeal.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.neutralTeal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDimensions.space4),
          Text(
            AppStrings.sampleDataBadge,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.neutralTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
