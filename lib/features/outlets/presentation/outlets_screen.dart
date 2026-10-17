import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/domain/permission_guard.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/staggered_list.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/success_animation_dialog.dart';

class OutletsScreen extends ConsumerWidget {
  const OutletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final outletsAsync = ref.watch(outletsProvider);

    final user = userAsync.value;
    final outlets = outletsAsync.value ?? [];

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final canManage = PermissionGuard.canManageOutlets(user.role);
    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Outlets')),
        body: const Center(child: Text('Only owners can manage outlets')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Outlets'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOutletDialog(context, ref, user),
        backgroundColor: AppColors.brandBlue,
        foregroundColor: AppColors.textInverse,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add outlet'),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.space16),
          itemCount: outlets.length,
          itemBuilder: (context, index) {
            final outlet = outlets[index];

            return StaggeredListItem(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                child: AppCard(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(outlet.name, style: AppTypography.titleMedium),
                          ),
                          StatusBadge(
                            label: outlet.isActive ? 'Active' : 'Inactive',
                            backgroundColor: outlet.isActive ? AppColors.receivedGreenLight : AppColors.surfaceMuted,
                            textColor: outlet.isActive ? AppColors.receivedGreen : AppColors.textMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: AppDimensions.space6),
                          Expanded(
                            child: Text(outlet.address, style: AppTypography.bodySmall),
                          ),
                        ],
                      ),
                      if (outlet.phone.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.space4),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: AppDimensions.space6),
                            Text(outlet.phone, style: AppTypography.bodySmall),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddOutletDialog(BuildContext context, WidgetRef ref, dynamic user) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dlgContext) {
        return AlertDialog(
          title: const Text('Add New Outlet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Outlet name',
                  hintText: 'e.g. North Hub Cloud Kitchen',
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppDimensions.space12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Location or delivery sector',
                ),
              ),
              const SizedBox(height: AppDimensions.space12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact phone',
                  hintText: '+91 80 4123 4570',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(dlgContext);
                HapticUtil.medium();
                final repo = ref.read(outletRepositoryProvider);
                await repo.createOutlet(
                  user,
                  name: nameCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                );
                if (context.mounted) {
                  await SuccessAnimationDialog.show(
                    context,
                    title: 'Outlet added',
                    subtitle: nameCtrl.text.trim(),
                  );
                }
              },
              child: const Text('Add outlet'),
            ),
          ],
        );
      },
    );
  }
}
