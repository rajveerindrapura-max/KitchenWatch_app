class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(num amount, {bool includeSymbol = true, bool showDecimals = false}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final integerPart = absAmount.floor();
    final fraction = ((absAmount - integerPart) * 100).round();

    final integerString = integerPart.toString();
    String formattedInteger;

    if (integerString.length <= 3) {
      formattedInteger = integerString;
    } else {
      final lastThree = integerString.substring(integerString.length - 3);
      final remaining = integerString.substring(0, integerString.length - 3);

      final buffer = StringBuffer();
      for (int i = 0; i < remaining.length; i++) {
        final charsFromRight = remaining.length - i;
        buffer.write(remaining[i]);
        if (charsFromRight > 1 && charsFromRight % 2 == 1) {
          buffer.write(',');
        }
      }
      formattedInteger = '${buffer.toString()},$lastThree';
    }

    String result = formattedInteger;
    if (showDecimals && fraction > 0) {
      result = '$result.${fraction.toString().padLeft(2, '0')}';
    }

    final symbol = includeSymbol ? '\u20B9' : '';
    if (isNegative) {
      return '-$symbol$result';
    }
    return '$symbol$result';
  }
}
