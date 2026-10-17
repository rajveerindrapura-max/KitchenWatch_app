import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenwatch/core/theme/app_theme.dart';
import 'package:kitchenwatch/features/dashboard/presentation/owner_dashboard_screen.dart';

void main() {
  testWidgets('Owner dashboard renders stat cards and sections cleanly', (tester) async {
    // Set a phone screen resolution
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OwnerDashboardScreen(),
        ),
      ),
    );

    // Initial pump
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // Verify Dashboard top branding and stat cards
    expect(find.text('KitchenWatch'), findsOneWidget);
    expect(find.text('Total Stock Value'), findsOneWidget);
    expect(find.text('Tracked Items'), findsOneWidget);
    expect(find.text('Low-Stock Alerts'), findsOneWidget);

    // Verify Attention Needed section
    expect(find.text('Attention Needed Today'), findsOneWidget);

    // Verify Floating Record Stock action button
    expect(find.text('Record stock'), findsOneWidget);
  });
}
