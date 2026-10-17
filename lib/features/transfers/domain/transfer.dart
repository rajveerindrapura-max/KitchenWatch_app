import '../../inventory/domain/stock_unit.dart';

class TransferItem {
  final String itemId;
  final String itemName;
  final double quantity;
  final StockUnit unit;
  final double estimatedValue;

  const TransferItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.estimatedValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit.name,
      'estimatedValue': estimatedValue,
    };
  }

  factory TransferItem.fromJson(Map<String, dynamic> json) {
    return TransferItem(
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: StockUnit.fromString(json['unit'] as String),
      estimatedValue: (json['estimatedValue'] as num).toDouble(),
    );
  }
}

class TransferRecord {
  final String id;
  final String fromOutletId;
  final String fromOutletName;
  final String toOutletId;
  final String toOutletName;
  final List<TransferItem> items;
  final DateTime timestamp;
  final String initiatedByUserId;
  final String initiatedByUserName;
  final String? notes;

  const TransferRecord({
    required this.id,
    required this.fromOutletId,
    required this.fromOutletName,
    required this.toOutletId,
    required this.toOutletName,
    required this.items,
    required this.timestamp,
    required this.initiatedByUserId,
    required this.initiatedByUserName,
    this.notes,
  });

  double get totalValue =>
      items.fold(0.0, (sum, item) => sum + item.estimatedValue);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromOutletId': fromOutletId,
      'fromOutletName': fromOutletName,
      'toOutletId': toOutletId,
      'toOutletName': toOutletName,
      'items': items.map((i) => i.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'initiatedByUserId': initiatedByUserId,
      'initiatedByUserName': initiatedByUserName,
      'notes': notes,
    };
  }

  factory TransferRecord.fromJson(Map<String, dynamic> json) {
    return TransferRecord(
      id: json['id'] as String,
      fromOutletId: json['fromOutletId'] as String,
      fromOutletName: json['fromOutletName'] as String,
      toOutletId: json['toOutletId'] as String,
      toOutletName: json['toOutletName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((i) => TransferItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      initiatedByUserId: json['initiatedByUserId'] as String,
      initiatedByUserName: json['initiatedByUserName'] as String,
      notes: json['notes'] as String?,
    );
  }
}
