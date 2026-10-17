import '../../../core/domain/permission_guard.dart';
import '../../inventory/domain/stock_unit.dart';

enum MovementType {
  received,
  used,
  wasted,
  transferred,
  adjustment;

  String get displayName {
    switch (this) {
      case MovementType.received:
        return 'Received';
      case MovementType.used:
        return 'Used';
      case MovementType.wasted:
        return 'Wasted';
      case MovementType.transferred:
        return 'Transferred';
      case MovementType.adjustment:
        return 'Adjustment';
    }
  }
}

enum WasteReason {
  expiry,
  spoilage,
  spillOrDamage,
  other;

  String get displayName {
    switch (this) {
      case WasteReason.expiry:
        return 'Expiry';
      case WasteReason.spoilage:
        return 'Spoilage';
      case WasteReason.spillOrDamage:
        return 'Spill or damage';
      case WasteReason.other:
        return 'Other';
    }
  }
}

class StockMovement {
  final String id;
  final MovementType type;
  final String itemId;
  final String itemName;
  final String fromOutletId;
  final String fromOutletName;
  final String? toOutletId;
  final String? toOutletName;
  final double quantity; // Positive magnitude of change
  final StockUnit unit;
  final String userId;
  final String userName;
  final UserRole userRole;
  final DateTime timestamp;
  final WasteReason? wasteReason;
  final String? note; // Required for adjustments
  final double costImpact; // Total rupee value impact calculated via FIFO

  const StockMovement({
    required this.id,
    required this.type,
    required this.itemId,
    required this.itemName,
    required this.fromOutletId,
    required this.fromOutletName,
    this.toOutletId,
    this.toOutletName,
    required this.quantity,
    required this.unit,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.timestamp,
    this.wasteReason,
    this.note,
    required this.costImpact,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'itemId': itemId,
      'itemName': itemName,
      'fromOutletId': fromOutletId,
      'fromOutletName': fromOutletName,
      'toOutletId': toOutletId,
      'toOutletName': toOutletName,
      'quantity': quantity,
      'unit': unit.name,
      'userId': userId,
      'userName': userName,
      'userRole': userRole.name,
      'timestamp': timestamp.toIso8601String(),
      'wasteReason': wasteReason?.name,
      'note': note,
      'costImpact': costImpact,
    };
  }

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] as String,
      type: MovementType.values.firstWhere((t) => t.name == json['type']),
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String,
      fromOutletId: json['fromOutletId'] as String,
      fromOutletName: json['fromOutletName'] as String,
      toOutletId: json['toOutletId'] as String?,
      toOutletName: json['toOutletName'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unit: StockUnit.fromString(json['unit'] as String),
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userRole: UserRole.values.firstWhere((r) => r.name == json['userRole']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      wasteReason: json['wasteReason'] != null
          ? WasteReason.values.firstWhere((w) => w.name == json['wasteReason'])
          : null,
      note: json['note'] as String?,
      costImpact: (json['costImpact'] as num).toDouble(),
    );
  }
}
