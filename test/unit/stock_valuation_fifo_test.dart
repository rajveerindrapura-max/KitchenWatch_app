import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenwatch/core/domain/permission_guard.dart';
import 'package:kitchenwatch/features/activity/data/mock_movement_repository.dart';
import 'package:kitchenwatch/features/activity/domain/movement.dart';
import 'package:kitchenwatch/features/auth/domain/user.dart';
import 'package:kitchenwatch/features/inventory/data/mock_inventory_repository.dart';
import 'package:kitchenwatch/features/inventory/domain/item.dart';
import 'package:kitchenwatch/features/inventory/domain/stock_unit.dart';
import 'package:kitchenwatch/features/outlets/data/mock_outlet_repository.dart';

void main() {
  group('FIFO Stock Valuation and Movements', () {
    late MockMovementRepository movementRepo;
    late MockOutletRepository outletRepo;
    late MockInventoryRepository inventoryRepo;

    const testOwner = User(
      id: 'owner-1',
      name: 'Owner Aarav',
      email: 'owner@test.io',
      phone: '+91 99999 11111',
      role: UserRole.owner,
      assignedOutletIds: ['outlet-1', 'outlet-2'],
    );

    const testEmployee = User(
      id: 'emp-1',
      name: 'Employee Rohan',
      email: 'emp@test.io',
      phone: '+91 99999 22222',
      role: UserRole.employee,
      assignedOutletIds: ['outlet-1'],
    );

    setUp(() async {
      movementRepo = MockMovementRepository();
      outletRepo = MockOutletRepository();
      inventoryRepo = MockInventoryRepository(
        movementRepository: movementRepo,
        outletRepository: outletRepo,
      );

      // Start with clean state
      await inventoryRepo.clearSampleData();
    });

    test('FIFO deduction accurately values consumption across multiple purchase batches', () async {
      // 1. Add item
      const item = Item(
        id: 'rice-test',
        name: 'Basmati Rice',
        category: 'Grains',
        unit: StockUnit.kg,
        minLevel: 10.0,
        purchasePricePerUnit: 50.0,
      );
      await inventoryRepo.addItem(testOwner, item);

      // 2. Receive Batch A: 10 kg @ Rs 40/kg
      await inventoryRepo.recordIncoming(
        testOwner,
        itemId: 'rice-test',
        outletId: 'outlet-1',
        quantity: 10.0,
        purchasePrice: 40.0,
      );

      // 3. Receive Batch B: 10 kg @ Rs 60/kg
      await inventoryRepo.recordIncoming(
        testOwner,
        itemId: 'rice-test',
        outletId: 'outlet-1',
        quantity: 10.0,
        purchasePrice: 60.0,
      );

      // Initial state verification: total 20 kg, value = (10*40) + (10*60) = 1000
      var stocks = await inventoryRepo.getItemStocks(outletId: 'outlet-1');
      var riceStock = stocks.firstWhere((s) => s.item.id == 'rice-test');
      expect(riceStock.totalQuantity, 20.0);
      expect(riceStock.totalValue, 1000.0);

      // 4. Employee records usage of 12 kg
      // FIFO expects:
      // First 10 kg from Batch A @ Rs 40 = Rs 400
      // Next 2 kg from Batch B @ Rs 60 = Rs 120
      // Total cost impact = Rs 520
      final movement = await inventoryRepo.recordUsage(
        testEmployee,
        itemId: 'rice-test',
        outletId: 'outlet-1',
        quantity: 12.0,
      );

      expect(movement.costImpact, 520.0);
      expect(movement.type, MovementType.used);

      // 5. Verify remaining inventory state:
      // Batch A is depleted (0 kg).
      // Batch B has 8 kg remaining @ Rs 60 = Rs 480.
      stocks = await inventoryRepo.getItemStocks(outletId: 'outlet-1');
      riceStock = stocks.firstWhere((s) => s.item.id == 'rice-test');

      expect(riceStock.totalQuantity, 8.0);
      expect(riceStock.totalValue, 480.0);
      expect(riceStock.isLowStock, isTrue); // 8 kg is below minLevel of 10 kg
    });

    test('Wastage logs correct reason and deducts via FIFO', () async {
      const item = Item(
        id: 'milk-test',
        name: 'Full Cream Milk',
        category: 'Dairy',
        unit: StockUnit.l,
        minLevel: 5.0,
        purchasePricePerUnit: 60.0,
      );
      await inventoryRepo.addItem(testOwner, item);

      await inventoryRepo.recordIncoming(
        testOwner,
        itemId: 'milk-test',
        outletId: 'outlet-1',
        quantity: 15.0,
        purchasePrice: 60.0,
      );

      final wasteMovement = await inventoryRepo.recordWastage(
        testEmployee,
        itemId: 'milk-test',
        outletId: 'outlet-1',
        quantity: 3.0,
        reason: WasteReason.spoilage,
      );

      expect(wasteMovement.type, MovementType.wasted);
      expect(wasteMovement.wasteReason, WasteReason.spoilage);
      expect(wasteMovement.costImpact, 180.0);

      final stocks = await inventoryRepo.getItemStocks(outletId: 'outlet-1');
      expect(stocks.firstWhere((s) => s.item.id == 'milk-test').totalQuantity, 12.0);
    });

    test('Adjustment requires mandatory note and updates stock balance', () async {
      const item = Item(
        id: 'flour-test',
        name: 'Maida',
        category: 'Grains',
        unit: StockUnit.kg,
        minLevel: 5.0,
        purchasePricePerUnit: 40.0,
      );
      await inventoryRepo.addItem(testOwner, item);

      await inventoryRepo.recordIncoming(
        testOwner,
        itemId: 'flour-test',
        outletId: 'outlet-1',
        quantity: 20.0,
        purchasePrice: 40.0,
      );

      // Fails when note is empty
      expect(
        () => inventoryRepo.recordAdjustment(
          testOwner,
          itemId: 'flour-test',
          outletId: 'outlet-1',
          newQuantity: 18.0,
          note: '   ',
        ),
        throwsA(isA<FormatException>()),
      );

      // Succeeds with valid audit note
      final adj = await inventoryRepo.recordAdjustment(
        testOwner,
        itemId: 'flour-test',
        outletId: 'outlet-1',
        newQuantity: 18.0,
        note: 'Quarterly physical scale audit',
      );

      expect(adj.type, MovementType.adjustment);
      expect(adj.note, 'Quarterly physical scale audit');

      final stocks = await inventoryRepo.getItemStocks(outletId: 'outlet-1');
      expect(stocks.firstWhere((s) => s.item.id == 'flour-test').totalQuantity, 18.0);
    });
  });
}
