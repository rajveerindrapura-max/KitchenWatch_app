import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenwatch/core/domain/permission_guard.dart';
import 'package:kitchenwatch/core/providers/app_state_providers.dart';
import 'package:kitchenwatch/core/theme/app_theme.dart';
import 'package:kitchenwatch/features/auth/domain/user.dart';
import 'package:kitchenwatch/features/quick_update/presentation/quick_update_screen.dart';

void main() {
  testWidgets('QuickUpdateScreen displays packet steppers and quick confirmation', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const testEmployee = User(
      id: 'emp-1',
      name: 'Rohan Verma',
      email: 'employee@test.io',
      phone: '+91 98765 43212',
      role: UserRole.employee,
      assignedOutletIds: ['outlet-1'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(testEmployee)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const QuickUpdateScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('Quick Update'), findsOneWidget);
    expect(find.text('Confirm shift count (Done in <1 min)'), findsOneWidget);

    // Verify plus and minus stepper icons are found
    expect(find.byIcon(Icons.add_rounded), findsWidgets);
    expect(find.byIcon(Icons.remove_rounded), findsWidgets);
  });
}
