import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenwatch/core/domain/permission_guard.dart';

void main() {
  group('PermissionGuard unit tests', () {
    test('Owner has full permissions across all operations', () {
      const role = UserRole.owner;

      expect(PermissionGuard.canViewStockValue(role), isTrue);
      expect(PermissionGuard.canAddItem(role), isTrue);
      expect(PermissionGuard.canEditMinStock(role), isTrue);
      expect(PermissionGuard.canRecordIncoming(role), isTrue);
      expect(PermissionGuard.canRecordAdjustment(role), isTrue);
      expect(PermissionGuard.canTransfer(role), isTrue);
      expect(PermissionGuard.canRecordUsageAndWaste(role), isTrue);
      expect(PermissionGuard.canManageOutlets(role), isTrue);
      expect(PermissionGuard.canManageTeam(role), isTrue);

      expect(() => PermissionGuard.verifyViewStockValue(role), returnsNormally);
      expect(() => PermissionGuard.verifyAddItem(role), returnsNormally);
      expect(() => PermissionGuard.verifyEditMinStock(role), returnsNormally);
      expect(() => PermissionGuard.verifyRecordIncoming(role), returnsNormally);
      expect(() => PermissionGuard.verifyRecordAdjustment(role), returnsNormally);
      expect(() => PermissionGuard.verifyTransfer(role), returnsNormally);
      expect(() => PermissionGuard.verifyManageOutlets(role), returnsNormally);
      expect(() => PermissionGuard.verifyManageTeam(role), returnsNormally);
    });

    test('Manager has operational permissions but cannot manage team or outlets', () {
      const role = UserRole.manager;

      expect(PermissionGuard.canViewStockValue(role), isTrue);
      expect(PermissionGuard.canAddItem(role), isTrue);
      expect(PermissionGuard.canEditMinStock(role), isTrue);
      expect(PermissionGuard.canRecordIncoming(role), isTrue);
      expect(PermissionGuard.canRecordAdjustment(role), isTrue);
      expect(PermissionGuard.canTransfer(role), isTrue);
      expect(PermissionGuard.canRecordUsageAndWaste(role), isTrue);

      expect(PermissionGuard.canManageOutlets(role), isFalse);
      expect(PermissionGuard.canManageTeam(role), isFalse);

      expect(() => PermissionGuard.verifyManageOutlets(role),
          throwsA(isA<PermissionDeniedException>()));
      expect(() => PermissionGuard.verifyManageTeam(role),
          throwsA(isA<PermissionDeniedException>()));
    });

    test('Employee can ONLY record usage and wastage and is blocked from valuation and item creation', () {
      const role = UserRole.employee;

      // Allowed
      expect(PermissionGuard.canRecordUsageAndWaste(role), isTrue);

      // Strictly Forbidden for employee
      expect(PermissionGuard.canViewStockValue(role), isFalse);
      expect(PermissionGuard.canAddItem(role), isFalse);
      expect(PermissionGuard.canEditMinStock(role), isFalse);
      expect(PermissionGuard.canRecordIncoming(role), isFalse);
      expect(PermissionGuard.canRecordAdjustment(role), isFalse);
      expect(PermissionGuard.canTransfer(role), isFalse);
      expect(PermissionGuard.canManageOutlets(role), isFalse);
      expect(PermissionGuard.canManageTeam(role), isFalse);

      expect(() => PermissionGuard.verifyViewStockValue(role),
          throwsA(isA<PermissionDeniedException>()));
      expect(() => PermissionGuard.verifyAddItem(role),
          throwsA(isA<PermissionDeniedException>()));
      expect(() => PermissionGuard.verifyEditMinStock(role),
          throwsA(isA<PermissionDeniedException>()));
      expect(() => PermissionGuard.verifyRecordIncoming(role),
          throwsA(isA<PermissionDeniedException>()));
      expect(() => PermissionGuard.verifyRecordAdjustment(role),
          throwsA(isA<PermissionDeniedException>()));
      expect(() => PermissionGuard.verifyTransfer(role),
          throwsA(isA<PermissionDeniedException>()));
    });
  });
}
