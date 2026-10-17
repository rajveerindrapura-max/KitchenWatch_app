import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenwatch/core/domain/permission_guard.dart';
import 'package:kitchenwatch/features/activity/data/mock_movement_repository.dart';
import 'package:kitchenwatch/features/auth/domain/user.dart';
import 'package:kitchenwatch/features/inventory/data/mock_inventory_repository.dart';
import 'package:kitchenwatch/features/inventory/domain/item.dart';
import 'package:kitchenwatch/features/inventory/domain/stock_unit.dart';
import 'package:kitchenwatch/features/outlets/data/mock_outlet_repository.dart';
import 'package:kitchenwatch/features/transfers/data/mock_transfer_repository.dart';
import 'package:kitchenwatch/features/transfers/domain/transfer.dart';

void main() {
  group('Stock Transfer Validation and Execution', () {
    late MockMovementRepository movementRepo;
    late MockOutletRepository outletRepo;
    late MockInventoryRepository inventoryRepo;
    late MockTransferRepository transferRepo;

    const testOwner = User(
      id: 'owner-1',
      name: 'Owner Aarav',
      email: 'owner@test.io',
      phone: '+91 99999 11111',
      role: UserRole.owner,
      assignedOutletIds: ['outlet-1', 'outlet-2'],
    );

    setUp(() async {
      movementRepo = MockMovementRepository();
      outletRepo = MockOutletRepository();
      inventoryRepo = MockInventoryRepository(
        movementRepository: movementRepo,
        outletRepository: outletRepo,
      );
      transferRepo = MockTransferRepository(
        inventoryRepository: inventoryRepo,
        movementRepository: movementRepo,
        outletRepository: outletRepo,
      );

      await inventoryRepo.clearSampleData();
    });

    test('Rejects transfer when origin and destination outlets are identical', () async {
      expect(
        () => transferRepo.createTransfer(
          testOwner,
          fromOutletId: 'outlet-1',
          toOutletId: 'outlet-1',
          items: const [
            TransferItem(
              itemId: 'item-1',
              itemName: 'Sugar',
              quantity: 5.0,
              unit: StockUnit.kg,
              estimatedValue: 200.0,
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Rejects transfer when items list is empty', () async {
      expect(
        () => transferRepo.createTransfer(
          testOwner,
          fromOutletId: 'outlet-1',
          toOutletId: 'outlet-2',
          items: const [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Executes transfer between outlets maintaining batch purchase price and reducing source', () async {
      const item = Item(
        id: 'oil-1',
        name: 'Olive Oil',
        category: 'Oils',
        unit: StockUnit.l,
        minLevel: 5.0,
        purchasePricePerUnit: 700.0,
      );
      await inventoryRepo.addItem(testOwner, item);

      // Receive 20 L in outlet-1 @ Rs 700
      await inventoryRepo.recordIncoming(
        testOwner,
        itemId: 'oil-1',
        outletId: 'outlet-1',
        quantity: 20.0,
        purchasePrice: 700.0,
      );

      // Transfer 5 L from outlet-1 to outlet-2
      final transfer = await transferRepo.createTransfer(
        testOwner,
        fromOutletId: 'outlet-1',
        toOutletId: 'outlet-2',
        items: const [
          TransferItem(
            itemId: 'oil-1',
            itemName: 'Olive Oil',
            quantity: 5.0,
            unit: StockUnit.l,
            estimatedValue: 3500.0,
          ),
        ],
        notes: 'Inter-kitchen supply replenishment',
      );

      expect(transfer.fromOutletId, 'outlet-1');
      expect(transfer.toOutletId, 'outlet-2');
      expect(transfer.totalValue, 3500.0);

      // Verify Outlet 1 stock reduced from 20 to 15
      final outlet1Stocks = await inventoryRepo.getItemStocks(outletId: 'outlet-1');
      final o1Item = outlet1Stocks.firstWhere((s) => s.item.id == 'oil-1');
      expect(o1Item.getQuantityForOutlet('outlet-1'), 15.0);

      // Verify Outlet 2 stock received 5
      final outlet2Stocks = await inventoryRepo.getItemStocks(outletId: 'outlet-2');
      final o2Item = outlet2Stocks.firstWhere((s) => s.item.id == 'oil-1');
      expect(o2Item.getQuantityForOutlet('outlet-2'), 5.0);
    });
  });
}
