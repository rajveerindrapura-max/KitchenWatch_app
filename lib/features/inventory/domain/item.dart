import 'stock_unit.dart';

class Item {
  final String id;
  final String name;
  final String category;
  final StockUnit unit;
  final double mainPacketSize; // Size of standard outer packet in units
  final double minLevel; // Minimum stock alert threshold
  final double purchasePricePerUnit;
  final bool trackExpiry;
  final String? preferredVendor; // Stored only, extension point
  final String? imageUrl; // Optional image / placeholder key

  const Item({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    this.mainPacketSize = 1.0,
    required this.minLevel,
    required this.purchasePricePerUnit,
    this.trackExpiry = false,
    this.preferredVendor,
    this.imageUrl,
  });

  String get effectiveDisplayName {
    if (name.trim().isNotEmpty) return name;
    if (imageUrl != null && imageUrl!.isNotEmpty) return 'Item ($category)';
    return 'Unnamed item';
  }

  Item copyWith({
    String? id,
    String? name,
    String? category,
    StockUnit? unit,
    double? mainPacketSize,
    double? minLevel,
    double? purchasePricePerUnit,
    bool? trackExpiry,
    String? preferredVendor,
    String? imageUrl,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      mainPacketSize: mainPacketSize ?? this.mainPacketSize,
      minLevel: minLevel ?? this.minLevel,
      purchasePricePerUnit: purchasePricePerUnit ?? this.purchasePricePerUnit,
      trackExpiry: trackExpiry ?? this.trackExpiry,
      preferredVendor: preferredVendor ?? this.preferredVendor,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit.name,
      'mainPacketSize': mainPacketSize,
      'minLevel': minLevel,
      'purchasePricePerUnit': purchasePricePerUnit,
      'trackExpiry': trackExpiry,
      'preferredVendor': preferredVendor,
      'imageUrl': imageUrl,
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      category: json['category'] as String,
      unit: StockUnit.fromString(json['unit'] as String),
      mainPacketSize: (json['mainPacketSize'] as num?)?.toDouble() ?? 1.0,
      minLevel: (json['minLevel'] as num).toDouble(),
      purchasePricePerUnit: (json['purchasePricePerUnit'] as num).toDouble(),
      trackExpiry: json['trackExpiry'] as bool? ?? false,
      preferredVendor: json['preferredVendor'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
