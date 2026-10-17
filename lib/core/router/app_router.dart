import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/activity/presentation/activity_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/dashboard/presentation/owner_dashboard_screen.dart';
import '../../features/inventory/presentation/add_edit_item_screen.dart';
import '../../features/inventory/presentation/inventory_list_screen.dart';
import '../../features/inventory/presentation/item_detail_screen.dart';
import '../../features/inventory/presentation/my_outlet_stock_screen.dart';
import '../../features/inventory/presentation/record_stock_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/outlets/presentation/outlets_screen.dart';
import '../../features/quick_update/presentation/quick_update_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/employee_shell.dart';
import '../../features/shell/owner_shell.dart';
import '../../features/team/presentation/team_management_screen.dart';
import '../../features/transfers/presentation/transfer_screen.dart';
import '../providers/app_state_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final userAsync = ref.watch(currentUserProvider);

  CustomTransitionPage buildPageTransition({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      return CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionsBuilder: (_, _, _, child) => child,
      );
    }
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
    );
  }

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final user = userAsync.value;
      final isAuthRoute = state.matchedLocation == '/sign-in' || state.matchedLocation == '/onboarding';

      if (user == null && !isAuthRoute) {
        return '/sign-in';
      }

      if (user != null && isAuthRoute) {
        return user.isEmployee ? '/quick-update' : '/dashboard';
      }

      // If employee tries to access owner/manager only tabs
      if (user != null && user.isEmployee) {
        final loc = state.matchedLocation;
        if (loc.startsWith('/dashboard') ||
            loc.startsWith('/transfers') ||
            loc.startsWith('/outlets') ||
            loc.startsWith('/team')) {
          return '/quick-update';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        pageBuilder: (context, state) => buildPageTransition(
          context: context,
          state: state,
          child: const SignInScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => buildPageTransition(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),

      // Standalone top level routes
      GoRoute(
        path: '/record-stock',
        pageBuilder: (context, state) {
          final itemId = state.uri.queryParameters['itemId'];
          return buildPageTransition(
            context: context,
            state: state,
            child: RecordStockScreen(initialItemId: itemId),
          );
        },
      ),
      GoRoute(
        path: '/inventory/add',
        pageBuilder: (context, state) => buildPageTransition(
          context: context,
          state: state,
          child: const AddEditItemScreen(),
        ),
      ),
      GoRoute(
        path: '/inventory/edit/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return buildPageTransition(
            context: context,
            state: state,
            child: AddEditItemScreen(itemId: id),
          );
        },
      ),
      GoRoute(
        path: '/inventory/item/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return buildPageTransition(
            context: context,
            state: state,
            child: ItemDetailScreen(itemId: id),
          );
        },
      ),
      GoRoute(
        path: '/transfers/new',
        pageBuilder: (context, state) {
          final itemId = state.uri.queryParameters['itemId'];
          final qty = state.uri.queryParameters['quantity'];
          final fromOutlet = state.uri.queryParameters['fromOutletId'];
          return buildPageTransition(
            context: context,
            state: state,
            child: TransferScreen(
              initialItemId: itemId,
              initialQuantity: qty,
              initialFromOutletId: fromOutlet,
            ),
          );
        },
      ),
      GoRoute(
        path: '/outlets',
        pageBuilder: (context, state) => buildPageTransition(
          context: context,
          state: state,
          child: const OutletsScreen(),
        ),
      ),
      GoRoute(
        path: '/team',
        pageBuilder: (context, state) => buildPageTransition(
          context: context,
          state: state,
          child: const TeamManagementScreen(),
        ),
      ),

      // Owner & Manager Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return OwnerShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                pageBuilder: (context, state) => buildPageTransition(
                  context: context,
                  state: state,
                  child: const OwnerDashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory',
                pageBuilder: (context, state) => buildPageTransition(
                  context: context,
                  state: state,
                  child: const InventoryListScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transfers',
                pageBuilder: (context, state) => buildPageTransition(
                  context: context,
                  state: state,
                  child: const TransferScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activity',
                pageBuilder: (context, state) => buildPageTransition(
                  context: context,
                  state: state,
                  child: const ActivityScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => buildPageTransition(
                  context: context,
                  state: state,
                  child: const SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Employee Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return EmployeeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quick-update',
                pageBuilder: (context, state) => buildPageTransition(
                  context: context,
                  state: state,
                  child: const QuickUpdateScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-stock',
                pageBuilder: (context, state) => buildPageTransition(
                  context: context,
                  state: state,
                  child: const MyOutletStockScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-activity',
                pageBuilder: (context, state) => buildPageTransition(
                  context: context,
                  state: state,
                  child: const ActivityScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/employee-settings',
                pageBuilder: (context, state) => buildPageTransition(
                  context: context,
                  state: state,
                  child: const SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
