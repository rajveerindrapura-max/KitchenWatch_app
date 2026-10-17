import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class StockLevelBar extends StatelessWidget {
  final double currentStock;
  final double minStock;
  final double height;

  const StockLevelBar({
    super.key,
    required this.currentStock,
    required this.minStock,
    this.height = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMin = minStock > 0 ? minStock : 1.0;
    // Healthy baseline is twice the min level
    final double maxReference = effectiveMin * 2.0;
    final double ratio = (currentStock / maxReference).clamp(0.0, 1.0);

    Color barColor;
    if (currentStock <= 0) {
      barColor = AppColors.wastageRose;
    } else if (currentStock <= minStock) {
      barColor = AppColors.lowStockAmber;
    } else {
      barColor = AppColors.receivedGreen;
    }

    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetWidth = constraints.maxWidth * ratio;

          if (disableAnimations) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: targetWidth,
                height: height,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
              ),
            );
          }

          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                width: targetWidth,
                height: height,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
