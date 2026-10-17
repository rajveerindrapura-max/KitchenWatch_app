import '../../activity/domain/movement.dart';
import '../../auth/domain/user.dart';
import 'item.dart';
import 'item_stock.dart';
import 'stock_batch.dart';

abstract class InventoryRepository {
  Future<List<Item>> getItems();
  Future<Item> addItem(User user, Item item);
  Future<void> updateItem(User user, Item item);
  Future<void> deleteItem(User user, String itemId);

  Future<List<StockBatch>> getBatches({String? outletId, String? itemId});
  Future<List<ItemStock>> getItemStocks({String? outletId});
  Stream<List<ItemStock>> watchItemStocks({String? outletId});

  Future<StockMovement> recordIncoming(
    User user, {
    required String itemId,
    required String outletId,
    required double quantity,
    required double purchasePrice,
    DateTime? expiryDate,
  });

  Future<StockMovement> recordUsage(
    User user, {
    required String itemId,
    required String outletId,
    required double quantity,
  });

  Future<StockMovement> recordWastage(
    User user, {
    required String itemId,
    required String outletId,
    required double quantity,
    required WasteReason reason,
  });

  Future<StockMovement> recordAdjustment(
    User user, {
    required String itemId,
    required String outletId,
    required double newQuantity,
    required String note,
  });

  Future<void> quickCountUpdate(
    User user, {
    required String outletId,
    required Map<String, double> packetCounts,
  });

  Future<void> resetDemoData();
  Future<void> clearSampleData();
}
