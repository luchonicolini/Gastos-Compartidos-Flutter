import 'currency.dart';

class ExchangeRate {
  const ExchangeRate({required this.from, required this.to, required this.value, this.updatedAt});

  final Currency from;
  final Currency to;
  final double value;
  final DateTime? updatedAt;
}

