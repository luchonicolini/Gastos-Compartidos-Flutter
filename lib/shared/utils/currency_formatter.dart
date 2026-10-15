class CurrencyFormatter {
  /// Formats a string of digits by adding a dot every 3 digits from right to left.
  static String formatWithDots(String digits) {
    final buffer = StringBuffer();
    final len = digits.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Formats a double amount into a string with dot separators for thousands, and optionally comma for decimals.
  static String formatAmount(double value) {
    final isNegative = value < 0;
    final absVal = value.abs();
    final isWhole = absVal == absVal.roundToDouble();

    if (isWhole) {
      final whole = absVal.toInt().toString();
      final formattedWhole = formatWithDots(whole);
      return '${isNegative ? '-' : ''}$formattedWhole';
    }

    final parts = absVal.toStringAsFixed(2).split('.');
    final formattedWhole = formatWithDots(parts[0]);
    final decimal = parts[1];
    return '${isNegative ? '-' : ''}$formattedWhole,$decimal';
  }
}
