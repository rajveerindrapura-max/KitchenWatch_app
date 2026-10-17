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
import '../../auth/domain/user.dart';

final teamMembersProvider = StreamProvider<List<User>>((ref) {
  final teamRepo = ref.watch(teamRepositoryProvider);
  return teamRepo.watchTeamMembers();
});

class TeamManagementScreen extends ConsumerWidget {
  const TeamManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final teamAsync = ref.watch(teamMembersProvider);
    final outletsAsync = ref.watch(outletsProvider);

    final user = userAsync.value;
    final team = teamAsync.value ?? [];
    final outlets = outletsAsync.value ?? [];

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final canManage = PermissionGuard.canManageTeam(user.role);
    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team')),
        body: const Center(child: Text('Only owners can manage team members')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Team & Permissions'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(context, ref, user, outlets),
        backgroundColor: AppColors.brandBlue,
        foregroundColor: AppColors.textInverse,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Invite member'),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.space16),
          itemCount: team.length,
          itemBuilder: (context, index) {
            final member = team[index];

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
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: member.role == UserRole.owner
                                      ? AppColors.brandBlueLight
                                      : (member.role == UserRole.manager
                                          ? AppColors.transferVioletLight
                                          : AppColors.surfaceMuted),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    member.name.isNotEmpty ? member.name[0].toUpperCase() : 'U',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: member.role == UserRole.owner
                                          ? AppColors.brandBlue
                                          : (member.role == UserRole.manager
                                              ? AppColors.transferViolet
                                              : AppColors.textDark),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(member.name, style: AppTypography.titleSmall),
                                  Text(member.email, style: AppTypography.bodySmall),
                                ],
                              ),
                            ],
                          ),
                          StatusBadge(
                            label: member.role.displayName,
                            backgroundColor: member.role == UserRole.owner
                                ? AppColors.brandBlueLight
                                : (member.role == UserRole.manager
                                    ? AppColors.transferVioletLight
                                    : AppColors.surfaceMuted),
                            textColor: member.role == UserRole.owner
                                ? AppColors.brandBlue
                                : (member.role == UserRole.manager
                                    ? AppColors.transferViolet
                                    : AppColors.textDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space10),
                      // Assigned Outlets Chips
                      Wrap(
                        spacing: AppDimensions.space6,
                        runSpacing: AppDimensions.space6,
                        children: member.assignedOutletIds.map((outletId) {
                          final match = outlets.where((o) => o.id == outletId);
                          final name = match.isNotEmpty ? match.first.name : outletId;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                            ),
                            child: Text(name, style: AppTypography.labelSmall),
                          );
                        }).toList(),
                      ),
                      if (member.id != user.id) ...[
                        const SizedBox(height: AppDimensions.space8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: AppColors.wastageRose),
                              onPressed: () async {
                                HapticUtil.light();
                                await ref.read(teamRepositoryProvider).deactivateMember(user, member.id);
                              },
                              child: Text(member.isActive ? 'Deactivate' : 'Reactivate'),
                            ),
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

  void _showInviteDialog(BuildContext context, WidgetRef ref, User actor, List<dynamic> outlets) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    UserRole selectedRole = UserRole.employee;
    final List<String> selectedOutletIds = outlets.isNotEmpty ? [outlets.first.id as String] : [];

    showDialog(
      context: context,
      builder: (dlgContext) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              title: const Text('Invite Team Member'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full name', hintText: 'e.g. Vikas Gupta'),
                      autofocus: true,
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email address', hintText: 'name@kitchenwatch.io'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone', hintText: '+91 98765 00000'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    Text('Role permissions', style: AppTypography.titleSmall),
                    const SizedBox(height: AppDimensions.space8),
                    SegmentedButton<UserRole>(
                      segments: const [
                        ButtonSegment(value: UserRole.manager, label: Text('Manager')),
                        ButtonSegment(value: UserRole.employee, label: Text('Employee')),
                      ],
                      selected: {selectedRole},
                      onSelectionChanged: (set) {
                        setDlgState(() => selectedRole = set.first);
                      },
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    Text('Assigned outlets', style: AppTypography.titleSmall),
                    const SizedBox(height: AppDimensions.space8),
                    ...outlets.map((o) {
                      final isAssigned = selectedOutletIds.contains(o.id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(o.name as String, style: AppTypography.bodyMedium),
                        value: isAssigned,
                        onChanged: (val) {
                          setDlgState(() {
                            if (val == true) {
                              selectedOutletIds.add(o.id as String);
                            } else {
                              selectedOutletIds.remove(o.id);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;
                    Navigator.pop(dlgContext);
                    HapticUtil.medium();

                    final repo = ref.read(teamRepositoryProvider);
                    await repo.inviteMember(
                      actor,
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      role: selectedRole,
                      assignedOutletIds: selectedOutletIds,
                    );

                    if (context.mounted) {
                      await SuccessAnimationDialog.show(
                        context,
                        title: 'Invitation sent',
                        subtitle: nameCtrl.text.trim(),
                      );
                    }
                  },
                  child: const Text('Send invite'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
