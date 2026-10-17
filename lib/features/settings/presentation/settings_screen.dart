import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/data/sample_data.dart';
import '../../../core/domain/permission_guard.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/sample_data_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/success_animation_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text('Settings', style: AppTypography.titleLarge),
            const SizedBox(width: AppDimensions.space8),
            if (isDemoMode) const SampleDataBadge(),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          children: [
            // User Profile Card
            AppCard(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.brandBlueLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: AppTypography.titleLarge.copyWith(color: AppColors.brandBlue),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: AppTypography.titleMedium),
                        Text(user.email, style: AppTypography.bodySmall),
                        const SizedBox(height: AppDimensions.space4),
                        StatusBadge(
                          label: user.role.displayName,
                          backgroundColor: user.isOwner ? AppColors.brandBlueLight : AppColors.surfaceMuted,
                          textColor: user.isOwner ? AppColors.brandBlue : AppColors.textDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Demo Role Switcher
            AppCard(
              padding: const EdgeInsets.all(AppDimensions.space16),
              color: AppColors.surfaceMuted,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Switch Active Role', style: AppTypography.titleSmall),
                      const SampleDataBadge(),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text('Experience the app from different permissions', style: AppTypography.bodySmall),
                  const SizedBox(height: AppDimensions.space12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: user.isOwner ? AppColors.brandBlue : AppColors.surface,
                            foregroundColor: user.isOwner ? AppColors.textInverse : AppColors.textDark,
                          ),
                          onPressed: () => _switchRole(ref, context, UserRole.owner),
                          child: const Text('Owner'),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: user.isManager ? AppColors.brandBlue : AppColors.surface,
                            foregroundColor: user.isManager ? AppColors.textInverse : AppColors.textDark,
                          ),
                          onPressed: () => _switchRole(ref, context, UserRole.manager),
                          child: const Text('Manager'),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: user.isEmployee ? AppColors.brandBlue : AppColors.surface,
                            foregroundColor: user.isEmployee ? AppColors.textInverse : AppColors.textDark,
                          ),
                          onPressed: () => _switchRole(ref, context, UserRole.employee),
                          child: const Text('Employee'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Owner Management Links
            if (user.isOwner) ...[
              Text('Organization', style: AppTypography.titleSmall),
              const SizedBox(height: AppDimensions.space8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.storefront_outlined, color: AppColors.brandBlue),
                      title: const Text('Outlets'),
                      subtitle: const Text('Manage locations and addresses'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        HapticUtil.light();
                        context.push('/outlets');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.group_outlined, color: AppColors.brandBlue),
                      title: const Text('Team & Permissions'),
                      subtitle: const Text('Invite and assign roles'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        HapticUtil.light();
                        context.push('/team');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space16),
            ],

            // Preferences Card
            Text('Preferences', style: AppTypography.titleSmall),
            const SizedBox(height: AppDimensions.space8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.currency_rupee_rounded, color: AppColors.textDark),
                    title: Text('Currency Format'),
                    subtitle: Text('Indian numbering: \u20B9 4,82,500'),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.scale_outlined, color: AppColors.textDark),
                    title: Text('Measurement Units'),
                    subtitle: Text('kg, g, L, ml, packets, bags, tins, pieces'),
                  ),
                  const Divider(),
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.dataset_outlined, color: AppColors.textDark),
                    title: const Text('Seeded Demo Mode'),
                    subtitle: const Text('Clearly labeled Sample data'),
                    value: isDemoMode,
                    activeTrackColor: AppColors.brandBlue,
                    onChanged: (val) async {
                      HapticUtil.selection();
                      ref.read(isDemoModeProvider.notifier).setDemoMode(val);
                      final inventory = ref.read(inventoryRepositoryProvider);
                      if (val) {
                        await inventory.resetDemoData();
                      } else {
                        await inventory.clearSampleData();
                      }
                      if (context.mounted) {
                        await SuccessAnimationDialog.show(
                          context,
                          title: val ? 'Sample data restored' : 'Sample data cleared',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space20),

            // About Card
            AppCard(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.appName, style: AppTypography.titleSmall),
                  const SizedBox(height: AppDimensions.space4),
                  Text(AppStrings.tagline, style: AppTypography.bodySmall),
                  const SizedBox(height: AppDimensions.space8),
                  Text('Version 1.0.0 (Inventory Only)', style: AppTypography.labelSmall),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space20),

            // Sign Out
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.wastageRose,
                side: const BorderSide(color: AppColors.wastageRose, width: 1),
              ),
              onPressed: () async {
                HapticUtil.light();
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) {
                  context.go('/sign-in');
                }
              },
              child: const Text('Sign out'),
            ),
            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }

  void _switchRole(WidgetRef ref, BuildContext context, UserRole role) async {
    HapticUtil.light();
    final authRepo = ref.read(authRepositoryProvider);
    final user = SampleData.initialUsers.firstWhere((u) => u.role == role);
    await authRepo.switchUser(user);

    if (context.mounted) {
      if (role == UserRole.employee) {
        context.go('/quick-update');
      } else {
        context.go('/dashboard');
      }
    }
  }
}
