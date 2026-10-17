import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/haptic_feedback_util.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../activity/domain/movement.dart';

class RecentLedgerSection extends StatelessWidget {
  final List<StockMovement> movements;
  final bool showValuation;

  const RecentLedgerSection({
    super.key,
    required this.movements,
    this.showValuation = true,
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
                'Recent Movements Ledger',
                style: AppTypography.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                HapticUtil.light();
                context.push('/activity');
              },
              child: const Text('View full ledger'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space8),
        if (movements.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Text('No movements recorded yet', style: AppTypography.bodyMedium),
          )
        else
          ...movements.take(5).map((m) {
            Color badgeBg;
            Color badgeText;
            IconData icon;
            String prefix;

            switch (m.type) {
              case MovementType.received:
                badgeBg = AppColors.receivedGreenLight;
                badgeText = AppColors.receivedGreen;
                icon = Icons.south_west_rounded;
                prefix = '+';
                break;
              case MovementType.used:
                badgeBg = AppColors.neutralTealLight;
                badgeText = AppColors.neutralTeal;
                icon = Icons.remove_circle_outline;
                prefix = '-';
                break;
              case MovementType.wasted:
                badgeBg = AppColors.wastageRoseLight;
                badgeText = AppColors.wastageRose;
                icon = Icons.delete_outline_rounded;
                prefix = '-';
                break;
              case MovementType.transferred:
                badgeBg = AppColors.transferVioletLight;
                badgeText = AppColors.transferViolet;
                icon = Icons.swap_horiz_rounded;
                prefix = '';
                break;
              case MovementType.adjustment:
                badgeBg = AppColors.lowStockAmberLight;
                badgeText = AppColors.lowStockAmber;
                icon = Icons.tune_rounded;
                prefix = '~';
                break;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.space8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space14,
                  vertical: AppDimensions.space12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space8),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                      ),
                      child: Icon(icon, size: 16, color: badgeText),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  m.itemName,
                                  style: AppTypography.titleSmall,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space6),
                              StatusBadge(
                                label: m.type.displayName,
                                backgroundColor: badgeBg,
                                textColor: badgeText,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.space2),
                          Text(
                            '${m.userName} (${m.userRole.displayName}) - ${DateFormatter.timeAgo(m.timestamp)}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$prefix${m.quantity.toStringAsFixed(1)} ${m.unit.symbol}',
                          style: AppTypography.monoMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: m.type == MovementType.received
                                ? AppColors.receivedGreen
                                : (m.type == MovementType.wasted ? AppColors.wastageRose : AppColors.textDark),
                          ),
                        ),
                        if (showValuation && m.costImpact > 0)
                          Text(
                            CurrencyFormatter.format(m.costImpact),
                            style: AppTypography.monoSmall,
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
