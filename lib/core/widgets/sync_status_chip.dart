import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../providers/app_state_providers.dart';
import '../utils/haptic_feedback_util.dart';

class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStatusProvider);

    Color dotColor;
    Color bg;
    switch (syncState) {
      case SyncState.synced:
        dotColor = AppColors.receivedGreen;
        bg = AppColors.receivedGreenLight;
        break;
      case SyncState.syncing:
        dotColor = AppColors.lowStockAmber;
        bg = AppColors.lowStockAmberLight;
        break;
      case SyncState.offline:
        dotColor = AppColors.textMuted;
        bg = AppColors.surfaceMuted;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        onTap: () {
          HapticUtil.light();
          ref.read(syncStatusProvider.notifier).simulateSync();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space8,
            vertical: AppDimensions.space4,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            border: Border.all(color: dotColor.withValues(alpha: 0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppDimensions.space6),
              Text(
                syncState.label,
                style: AppTypography.labelSmall.copyWith(
                  color: dotColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
