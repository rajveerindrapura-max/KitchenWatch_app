enum StockUnit {
  kg,
  g,
  l,
  ml,
  packets,
  bags,
  tins,
  pieces;

  String get symbol {
    switch (this) {
      case StockUnit.kg:
        return 'kg';
      case StockUnit.g:
        return 'g';
      case StockUnit.l:
        return 'L';
      case StockUnit.ml:
        return 'ml';
      case StockUnit.packets:
        return 'packets';
      case StockUnit.bags:
        return 'bags';
      case StockUnit.tins:
        return 'tins';
      case StockUnit.pieces:
        return 'pieces';
    }
  }

  static StockUnit fromString(String val) {
    return StockUnit.values.firstWhere(
      (u) => u.name.toLowerCase() == val.toLowerCase() || u.symbol.toLowerCase() == val.toLowerCase(),
      orElse: () => StockUnit.kg,
    );
  }
}
