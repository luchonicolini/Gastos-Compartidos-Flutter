import 'currency.dart';

class Money {
  const Money({required this.cents, required this.currency});

  final int cents;
  final Currency currency;

  factory Money.fromDecimal(double value, Currency currency) {
    return Money.fromString(value.toStringAsFixed(2), currency);
  }

  factory Money.fromString(String value, Currency currency) {
    final normalized = value.trim().replaceAll(',', '.');
    final negative = normalized.startsWith('-');
    final unsigned = negative ? normalized.substring(1) : normalized;
    final pieces = unsigned.split('.');
    final whole = int.tryParse(pieces.first.isEmpty ? '0' : pieces.first) ?? 0;
    final decimals = pieces.length > 1 ? pieces[1].padRight(2, '0') : '00';
    final firstTwo = int.tryParse(decimals.substring(0, 2)) ?? 0;
    final rounded = decimals.length > 2 && int.tryParse(decimals[2])! >= 5 ? 1 : 0;
    final cents = whole * 100 + firstTwo + rounded;
    return Money(cents: negative ? -cents : cents, currency: currency);
  }

  double get decimalValue => cents / 100;

  Money convertTo(Currency target, double exchangeRate) {
    return Money(cents: (cents * exchangeRate).round(), currency: target);
  }

  Money operator +(Money other) {
    _checkCurrency(other);
    return Money(cents: cents + other.cents, currency: currency);
  }

  Money operator -(Money other) {
    _checkCurrency(other);
    return Money(cents: cents - other.cents, currency: currency);
  }

  void _checkCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('No se pueden operar monedas diferentes sin convertirlas.');
    }
  }

  @override
  String toString() => '${currency.code} ${currency.symbol}${decimalValue.toStringAsFixed(2)}';

  @override
  bool operator ==(Object other) =>
      other is Money && other.cents == cents && other.currency == currency;

  @override
  int get hashCode => Object.hash(cents, currency);
}

