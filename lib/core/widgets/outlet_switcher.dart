import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../domain/permission_guard.dart';
import '../providers/app_state_providers.dart';
import '../utils/haptic_feedback_util.dart';

class OutletSwitcher extends ConsumerWidget {
  const OutletSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final outletsAsync = ref.watch(outletsProvider);
    final selectedOutletId = ref.watch(selectedOutletIdProvider);

    final user = userAsync.value;
    final outlets = outletsAsync.value ?? [];

    if (user == null) return const SizedBox.shrink();

    // Determine available outlets for this user
    final availableOutlets = user.isOwner
        ? outlets
        : outlets.where((o) => user.assignedOutletIds.contains(o.id)).toList();

    // Current selection label
    String currentLabel;
    if (selectedOutletId == null) {
      currentLabel = user.isOwner ? AppStrings.allOutlets : (availableOutlets.isNotEmpty ? availableOutlets.first.name : '');
    } else {
      final match = outlets.where((o) => o.id == selectedOutletId);
      currentLabel = match.isNotEmpty ? match.first.name : AppStrings.allOutlets;
    }

    // For employees with 1 outlet, show simple static badge
    if (user.role == UserRole.employee || availableOutlets.length <= 1) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space6,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, size: 16, color: AppColors.textDark),
            const SizedBox(width: AppDimensions.space6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                currentLabel,
                style: AppTypography.labelMedium.copyWith(color: AppColors.textDark),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        onTap: () {
          HapticUtil.selection();
          _showOutletPicker(context, ref, user.isOwner, availableOutlets, selectedOutletId);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space12,
            vertical: AppDimensions.space6,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_outlined, size: 16, color: AppColors.brandBlue),
              const SizedBox(width: AppDimensions.space6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  currentLabel,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.space4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  void _showOutletPicker(
    BuildContext context,
    WidgetRef ref,
    bool isOwner,
    List<dynamic> outlets,
    String? currentSelectedId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space20,
              vertical: AppDimensions.space16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),
                Text(
                  'Switch outlet',
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: AppDimensions.space12),
                if (isOwner)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.all_inclusive_rounded, color: AppColors.brandBlue),
                    title: Text(AppStrings.allOutlets, style: AppTypography.bodyLarge),
                    trailing: currentSelectedId == null
                        ? const Icon(Icons.check_rounded, color: AppColors.brandBlue)
                        : null,
                    onTap: () {
                      ref.read(selectedOutletIdProvider.notifier).selectOutlet(null);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ...outlets.map((outlet) {
                  final isSelected = currentSelectedId == outlet.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.storefront_outlined, color: AppColors.textDark),
                    title: Text(outlet.name, style: AppTypography.bodyLarge),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded, color: AppColors.brandBlue)
                        : null,
                    onTap: () {
                      ref.read(selectedOutletIdProvider.notifier).selectOutlet(outlet.id);
                      Navigator.pop(sheetContext);
                    },
                  );
                }),
                const SizedBox(height: AppDimensions.space8),
              ],
            ),
          ),
        );
      },
    );
  }
}
