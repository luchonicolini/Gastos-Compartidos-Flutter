import 'package:flutter_test/flutter_test.dart';

import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/money.dart';

void main() {
  test('representa importes en centavos sin perder precisión', () {
    final amount = Money.fromString('125,75', Currency.brl);

    expect(amount.cents, 12575);
    expect(amount.decimalValue, 125.75);
    expect(amount.currency, Currency.brl);
  });

  test('redondea de forma determinista a dos decimales', () {
    expect(Money.fromString('100.005', Currency.ars).cents, 10001);
    expect(Money.fromString('100.004', Currency.ars).cents, 10000);
  });

  test('convierte conservando el importe original y generando centavos destino', () {
    final original = Money.fromString('350', Currency.brl);
    final converted = original.convertTo(Currency.ars, 250);

    expect(original.cents, 35000);
    expect(converted.cents, 8750000);
    expect(converted.currency, Currency.ars);
  });
}

