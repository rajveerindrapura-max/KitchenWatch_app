import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/sample_data_badge.dart';
import '../../../core/widgets/staggered_list.dart';
import '../../../core/widgets/success_animation_dialog.dart';
import '../../../core/widgets/sync_status_chip.dart';
import '../../inventory/domain/item_stock.dart';

class QuickUpdateScreen extends ConsumerStatefulWidget {
  const QuickUpdateScreen({super.key});

  @override
  ConsumerState<QuickUpdateScreen> createState() => _QuickUpdateScreenState();
}

class _QuickUpdateScreenState extends ConsumerState<QuickUpdateScreen> {
  // Map of itemId -> counted packets
  final Map<String, double> _packetCounts = {};
  bool _isInit = false;
  bool _isSubmitting = false;

  void _initCounts(List<ItemStock> stocks, String outletId) {
    if (_isInit) return;
    for (final s in stocks) {
      final currentUnits = s.getQuantityForOutlet(outletId);
      final packetSize = s.item.mainPacketSize > 0 ? s.item.mainPacketSize : 1.0;
      final packets = (currentUnits / packetSize).roundToDouble();
      _packetCounts[s.item.id] = packets;
    }
    _isInit = true;
  }

  void _stepCount(String itemId, double delta) {
    HapticUtil.light();
    setState(() {
      final current = _packetCounts[itemId] ?? 0.0;
      final next = (current + delta).clamp(0.0, 999.0);
      _packetCounts[itemId] = next;
    });
  }

  Future<void> _handleConfirm(String outletId) async {
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    if (user == null) return;

    setState(() => _isSubmitting = true);
    HapticUtil.medium();

    try {
      final inventoryRepo = ref.read(inventoryRepositoryProvider);
      await inventoryRepo.quickCountUpdate(
        user,
        outletId: outletId,
        packetCounts: _packetCounts,
      );

      if (mounted) {
        await SuccessAnimationDialog.show(
          context,
          title: 'Shift counts verified',
          subtitle: 'Inventory updated in seconds',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final outletName = outletMatch.isNotEmpty ? outletMatch.first.name : 'Assigned Outlet';

    _initCounts(itemStocks, outletId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text('Quick Update', style: AppTypography.titleLarge),
            const SizedBox(width: AppDimensions.space8),
            if (isDemoMode) const SampleDataBadge(),
          ],
        ),
        actions: const [
          SyncStatusChip(),
          SizedBox(width: AppDimensions.space12),
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
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : () => _handleConfirm(outletId),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textInverse),
                )
              : const Text('Confirm shift count (Done in <1 min)'),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Outlet Header Banner
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space8,
              ),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space14,
                  vertical: AppDimensions.space10,
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
                          Text('Count outer packets on shelf', style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    Text(
                      '${itemStocks.length} items',
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space8,
                ),
                itemCount: itemStocks.length,
                itemBuilder: (context, index) {
                  final stock = itemStocks[index];
                  final item = stock.item;
                  final count = _packetCounts[item.id] ?? 0.0;
                  final totalUnits = count * item.mainPacketSize;

                  return StaggeredListItem(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.space10),
                      child: AppCard(
                        padding: const EdgeInsets.all(AppDimensions.space14),
                        child: Row(
                          children: [
                            // Big Item Tile Image / Icon
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.brandBlueLight,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.brandBlue,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space12),
                            // Item info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.effectiveDisplayName,
                                    style: AppTypography.titleSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppDimensions.space2),
                                  Text(
                                    '${item.mainPacketSize.toStringAsFixed(0)} ${item.unit.symbol} / packet',
                                    style: AppTypography.bodySmall,
                                  ),
                                  const SizedBox(height: AppDimensions.space2),
                                  Text(
                                    'Total: ${totalUnits.toStringAsFixed(0)} ${item.unit.symbol}',
                                    style: AppTypography.monoSmall.copyWith(
                                      color: AppColors.brandBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Plus and Minus Steppers
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton.filledTonal(
                                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                  onPressed: () => _stepCount(item.id, -1.0),
                                  icon: const Icon(Icons.remove_rounded, size: 20),
                                ),
                                Container(
                                  constraints: const BoxConstraints(minWidth: 44),
                                  alignment: Alignment.center,
                                  child: Text(
                                    count.toInt().toString(),
                                    style: AppTypography.monoLarge.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                IconButton.filledTonal(
                                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                  onPressed: () => _stepCount(item.id, 1.0),
                                  icon: const Icon(Icons.add_rounded, size: 20),
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
