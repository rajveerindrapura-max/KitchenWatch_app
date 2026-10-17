import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/count_up_text.dart';

class StatCardsRow extends StatelessWidget {
  final double totalStockValue;
  final int totalItemsCount;
  final int lowStockCount;
  final bool showValuation; // False for roles that cannot view valuation

  const StatCardsRow({
    super.key,
    required this.totalStockValue,
    required this.totalItemsCount,
    required this.lowStockCount,
    this.showValuation = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 580;

        final cards = [
          if (showValuation)
            _StatCard(
              title: 'Total Stock Value',
              valueChild: CountUpText(
                value: totalStockValue,
                style: AppTypography.monoLarge.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
                formatter: (val) => CurrencyFormatter.format(val),
              ),
              subtitle: 'Valued via purchase FIFO',
              icon: Icons.currency_rupee_rounded,
              iconColor: AppColors.brandBlue,
              iconBgColor: AppColors.brandBlueLight,
            ),
          _StatCard(
            title: 'Tracked Items',
            valueChild: CountUpText(
              value: totalItemsCount,
              style: AppTypography.monoLarge.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
              formatter: (val) => val.toInt().toString(),
            ),
            subtitle: 'Active raw materials',
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.neutralTeal,
            iconBgColor: AppColors.neutralTealLight,
          ),
          _StatCard(
            title: 'Low-Stock Alerts',
            valueChild: CountUpText(
              value: lowStockCount,
              style: AppTypography.monoLarge.copyWith(
                color: lowStockCount > 0 ? AppColors.lowStockAmber : AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
              formatter: (val) => val.toInt().toString(),
            ),
            subtitle: lowStockCount > 0 ? 'Requires attention' : 'All optimal',
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.lowStockAmber,
            iconBgColor: AppColors.lowStockAmberLight,
          ),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cards
                .map(
                  (card) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space6),
                      child: card,
                    ),
                  ),
                )
                .toList(),
          );
        }

        return Column(
          children: cards
              .map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Widget valueChild;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _StatCard({
    required this.title,
    required this.valueChild,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.labelMedium),
              Container(
                padding: const EdgeInsets.all(AppDimensions.space6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          valueChild,
          const SizedBox(height: AppDimensions.space4),
          Text(subtitle, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
