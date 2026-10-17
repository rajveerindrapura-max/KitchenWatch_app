import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/haptic_feedback_util.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/stock_level_bar.dart';
import '../../../inventory/domain/item_stock.dart';

class AttentionNeededSection extends StatelessWidget {
  final List<ItemStock> lowStockItems;

  const AttentionNeededSection({
    super.key,
    required this.lowStockItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Attention Needed Today',
                style: AppTypography.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (lowStockItems.isNotEmpty) ...[
              const SizedBox(width: AppDimensions.space8),
              StatusBadge(
                label: '${lowStockItems.length} alerts',
                backgroundColor: AppColors.lowStockAmberLight,
                textColor: AppColors.lowStockAmber,
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppDimensions.space12),
        if (lowStockItems.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppDimensions.space20),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.receivedGreen, size: 24),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('All stocks healthy', style: AppTypography.titleSmall),
                      Text('No items currently below minimum threshold', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...lowStockItems.take(5).map((stock) {
            final item = stock.item;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.space10),
              child: AppCard(
                padding: const EdgeInsets.all(AppDimensions.space14),
                onTap: () {
                  HapticUtil.light();
                  context.push('/inventory/item/${item.id}');
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.effectiveDisplayName,
                            style: AppTypography.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${stock.totalQuantity.toStringAsFixed(1)} / ${item.minLevel.toStringAsFixed(1)} ${item.unit.symbol}',
                          style: AppTypography.monoMedium.copyWith(
                            color: stock.isOutOfStock ? AppColors.wastageRose : AppColors.lowStockAmber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    StockLevelBar(
                      currentStock: stock.totalQuantity,
                      minStock: item.minLevel,
                    ),
                    const SizedBox(height: AppDimensions.space6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.category,
                          style: AppTypography.bodySmall,
                        ),
                        Text(
                          stock.isOutOfStock ? 'Out of stock' : 'Below safety level',
                          style: AppTypography.labelSmall.copyWith(
                            color: stock.isOutOfStock ? AppColors.wastageRose : AppColors.lowStockAmber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
