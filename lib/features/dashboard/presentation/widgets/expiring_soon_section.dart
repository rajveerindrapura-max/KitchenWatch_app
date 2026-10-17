import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/haptic_feedback_util.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../inventory/domain/item_stock.dart';

class ExpiringSoonSection extends StatelessWidget {
  final List<ItemStock> expiringItems;

  const ExpiringSoonSection({
    super.key,
    required this.expiringItems,
  });

  @override
  Widget build(BuildContext context) {
    if (expiringItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Expiring Soon',
                style: AppTypography.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppDimensions.space8),
            StatusBadge(
              label: '${expiringItems.length} items',
              backgroundColor: AppColors.wastageRoseLight,
              textColor: AppColors.wastageRose,
              icon: Icons.schedule_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space12),
        ...expiringItems.take(4).map((stock) {
          final item = stock.item;
          final batch = stock.nearestExpiringBatch;
          if (batch == null || batch.expiryDate == null) return const SizedBox.shrink();

          final daysLeftStr = DateFormatter.daysLeft(batch.expiryDate!);

          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.space10),
            child: AppCard(
              padding: const EdgeInsets.all(AppDimensions.space14),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space8,
                          vertical: AppDimensions.space4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.wastageRoseLight,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                        ),
                        child: Text(
                          daysLeftStr,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.wastageRose,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Batch quantity: ${batch.quantity.toStringAsFixed(1)} ${item.unit.symbol}',
                        style: AppTypography.monoSmall,
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(40, 32),
                        ),
                        onPressed: () {
                          HapticUtil.light();
                          // Prefilled transfer route
                          context.push(
                            '/transfers/new?itemId=${item.id}&quantity=${batch.quantity}&fromOutletId=${batch.outletId}',
                          );
                        },
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.transferViolet),
                        label: Text(
                          'Move to outlet',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.transferViolet),
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
