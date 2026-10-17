class StockBatch {
  final String batchId;
  final String itemId;
  final String outletId;
  final double quantity;
  final double purchasePrice; // Purchase price per unit
  final DateTime receivedDate;
  final DateTime? expiryDate;

  const StockBatch({
    required this.batchId,
    required this.itemId,
    required this.outletId,
    required this.quantity,
    required this.purchasePrice,
    required this.receivedDate,
    this.expiryDate,
  });

  double get totalValue => quantity * purchasePrice;

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  StockBatch copyWith({
    String? batchId,
    String? itemId,
    String? outletId,
    double? quantity,
    double? purchasePrice,
    DateTime? receivedDate,
    DateTime? expiryDate,
  }) {
    return StockBatch(
      batchId: batchId ?? this.batchId,
      itemId: itemId ?? this.itemId,
      outletId: outletId ?? this.outletId,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      receivedDate: receivedDate ?? this.receivedDate,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'itemId': itemId,
      'outletId': outletId,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'receivedDate': receivedDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  factory StockBatch.fromJson(Map<String, dynamic> json) {
    return StockBatch(
      batchId: json['batchId'] as String,
      itemId: json['itemId'] as String,
      outletId: json['outletId'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      receivedDate: DateTime.parse(json['receivedDate'] as String),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
    );
  }
}
