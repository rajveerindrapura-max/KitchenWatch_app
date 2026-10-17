import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenwatch/core/utils/currency_formatter.dart';

void main() {
  group('Indian Currency Formatter', () {
    test('Correctly groups digits according to Indian numbering system', () {
      expect(CurrencyFormatter.format(0), '\u20B90');
      expect(CurrencyFormatter.format(50), '\u20B950');
      expect(CurrencyFormatter.format(500), '\u20B9500');
      expect(CurrencyFormatter.format(1500), '\u20B91,500');
      expect(CurrencyFormatter.format(12500), '\u20B912,500');
      expect(CurrencyFormatter.format(482500), '\u20B94,82,500');
      expect(CurrencyFormatter.format(1482500), '\u20B914,82,500');
      expect(CurrencyFormatter.format(21482500), '\u20B92,14,82,500');
    });

    test('Handles negative numbers and custom options', () {
      expect(CurrencyFormatter.format(-482500), '-\u20B94,82,500');
      expect(CurrencyFormatter.format(482500, includeSymbol: false), '4,82,500');
    });
  });
}
