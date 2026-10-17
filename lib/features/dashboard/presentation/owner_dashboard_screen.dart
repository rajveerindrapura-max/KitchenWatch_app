import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/domain/permission_guard.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/outlet_switcher.dart';
import '../../../core/widgets/sample_data_badge.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/staggered_list.dart';
import '../../../core/widgets/sync_status_chip.dart';
import 'widgets/attention_needed_section.dart';
import 'widgets/expiring_soon_section.dart';
import 'widgets/recent_ledger_section.dart';
import 'widgets/stat_cards_row.dart';
import 'widgets/wastage_chart_card.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final itemStocksAsync = ref.watch(itemStocksProvider);
    final movementsAsync = ref.watch(movementsProvider);
    final outletsAsync = ref.watch(outletsProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);

    final user = userAsync.value;
    final itemStocks = itemStocksAsync.value ?? [];
    final movements = movementsAsync.value ?? [];
    final outlets = outletsAsync.value ?? [];

    if (user == null || itemStocksAsync.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('KitchenWatch')),
        body: const Padding(
          padding: EdgeInsets.all(AppDimensions.space16),
          child: Column(
            children: [
              SkeletonLoader(width: double.infinity, height: 120),
              SizedBox(height: AppDimensions.space16),
              SkeletonLoader(width: double.infinity, height: 200),
            ],
          ),
        ),
      );
    }

    final canViewValuation = PermissionGuard.canViewStockValue(user.role);
    final totalStockValue = itemStocks.fold(0.0, (sum, s) => sum + s.totalValue);
    final lowStockItems = itemStocks.where((s) => s.isLowStock).toList();
    final expiringItems = itemStocks.where((s) => s.isExpiringSoon).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text('KitchenWatch', style: AppTypography.titleLarge),
            const SizedBox(width: AppDimensions.space8),
            if (isDemoMode) const SampleDataBadge(),
          ],
        ),
        actions: const [
          SyncStatusChip(),
          SizedBox(width: AppDimensions.space12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticUtil.medium();
          context.push('/record-stock');
        },
        backgroundColor: AppColors.brandBlue,
        foregroundColor: AppColors.textInverse,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text('Record stock', style: AppTypography.labelLarge.copyWith(color: AppColors.textInverse)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brandBlue,
          onRefresh: () async {
            await ref.read(syncStatusProvider.notifier).simulateSync();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space12,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > 720;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Outlet Switcher Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const OutletSwitcher(),
                        Text(
                          '${outlets.length} active outlets',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    // Top Stat Cards with count up animations
                    StaggeredListItem(
                      index: 0,
                      child: StatCardsRow(
                        totalStockValue: totalStockValue,
                        totalItemsCount: itemStocks.length,
                        lowStockCount: lowStockItems.length,
                        showValuation: canViewValuation,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space20),

                    if (isTablet)
                      // Two column layout on tablets
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                StaggeredListItem(
                                  index: 1,
                                  child: AttentionNeededSection(lowStockItems: lowStockItems),
                                ),
                                const SizedBox(height: AppDimensions.space20),
                                StaggeredListItem(
                                  index: 2,
                                  child: ExpiringSoonSection(expiringItems: expiringItems),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space16),
                          Expanded(
                            child: Column(
                              children: [
                                StaggeredListItem(
                                  index: 3,
                                  child: WastageChartCard(
                                    movements: movements,
                                    outlets: outlets,
                                    showValuation: canViewValuation,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.space20),
                                StaggeredListItem(
                                  index: 4,
                                  child: RecentLedgerSection(
                                    movements: movements,
                                    showValuation: canViewValuation,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      // Phone single column layout
                      Column(
                        children: [
                          StaggeredListItem(
                            index: 1,
                            child: AttentionNeededSection(lowStockItems: lowStockItems),
                          ),
                          const SizedBox(height: AppDimensions.space20),
                          StaggeredListItem(
                            index: 2,
                            child: ExpiringSoonSection(expiringItems: expiringItems),
                          ),
                          const SizedBox(height: AppDimensions.space20),
                          StaggeredListItem(
                            index: 3,
                            child: WastageChartCard(
                              movements: movements,
                              outlets: outlets,
                              showValuation: canViewValuation,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space20),
                          StaggeredListItem(
                            index: 4,
                            child: RecentLedgerSection(
                              movements: movements,
                              showValuation: canViewValuation,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppDimensions.space40),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
