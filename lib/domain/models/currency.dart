class Currency {
  const Currency({required this.code, required this.symbol, required this.name});

  final String code;
  final String symbol;
  final String name;

  static const ars = Currency(code: 'ARS', symbol: r'$', name: 'Peso argentino');
  static const brl = Currency(code: 'BRL', symbol: r'R$', name: 'Real brasileño');
  static const usd = Currency(code: 'USD', symbol: r'US$', name: 'Dólar estadounidense');

  static const supported = [ars, brl, usd];

  static Currency fromCode(String code) {
    return supported.firstWhere(
      (currency) => currency.code == code.toUpperCase(),
      orElse: () => Currency(code: code.toUpperCase(), symbol: code.toUpperCase(), name: code.toUpperCase()),
    );
  }

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
