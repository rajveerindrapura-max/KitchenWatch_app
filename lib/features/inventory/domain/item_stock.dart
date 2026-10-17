import 'item.dart';
import 'stock_batch.dart';

class ItemStock {
  final Item item;
  final List<StockBatch> batches;

  const ItemStock({
    required this.item,
    required this.batches,
  });

  double get totalQuantity =>
      batches.fold(0.0, (sum, batch) => sum + batch.quantity);

  double get totalValue =>
      batches.fold(0.0, (sum, batch) => sum + batch.totalValue);

  bool get isLowStock => totalQuantity <= item.minLevel;

  bool get isOutOfStock => totalQuantity <= 0;

  double getQuantityForOutlet(String outletId) {
    return batches
        .where((b) => b.outletId == outletId)
        .fold(0.0, (sum, b) => sum + b.quantity);
  }

  double getValueForOutlet(String outletId) {
    return batches
        .where((b) => b.outletId == outletId)
        .fold(0.0, (sum, b) => sum + b.totalValue);
  }

  List<StockBatch> getBatchesForOutlet(String outletId) {
    final outletBatches = batches.where((b) => b.outletId == outletId).toList();
    outletBatches.sort((a, b) => a.receivedDate.compareTo(b.receivedDate));
    return outletBatches;
  }

  StockBatch? get nearestExpiringBatch {
    final withExpiry = batches
        .where((b) => b.expiryDate != null && b.quantity > 0)
        .toList();
    if (withExpiry.isEmpty) return null;
    withExpiry.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    return withExpiry.first;
  }

  bool get isExpiringSoon {
    final nearest = nearestExpiringBatch;
    if (nearest == null || nearest.expiryDate == null) return false;
    final days = nearest.daysUntilExpiry;
    return days != null && days <= 5 && days >= 0;
  }
}
