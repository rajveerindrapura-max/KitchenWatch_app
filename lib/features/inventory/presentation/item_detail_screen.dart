import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/domain/permission_guard.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/stock_level_bar.dart';
import '../../outlets/domain/outlet.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final itemStocksAsync = ref.watch(itemStocksProvider);
    final outletsAsync = ref.watch(outletsProvider);
    final movementsAsync = ref.watch(movementsProvider);

    final user = userAsync.value;
    final itemStocks = itemStocksAsync.value ?? [];
    final outlets = outletsAsync.value ?? [];
    final movements = movementsAsync.value ?? [];

    final matchingStock = itemStocks.where((s) => s.item.id == itemId);
    if (matchingStock.isEmpty || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item details')),
        body: const Center(child: Text('Item not found')),
      );
    }

    final stock = matchingStock.first;
    final item = stock.item;
    final canViewValuation = PermissionGuard.canViewStockValue(user.role);
    final canEdit = PermissionGuard.canEditMinStock(user.role);
    final canTransfer = PermissionGuard.canTransfer(user.role);

    final itemMovements = movements.where((m) => m.itemId == itemId).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(item.effectiveDisplayName),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                HapticUtil.light();
                context.push('/inventory/edit/${item.id}');
              },
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space20,
          vertical: AppDimensions.space12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticUtil.light();
                  context.push('/record-stock?itemId=${item.id}');
                },
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Record stock'),
              ),
            ),
            if (canTransfer) ...[
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.transferViolet),
                  onPressed: () {
                    HapticUtil.light();
                    context.push('/transfers/new?itemId=${item.id}');
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Transfer'),
                ),
              ),
            ],
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.category, style: AppTypography.labelMedium),
                        if (stock.isLowStock)
                          const StatusBadge(
                            label: 'Low stock',
                            backgroundColor: AppColors.lowStockAmberLight,
                            textColor: AppColors.lowStockAmber,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    Text(item.effectiveDisplayName, style: AppTypography.displayMedium),
                    const SizedBox(height: AppDimensions.space12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total stock', style: AppTypography.bodySmall),
                              const SizedBox(height: AppDimensions.space2),
                              Text(
                                '${stock.totalQuantity.toStringAsFixed(1)} ${item.unit.symbol}',
                                style: AppTypography.monoLarge,
                              ),
                            ],
                          ),
                        ),
                        if (canViewValuation)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total value', style: AppTypography.bodySmall),
                                const SizedBox(height: AppDimensions.space2),
                                Text(
                                  CurrencyFormatter.format(stock.totalValue),
                                  style: AppTypography.monoLarge,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    StockLevelBar(
                      currentStock: stock.totalQuantity,
                      minStock: item.minLevel,
                      height: 8,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    const Divider(),
                    const SizedBox(height: AppDimensions.space12),
                    // Item Specifications
                    Wrap(
                      spacing: AppDimensions.space20,
                      runSpacing: AppDimensions.space10,
                      children: [
                        _SpecItem(label: 'Unit', value: item.unit.symbol),
                        _SpecItem(
                          label: 'Main packet size',
                          value: '${item.mainPacketSize.toStringAsFixed(1)} ${item.unit.symbol}',
                        ),
                        _SpecItem(
                          label: 'Safety minimum',
                          value: '${item.minLevel.toStringAsFixed(1)} ${item.unit.symbol}',
                        ),
                        if (canViewValuation)
                          _SpecItem(
                            label: 'Standard price',
                            value: '${CurrencyFormatter.format(item.purchasePricePerUnit)} / ${item.unit.symbol}',
                          ),
                        if (item.preferredVendor != null)
                          _SpecItem(label: 'Preferred vendor', value: item.preferredVendor!),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space20),

              // Stock by Outlet
              Text('Stock by Outlet', style: AppTypography.titleMedium),
              const SizedBox(height: AppDimensions.space8),
              ...outlets.map((outlet) {
                final qty = stock.getQuantityForOutlet(outlet.id);
                final val = stock.getValueForOutlet(outlet.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.space8),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(outlet.name, style: AppTypography.titleSmall),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${qty.toStringAsFixed(1)} ${item.unit.symbol}',
                              style: AppTypography.monoMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (canViewValuation)
                              Text(CurrencyFormatter.format(val), style: AppTypography.monoSmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: AppDimensions.space20),

              // Batches and FIFO Pricing
              if (canViewValuation) ...[
                Text('Purchase Batches (FIFO)', style: AppTypography.titleMedium),
                const SizedBox(height: AppDimensions.space8),
                if (stock.batches.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    child: Text('No active batches in inventory', style: AppTypography.bodyMedium),
                  )
                else
                  ...stock.batches.map((batch) {
                    final outlet = outlets.firstWhere(
                      (o) => o.id == batch.outletId,
                      orElse: () => Outlet(id: batch.outletId, name: 'Outlet', address: ''),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
                      child: AppCard(
                        padding: const EdgeInsets.all(AppDimensions.space12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(outlet.name, style: AppTypography.titleSmall),
                                Text(
                                  'Received: ${DateFormatter.shortDate(batch.receivedDate)}',
                                  style: AppTypography.bodySmall,
                                ),
                                if (batch.expiryDate != null)
                                  Text(
                                    DateFormatter.daysLeft(batch.expiryDate!),
                                    style: AppTypography.labelSmall.copyWith(
                                      color: batch.isExpired ? AppColors.wastageRose : AppColors.lowStockAmber,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${batch.quantity.toStringAsFixed(1)} ${item.unit.symbol}',
                                  style: AppTypography.monoMedium.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '@ ${CurrencyFormatter.format(batch.purchasePrice)} / ${item.unit.symbol}',
                                  style: AppTypography.monoSmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: AppDimensions.space20),
              ],

              // Item Movement History
              Text('Movement History', style: AppTypography.titleMedium),
              const SizedBox(height: AppDimensions.space8),
              if (itemMovements.isEmpty)
                AppCard(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  child: Text('No movements recorded for this item', style: AppTypography.bodyMedium),
                )
              else
                ...itemMovements.take(8).map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.space6),
                    child: AppCard(
                      padding: const EdgeInsets.all(AppDimensions.space12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  StatusBadge(
                                    label: m.type.displayName,
                                    backgroundColor: AppColors.surfaceMuted,
                                    textColor: AppColors.textDark,
                                  ),
                                  const SizedBox(width: AppDimensions.space6),
                                  Text(
                                    DateFormatter.timeAgo(m.timestamp),
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.space4),
                              Text(
                                '${m.fromOutletName} - ${m.userName}',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                          Text(
                            '${m.quantity.toStringAsFixed(1)} ${m.unit.symbol}',
                            style: AppTypography.monoMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: AppDimensions.space32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecItem extends StatelessWidget {
  final String label;
  final String value;

  const _SpecItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall),
        const SizedBox(height: AppDimensions.space2),
        Text(value, style: AppTypography.titleSmall),
      ],
    );
  }
}
