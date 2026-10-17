import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/haptic_feedback_util.dart';

class EmployeeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const EmployeeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
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
                  icon: Icon(Icons.bolt_outlined, color: AppColors.textMuted),
                  selectedIcon: Icon(Icons.bolt_rounded, color: AppColors.brandBlue),
                  label: AppStrings.navQuickUpdate,
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined, color: AppColors.textMuted),
                  selectedIcon: Icon(Icons.inventory_2_rounded, color: AppColors.brandBlue),
                  label: AppStrings.navMyOutletStock,
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined, color: AppColors.textMuted),
                  selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.brandBlue),
                  label: AppStrings.navMyActivity,
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined, color: AppColors.textMuted),
                  selectedIcon: Icon(Icons.settings_rounded, color: AppColors.brandBlue),
                  label: AppStrings.navSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
