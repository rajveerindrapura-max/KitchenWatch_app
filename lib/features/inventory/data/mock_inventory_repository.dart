import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../core/data/sample_data.dart';
import '../../../core/domain/permission_guard.dart';
import '../../activity/domain/movement.dart';
import '../../activity/domain/movement_repository.dart';
import '../../auth/domain/user.dart';
import '../../outlets/domain/outlet.dart';
import '../../outlets/domain/outlet_repository.dart';
import '../domain/inventory_repository.dart';
import '../domain/item.dart';
import '../domain/item_stock.dart';
import '../domain/stock_batch.dart';

class MockInventoryRepository implements InventoryRepository {
  final MovementRepository movementRepository;
  final OutletRepository outletRepository;

  final List<Item> _items = List.from(SampleData.initialItems);
  final List<StockBatch> _batches = List.from(SampleData.generateInitialBatches());
  final _controller = StreamController<List<ItemStock>>.broadcast();

  MockInventoryRepository({
    required this.movementRepository,
    required this.outletRepository,
  });

  @override
  Future<List<Item>> getItems() async {
    return List.unmodifiable(_items);
  }

  @override
  Future<Item> addItem(User user, Item item) async {
    PermissionGuard.verifyAddItem(user.role);

    final newItem = item.id.isEmpty
        ? item.copyWith(id: 'item-${const Uuid().v4().substring(0, 8)}')
        : item;

    _items.add(newItem);
    _notifyChanges();
    return newItem;
  }

  @override
  Future<void> updateItem(User user, Item item) async {
    PermissionGuard.verifyEditMinStock(user.role);

    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      _notifyChanges();
    }
  }

  @override
  Future<void> deleteItem(User user, String itemId) async {
    PermissionGuard.verifyAddItem(user.role);

    _items.removeWhere((i) => i.id == itemId);
    _batches.removeWhere((b) => b.itemId == itemId);
    _notifyChanges();
  }

  @override
  Future<List<StockBatch>> getBatches({String? outletId, String? itemId}) async {
    var result = List<StockBatch>.from(_batches);
    if (outletId != null) {
      result = result.where((b) => b.outletId == outletId).toList();
    }
    if (itemId != null) {
      result = result.where((b) => b.itemId == itemId).toList();
    }
    return List.unmodifiable(result);
  }

  @override
  Future<List<ItemStock>> getItemStocks({String? outletId}) async {
    return _computeItemStocks(outletId: outletId);
  }

  List<ItemStock> _computeItemStocks({String? outletId}) {
    return _items.map((item) {
      final relevantBatches = _batches.where((b) {
        if (b.itemId != item.id || b.quantity <= 0) return false;
        if (outletId != null && b.outletId != outletId) return false;
        return true;
      }).toList();

      relevantBatches.sort((a, b) => a.receivedDate.compareTo(b.receivedDate));

      return ItemStock(item: item, batches: relevantBatches);
    }).toList();
  }

  @override
  Stream<List<ItemStock>> watchItemStocks({String? outletId}) async* {
    yield _computeItemStocks(outletId: outletId);
    yield* _controller.stream.map((_) => _computeItemStocks(outletId: outletId));
  }

  // FIFO Stock deduction engine
  double _deductStockFIFO(String itemId, String outletId, double quantityToDeduct) {
    double remaining = quantityToDeduct;
    double totalCostImpact = 0.0;

    final matchingIndices = <int>[];
    for (int i = 0; i < _batches.length; i++) {
      if (_batches[i].itemId == itemId &&
          _batches[i].outletId == outletId &&
          _batches[i].quantity > 0) {
        matchingIndices.add(i);
      }
    }

    matchingIndices.sort((a, b) => _batches[a].receivedDate.compareTo(_batches[b].receivedDate));

    for (final index in matchingIndices) {
      if (remaining <= 0) break;
      final currentBatch = _batches[index];
      final toTake = currentBatch.quantity <= remaining ? currentBatch.quantity : remaining;

      totalCostImpact += toTake * currentBatch.purchasePrice;
      remaining -= toTake;

      _batches[index] = currentBatch.copyWith(
        quantity: currentBatch.quantity - toTake,
      );
    }

    // Clean up empty batches
    _batches.removeWhere((b) => b.quantity <= 0);

    // If remaining > 0 (deficit), calculate cost using default item price
    if (remaining > 0) {
      final item = _items.firstWhere((i) => i.id == itemId);
      totalCostImpact += remaining * item.purchasePricePerUnit;
    }

    return totalCostImpact;
  }

  Future<String> _getOutletName(String outletId) async {
    final outlets = await outletRepository.getOutlets();
    final match = outlets.firstWhere(
      (o) => o.id == outletId,
      orElse: () => Outlet(id: outletId, name: 'Outlet $outletId', address: ''),
    );
    return match.name;
  }

  @override
  Future<StockMovement> recordIncoming(
    User user, {
    required String itemId,
    required String outletId,
    required double quantity,
    required double purchasePrice,
    DateTime? expiryDate,
  }) async {
    PermissionGuard.verifyRecordIncoming(user.role);
    if (!user.canAccessOutlet(outletId)) {
      throw const PermissionDeniedException('Not authorized for this outlet');
    }

    final item = _items.firstWhere((i) => i.id == itemId);
    final outletName = await _getOutletName(outletId);

    final newBatch = StockBatch(
      batchId: 'batch-${const Uuid().v4().substring(0, 8)}',
      itemId: itemId,
      outletId: outletId,
      quantity: quantity,
      purchasePrice: purchasePrice,
      receivedDate: DateTime.now(),
      expiryDate: expiryDate,
    );

    _batches.add(newBatch);

    final movement = StockMovement(
      id: 'mov-${const Uuid().v4().substring(0, 8)}',
      type: MovementType.received,
      itemId: itemId,
      itemName: item.effectiveDisplayName,
      fromOutletId: outletId,
      fromOutletName: outletName,
      quantity: quantity,
      unit: item.unit,
      userId: user.id,
      userName: user.name,
      userRole: user.role,
      timestamp: DateTime.now(),
      costImpact: quantity * purchasePrice,
    );

    await movementRepository.logMovement(movement);
    _notifyChanges();
    return movement;
  }

  @override
  Future<StockMovement> recordUsage(
    User user, {
    required String itemId,
    required String outletId,
    required double quantity,
  }) async {
    if (!user.canAccessOutlet(outletId)) {
      throw const PermissionDeniedException('Not authorized for this outlet');
    }

    final item = _items.firstWhere((i) => i.id == itemId);
    final outletName = await _getOutletName(outletId);
    final costImpact = _deductStockFIFO(itemId, outletId, quantity);

    final movement = StockMovement(
      id: 'mov-${const Uuid().v4().substring(0, 8)}',
      type: MovementType.used,
      itemId: itemId,
      itemName: item.effectiveDisplayName,
      fromOutletId: outletId,
      fromOutletName: outletName,
      quantity: quantity,
      unit: item.unit,
      userId: user.id,
      userName: user.name,
      userRole: user.role,
      timestamp: DateTime.now(),
      costImpact: costImpact,
    );

    await movementRepository.logMovement(movement);
    _notifyChanges();
    return movement;
  }

  @override
  Future<StockMovement> recordWastage(
    User user, {
    required String itemId,
    required String outletId,
    required double quantity,
    required WasteReason reason,
  }) async {
    if (!user.canAccessOutlet(outletId)) {
      throw const PermissionDeniedException('Not authorized for this outlet');
    }

    final item = _items.firstWhere((i) => i.id == itemId);
    final outletName = await _getOutletName(outletId);
    final costImpact = _deductStockFIFO(itemId, outletId, quantity);

    final movement = StockMovement(
      id: 'mov-${const Uuid().v4().substring(0, 8)}',
      type: MovementType.wasted,
      itemId: itemId,
      itemName: item.effectiveDisplayName,
      fromOutletId: outletId,
      fromOutletName: outletName,
      quantity: quantity,
      unit: item.unit,
      userId: user.id,
      userName: user.name,
      userRole: user.role,
      timestamp: DateTime.now(),
      wasteReason: reason,
      costImpact: costImpact,
    );

    await movementRepository.logMovement(movement);
    _notifyChanges();
    return movement;
  }

  @override
  Future<StockMovement> recordAdjustment(
    User user, {
    required String itemId,
    required String outletId,
    required double newQuantity,
    required String note,
  }) async {
    PermissionGuard.verifyRecordAdjustment(user.role);
    if (!user.canAccessOutlet(outletId)) {
      throw const PermissionDeniedException('Not authorized for this outlet');
    }
    if (note.trim().isEmpty) {
      throw const FormatException('Adjustment note is required');
    }

    final item = _items.firstWhere((i) => i.id == itemId);
    final outletName = await _getOutletName(outletId);

    // Current quantity for this item in outlet
    final currentBatches = _batches.where((b) => b.itemId == itemId && b.outletId == outletId);
    final currentQuantity = currentBatches.fold(0.0, (sum, b) => sum + b.quantity);
    final difference = newQuantity - currentQuantity;

    double costImpact = 0.0;
    if (difference > 0) {
      // Stock increased
      costImpact = difference * item.purchasePricePerUnit;
      _batches.add(StockBatch(
        batchId: 'batch-${const Uuid().v4().substring(0, 8)}',
        itemId: itemId,
        outletId: outletId,
        quantity: difference,
        purchasePrice: item.purchasePricePerUnit,
        receivedDate: DateTime.now(),
      ));
    } else if (difference < 0) {
      // Stock decreased
      costImpact = _deductStockFIFO(itemId, outletId, difference.abs());
    }

    final movement = StockMovement(
      id: 'mov-${const Uuid().v4().substring(0, 8)}',
      type: MovementType.adjustment,
      itemId: itemId,
      itemName: item.effectiveDisplayName,
      fromOutletId: outletId,
      fromOutletName: outletName,
      quantity: difference.abs(),
      unit: item.unit,
      userId: user.id,
      userName: user.name,
      userRole: user.role,
      timestamp: DateTime.now(),
      note: note.trim(),
      costImpact: costImpact,
    );

    await movementRepository.logMovement(movement);
    _notifyChanges();
    return movement;
  }

  @override
  Future<void> quickCountUpdate(
    User user, {
    required String outletId,
    required Map<String, double> packetCounts,
  }) async {
    if (!user.canAccessOutlet(outletId)) {
      throw const PermissionDeniedException('Not authorized for this outlet');
    }

    for (final entry in packetCounts.entries) {
      final itemId = entry.key;
      final countedPackets = entry.value;

      final itemIndex = _items.indexWhere((i) => i.id == itemId);
      if (itemIndex == -1) continue;
      final item = _items[itemIndex];

      final targetQuantity = countedPackets * item.mainPacketSize;
      final currentQuantity = _batches
          .where((b) => b.itemId == itemId && b.outletId == outletId)
          .fold(0.0, (sum, b) => sum + b.quantity);

      final diff = currentQuantity - targetQuantity;
      if (diff > 0.001) {
        // Consumed / used during shift
        await recordUsage(user, itemId: itemId, outletId: outletId, quantity: diff);
      } else if (diff < -0.001) {
        // Counted more than on record
        final added = diff.abs();
        _batches.add(StockBatch(
          batchId: 'batch-${const Uuid().v4().substring(0, 8)}',
          itemId: itemId,
          outletId: outletId,
          quantity: added,
          purchasePrice: item.purchasePricePerUnit,
          receivedDate: DateTime.now(),
        ));
      }
    }

    _notifyChanges();
  }

  void transferBatchesDirectly({
    required String itemId,
    required String fromOutletId,
    required String toOutletId,
    required double quantity,
  }) {
    double remaining = quantity;

    final matchingIndices = <int>[];
    for (int i = 0; i < _batches.length; i++) {
      if (_batches[i].itemId == itemId &&
          _batches[i].outletId == fromOutletId &&
          _batches[i].quantity > 0) {
        matchingIndices.add(i);
      }
    }

    matchingIndices.sort((a, b) => _batches[a].receivedDate.compareTo(_batches[b].receivedDate));

    for (final index in matchingIndices) {
      if (remaining <= 0) break;
      final currentBatch = _batches[index];
      final toTake = currentBatch.quantity <= remaining ? currentBatch.quantity : remaining;

      // Create transferred batch in destination outlet preserving price and expiry!
      _batches.add(StockBatch(
        batchId: 'batch-${const Uuid().v4().substring(0, 8)}',
        itemId: itemId,
        outletId: toOutletId,
        quantity: toTake,
        purchasePrice: currentBatch.purchasePrice,
        receivedDate: DateTime.now(),
        expiryDate: currentBatch.expiryDate,
      ));

      _batches[index] = currentBatch.copyWith(
        quantity: currentBatch.quantity - toTake,
      );
      remaining -= toTake;
    }

    _batches.removeWhere((b) => b.quantity <= 0);
    _notifyChanges();
  }

  void _notifyChanges() {
    _controller.add(_computeItemStocks());
  }

  @override
  Future<void> resetDemoData() async {
    _items.clear();
    _items.addAll(SampleData.initialItems);
    _batches.clear();
    _batches.addAll(SampleData.generateInitialBatches());
    _notifyChanges();
  }

  @override
  Future<void> clearSampleData() async {
    _items.clear();
    _batches.clear();
    _notifyChanges();
  }

  void dispose() {
    _controller.close();
  }
}
