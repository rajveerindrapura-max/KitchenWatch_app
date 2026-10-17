import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../activity/domain/movement.dart';
import '../../../outlets/domain/outlet.dart';

class WastageChartCard extends StatelessWidget {
  final List<StockMovement> movements;
  final List<Outlet> outlets;
  final bool showValuation;

  const WastageChartCard({
    super.key,
    required this.movements,
    required this.outlets,
    this.showValuation = true,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Filter waste movements this week
    final weekWastage = movements.where((m) =>
        m.type == MovementType.wasted && m.timestamp.isAfter(sevenDaysAgo));

    // Map outlet ID to total wastage cost
    final Map<String, double> outletWastage = {};
    for (final outlet in outlets) {
      outletWastage[outlet.id] = 0.0;
    }

    double totalWasteValue = 0.0;
    for (final m in weekWastage) {
      outletWastage[m.fromOutletId] =
          (outletWastage[m.fromOutletId] ?? 0.0) + m.costImpact;
      totalWasteValue += m.costImpact;
    }

    final maxWaste = outletWastage.values.isEmpty
        ? 1.0
        : outletWastage.values.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxWaste > 0 ? maxWaste : 1.0;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Wastage this week', style: AppTypography.titleMedium),
              if (showValuation)
                Text(
                  CurrencyFormatter.format(totalWasteValue),
                  style: AppTypography.monoMedium.copyWith(
                    color: AppColors.wastageRose,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space4),
          Text('Breakdown across kitchen locations', style: AppTypography.bodySmall),
          const SizedBox(height: AppDimensions.space16),
          ...outlets.map((outlet) {
            final waste = outletWastage[outlet.id] ?? 0.0;
            final ratio = (waste / effectiveMax).clamp(0.02, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.space12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          outlet.name,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showValuation)
                        Text(
                          CurrencyFormatter.format(waste),
                          style: AppTypography.monoSmall.copyWith(
                            color: waste > 0 ? AppColors.textDark : AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space6),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            width: constraints.maxWidth * (waste > 0 ? ratio : 0.0),
                            height: 8,
                            decoration: BoxDecoration(
                              color: waste > 0 ? AppColors.wastageRose : AppColors.border,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
