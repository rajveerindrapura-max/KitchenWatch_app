import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/domain/permission_guard.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/outlet_switcher.dart';
import '../../../core/widgets/sample_data_badge.dart';
import '../../../core/widgets/staggered_list.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/movement.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  MovementType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final movementsAsync = ref.watch(movementsProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);

    final user = userAsync.value;
    final movements = movementsAsync.value ?? [];

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final canViewValuation = PermissionGuard.canViewStockValue(user.role);

    final filteredMovements = _selectedType == null
        ? movements
        : movements.where((m) => m.type == _selectedType).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text('Activity Ledger', style: AppTypography.titleLarge),
            const SizedBox(width: AppDimensions.space8),
            if (isDemoMode) const SampleDataBadge(),
          ],
        ),
        actions: const [
          OutletSwitcher(),
          SizedBox(width: AppDimensions.space12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills Row
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: 4),
                children: [
                  FilterChip(
                    selected: _selectedType == null,
                    showCheckmark: false,
                    label: const Text('All activity'),
                    selectedColor: AppColors.brandBlueLight,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: _selectedType == null ? AppColors.brandBlue : AppColors.border,
                    ),
                    onSelected: (_) {
                      HapticUtil.selection();
                      setState(() => _selectedType = null);
                    },
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  ...MovementType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppDimensions.space8),
                      child: FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        label: Text(type.displayName),
                        selectedColor: _getTypeColorLight(type),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: isSelected ? _getTypeColor(type) : AppColors.border,
                        ),
                        onSelected: (_) {
                          HapticUtil.selection();
                          setState(() => _selectedType = type);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${filteredMovements.length} logged entries', style: AppTypography.bodySmall),
                  if (_selectedType == MovementType.wasted)
                    Text('Spotting unusual wastage', style: AppTypography.labelSmall.copyWith(color: AppColors.wastageRose)),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space8),

            Expanded(
              child: filteredMovements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_toggle_off_rounded, size: 40, color: AppColors.textLight),
                          const SizedBox(height: AppDimensions.space8),
                          Text('No movements matching filter', style: AppTypography.titleSmall),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      itemCount: filteredMovements.length,
                      itemBuilder: (context, index) {
                        final m = filteredMovements[index];

                        final color = _getTypeColor(m.type);
                        final lightColor = _getTypeColorLight(m.type);

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
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(AppDimensions.space8),
                                        decoration: BoxDecoration(
                                          color: lightColor,
                                          borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                                        ),
                                        child: Icon(_getTypeIcon(m.type), size: 16, color: color),
                                      ),
                                      const SizedBox(width: AppDimensions.space10),
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
                                                  backgroundColor: lightColor,
                                                  textColor: color,
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '${m.fromOutletName}${m.toOutletName != null ? ' -> ${m.toOutletName}' : ''}',
                                              style: AppTypography.bodySmall,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${_getSign(m.type)}${m.quantity.toStringAsFixed(1)} ${m.unit.symbol}',
                                            style: AppTypography.monoMedium.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: color,
                                            ),
                                          ),
                                          if (canViewValuation && m.costImpact > 0)
                                            Text(
                                              CurrencyFormatter.format(m.costImpact),
                                              style: AppTypography.monoSmall,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (m.wasteReason != null || m.note != null) ...[
                                    const SizedBox(height: AppDimensions.space8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppDimensions.space10,
                                        vertical: AppDimensions.space6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceMuted,
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            m.wasteReason != null ? Icons.info_outline : Icons.note_outlined,
                                            size: 14,
                                            color: AppColors.textMuted,
                                          ),
                                          const SizedBox(width: AppDimensions.space6),
                                          Expanded(
                                            child: Text(
                                              m.wasteReason != null
                                                  ? 'Reason: ${m.wasteReason!.displayName}'
                                                  : 'Note: ${m.note}',
                                              style: AppTypography.bodySmall.copyWith(color: AppColors.textDark),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: AppDimensions.space8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'By ${m.userName} (${m.userRole.displayName})',
                                        style: AppTypography.bodySmall,
                                      ),
                                      Text(
                                        DateFormatter.shortDateTime(m.timestamp),
                                        style: AppTypography.labelSmall,
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

  Color _getTypeColor(MovementType type) {
    switch (type) {
      case MovementType.received:
        return AppColors.receivedGreen;
      case MovementType.used:
        return AppColors.neutralTeal;
      case MovementType.wasted:
        return AppColors.wastageRose;
      case MovementType.transferred:
        return AppColors.transferViolet;
      case MovementType.adjustment:
        return AppColors.lowStockAmber;
    }
  }

  Color _getTypeColorLight(MovementType type) {
    switch (type) {
      case MovementType.received:
        return AppColors.receivedGreenLight;
      case MovementType.used:
        return AppColors.neutralTealLight;
      case MovementType.wasted:
        return AppColors.wastageRoseLight;
      case MovementType.transferred:
        return AppColors.transferVioletLight;
      case MovementType.adjustment:
        return AppColors.lowStockAmberLight;
    }
  }

  IconData _getTypeIcon(MovementType type) {
    switch (type) {
      case MovementType.received:
        return Icons.south_west_rounded;
      case MovementType.used:
        return Icons.remove_circle_outline;
      case MovementType.wasted:
        return Icons.delete_outline_rounded;
      case MovementType.transferred:
        return Icons.swap_horiz_rounded;
      case MovementType.adjustment:
        return Icons.tune_rounded;
    }
  }

  String _getSign(MovementType type) {
    switch (type) {
      case MovementType.received:
        return '+';
      case MovementType.used:
      case MovementType.wasted:
        return '-';
      case MovementType.transferred:
      case MovementType.adjustment:
        return '';
    }
  }
}
