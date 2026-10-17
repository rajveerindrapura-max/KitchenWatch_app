import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/haptic_feedback_util.dart';

class OwnerShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const OwnerShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.brandBlueLight,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            HapticUtil.selection();
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.brandBlue),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.inventory_2_rounded, color: AppColors.brandBlue),
              label: 'Inventory',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_horiz_rounded, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.swap_horiz_rounded, color: AppColors.transferViolet),
              label: 'Transfers',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.brandBlue),
              label: 'Activity',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.settings_rounded, color: AppColors.brandBlue),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
