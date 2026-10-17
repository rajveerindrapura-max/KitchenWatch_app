import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/sample_data_badge.dart';
import '../../../core/widgets/staggered_list.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/stock_level_bar.dart';

class MyOutletStockScreen extends ConsumerWidget {
  const MyOutletStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final outletsAsync = ref.watch(outletsProvider);
    final itemStocksAsync = ref.watch(itemStocksProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);

    final user = userAsync.value;
    final outlets = outletsAsync.value ?? [];
    final itemStocks = itemStocksAsync.value ?? [];

    if (user == null || outlets.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final outletId = user.assignedOutletIds.isNotEmpty ? user.assignedOutletIds.first : outlets.first.id;
    final outletMatch = outlets.where((o) => o.id == outletId);
    final outletName = outletMatch.isNotEmpty ? outletMatch.first.name : 'My Outlet';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text('My Outlet Stock', style: AppTypography.titleLarge),
            const SizedBox(width: AppDimensions.space8),
            if (isDemoMode) const SampleDataBadge(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticUtil.light();
          context.push('/record-stock');
        },
        backgroundColor: AppColors.brandBlue,
        foregroundColor: AppColors.textInverse,
        icon: const Icon(Icons.remove_circle_outline, size: 20),
        label: const Text('Record used / wasted'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space12,
                ),
                color: AppColors.surfaceMuted,
                child: Row(
                  children: [
                    const Icon(Icons.storefront_outlined, size: 20, color: AppColors.brandBlue),
                    const SizedBox(width: AppDimensions.space10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(outletName, style: AppTypography.titleSmall),
                          Text('Current shelf quantities', style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                itemCount: itemStocks.length,
                itemBuilder: (context, index) {
                  final stock = itemStocks[index];
                  final item = stock.item;
                  final outletQty = stock.getQuantityForOutlet(outletId);
                  final isLow = outletQty <= item.minLevel;

                  return StaggeredListItem(
                    index: index,
                    child: Padding(
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
                                Text(
                                  '${outletQty.toStringAsFixed(1)} ${item.unit.symbol}',
                                  style: AppTypography.monoMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isLow ? AppColors.lowStockAmber : AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.space8),
                            StockLevelBar(
                              currentStock: outletQty,
                              minStock: item.minLevel,
                            ),
                            const SizedBox(height: AppDimensions.space6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.category, style: AppTypography.bodySmall),
                                if (isLow)
                                  StatusBadge(
                                    label: 'Low stock',
                                    backgroundColor: AppColors.lowStockAmberLight,
                                    textColor: AppColors.lowStockAmber,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
