import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../core/domain/permission_guard.dart';
import '../../activity/domain/movement.dart';
import '../../activity/domain/movement_repository.dart';
import '../../auth/domain/user.dart';
import '../../inventory/data/mock_inventory_repository.dart';
import '../../outlets/domain/outlet.dart';
import '../../outlets/domain/outlet_repository.dart';
import '../domain/transfer.dart';
import '../domain/transfer_repository.dart';

class MockTransferRepository implements TransferRepository {
  final MockInventoryRepository inventoryRepository;
  final MovementRepository movementRepository;
  final OutletRepository outletRepository;

  final List<TransferRecord> _transfers = [];
  final _controller = StreamController<List<TransferRecord>>.broadcast();

  MockTransferRepository({
    required this.inventoryRepository,
    required this.movementRepository,
    required this.outletRepository,
  });

  Future<String> _getOutletName(String outletId) async {
    final outlets = await outletRepository.getOutlets();
    final match = outlets.firstWhere(
      (o) => o.id == outletId,
      orElse: () => Outlet(id: outletId, name: 'Outlet $outletId', address: ''),
    );
    return match.name;
  }

  @override
  Future<TransferRecord> createTransfer(
    User user, {
    required String fromOutletId,
    required String toOutletId,
    required List<TransferItem> items,
    String? notes,
  }) async {
    PermissionGuard.verifyTransfer(user.role);

    if (fromOutletId == toOutletId) {
      throw ArgumentError('Origin and destination outlets cannot be identical');
    }

    if (items.isEmpty) {
      throw ArgumentError('Select at least one item to transfer');
    }

    final fromOutletName = await _getOutletName(fromOutletId);
    final toOutletName = await _getOutletName(toOutletId);

    // Apply batch transfer in inventory
    for (final item in items) {
      inventoryRepository.transferBatchesDirectly(
        itemId: item.itemId,
        fromOutletId: fromOutletId,
        toOutletId: toOutletId,
        quantity: item.quantity,
      );

      // Log movement in ledger
      await movementRepository.logMovement(
        StockMovement(
          id: 'mov-${const Uuid().v4().substring(0, 8)}',
          type: MovementType.transferred,
          itemId: item.itemId,
          itemName: item.itemName,
          fromOutletId: fromOutletId,
          fromOutletName: fromOutletName,
          toOutletId: toOutletId,
          toOutletName: toOutletName,
          quantity: item.quantity,
          unit: item.unit,
          userId: user.id,
          userName: user.name,
          userRole: user.role,
          timestamp: DateTime.now(),
          costImpact: item.estimatedValue,
          note: notes,
        ),
      );
    }

    final transferRecord = TransferRecord(
      id: 'tx-${const Uuid().v4().substring(0, 8)}',
      fromOutletId: fromOutletId,
      fromOutletName: fromOutletName,
      toOutletId: toOutletId,
      toOutletName: toOutletName,
      items: items,
      timestamp: DateTime.now(),
      initiatedByUserId: user.id,
      initiatedByUserName: user.name,
      notes: notes,
    );

    _transfers.insert(0, transferRecord);
    _controller.add(List.unmodifiable(_transfers));
    return transferRecord;
  }

  @override
  Future<List<TransferRecord>> getTransfers({String? outletId}) async {
    if (outletId == null) {
      return List.unmodifiable(_transfers);
    }
    return List.unmodifiable(
      _transfers.where((t) => t.fromOutletId == outletId || t.toOutletId == outletId),
    );
  }

  @override
  Stream<List<TransferRecord>> watchTransfers({String? outletId}) async* {
    yield await getTransfers(outletId: outletId);
    yield* _controller.stream.asyncMap((_) => getTransfers(outletId: outletId));
  }

  void dispose() {
    _controller.close();
  }
}
