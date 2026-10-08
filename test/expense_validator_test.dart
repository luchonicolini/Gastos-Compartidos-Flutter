import 'package:flutter_test/flutter_test.dart';

import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/domain/models/split_type.dart';
import 'package:gastos_compartidos/logic/expense_validator.dart';

void main() {
  final luciano = Person(id: '1', name: 'Luciano');
  final ana = Person(id: '2', name: 'Ana');

  test('acepta un gasto equitativo válido', () {
    final error = ExpenseValidator.validate(
      description: 'Cena',
      amount: 100,
      payer: luciano,
      participants: [luciano, ana],
      splitType: SplitType.equally,
    );

    expect(error, isNull);
  });

  test('rechaza montos que no coinciden con el total', () {
    final error = ExpenseValidator.validate(
      description: 'Cena',
      amount: 100,
      payer: luciano,
      participants: [luciano, ana],
      splitType: SplitType.byAmount,
      splitDetails: {'1': 40, '2': 50},
    );

    expect(error, contains('deben sumar'));
  });

  test('rechaza porcentajes que no suman cien', () {
    final error = ExpenseValidator.validate(
      description: 'Cena',
      amount: 100,
      payer: luciano,
      participants: [luciano, ana],
      splitType: SplitType.byPercentage,
      splitDetails: {'1': 60, '2': 30},
    );

    expect(error, contains('100%'));
  });

  test('rechaza partes con suma cero', () {
    final error = ExpenseValidator.validate(
      description: 'Cena',
      amount: 100,
      payer: luciano,
      participants: [luciano, ana],
      splitType: SplitType.byShares,
      splitDetails: {'1': 0, '2': 0},
    );

    expect(error, contains('mayor a cero'));
  });
}

