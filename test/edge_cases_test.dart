import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/expense.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/money.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/domain/models/split_type.dart';
import 'package:gastos_compartidos/logic/balance_calculator.dart';
import 'package:gastos_compartidos/logic/expense_validator.dart';
import 'package:gastos_compartidos/logic/settlement_calculator.dart';

void main() {
  group('Edge Cases & Stress Tests', () {
    test('1. Números grandes (ej: 500 millones de pesos por inflación)', () {
      final p1 = Person(id: '1', name: 'Martín');
      final p2 = Person(id: '2', name: 'Lucas');

      final expense = Expense(
        description: 'Alquiler casa verano',
        amount: 500000000.00,
        payer: p1,
        participants: [p1, p2],
        splitType: SplitType.equally,
      );

      final shares = BalanceCalculator.calculateShares(
        expense: expense,
        participants: [p1, p2],
      );

      expect(shares[p1.id], 250000000.00);
      expect(shares[p2.id], 250000000.00);

      final group = Group(
        name: 'Vacaciones',
        members: [p1, p2],
        expenses: [expense],
      );

      final balances = BalanceCalculator.calculateMemberBalances(group);
      final p1Balance = balances.firstWhere((b) => b.id == p1.id);
      final p2Balance = balances.firstWhere((b) => b.id == p2.id);

      expect(p1Balance.balance, 250000000.00);
      expect(p2Balance.balance, -250000000.00);

      final settlements = SettlementCalculator.suggestFormattedSettlements(
        balances,
        referenceCurrency: Currency.ars,
      );
      expect(settlements.length, 1);
      expect(settlements.first.amount, 250000000.00);
    });

    test('2. División periódica entre 3 y 7 personas sin pérdida de centavos', () {
      final people = List.generate(3, (i) => Person(id: '$i', name: 'P$i'));

      // 100 pesos entre 3 personas = 33.33 + 33.33 + 33.34 = 100.00
      final expense = Expense(
        description: 'Pizza',
        amount: 100.00,
        payer: people[0],
        participants: people,
        splitType: SplitType.equally,
      );

      final shares = BalanceCalculator.calculateShares(
        expense: expense,
        participants: people,
      );

      final total = shares.values.fold<double>(0, (a, b) => a + b);
      expect((total - 100.00).abs(), lessThanOrEqualTo(0.0001));

      // 7 personas dividiendo 10 pesos = 1.42857...
      final sevenPeople = List.generate(7, (i) => Person(id: 's$i', name: 'S$i'));
      final expense7 = Expense(
        description: 'Café',
        amount: 10.00,
        payer: sevenPeople[0],
        participants: sevenPeople,
        splitType: SplitType.equally,
      );
      final shares7 = BalanceCalculator.calculateShares(
        expense: expense7,
        participants: sevenPeople,
      );
      final total7 = shares7.values.fold<double>(0, (a, b) => a + b);
      expect((total7 - 10.00).abs(), lessThanOrEqualTo(0.0001));
    });

    test('3. Ciclo triangular de deudas (A le debe a B, B a C, C a A)', () {
      final a = Person(id: 'a', name: 'A');
      final b = Person(id: 'b', name: 'B');
      final c = Person(id: 'c', name: 'C');

      // A paga 30 por A, B, C (cada uno debe 10 a A)
      final expA = Expense(
        description: 'Gasto A',
        amount: 30.00,
        payer: a,
        participants: [a, b, c],
      );
      // B paga 30 por A, B, C (cada uno debe 10 a B)
      final expB = Expense(
        description: 'Gasto B',
        amount: 30.00,
        payer: b,
        participants: [a, b, c],
      );
      // C paga 30 por A, B, C (cada uno debe 10 a C)
      final expC = Expense(
        description: 'Gasto C',
        amount: 30.00,
        payer: c,
        participants: [a, b, c],
      );

      final group = Group(
        name: 'Triángulo',
        members: [a, b, c],
        expenses: [expA, expB, expC],
      );

      final balances = BalanceCalculator.calculateMemberBalances(group);
      for (final bal in balances) {
        expect(bal.balance, 0.0, reason: '${bal.name} debería quedar en 0 balance');
      }

      final settlements = SettlementCalculator.suggestFormattedSettlements(
        balances,
        referenceCurrency: Currency.ars,
      );
      // Como todos gastaron lo mismo, las deudas se cancelan mutuamente
      expect(settlements, isEmpty);
    });

    test('4. Validaciones de bordes (monto negativo, cero, descripción vacía)', () {
      final p = Person(id: '1', name: 'Juan');

      expect(
        ExpenseValidator.validate(
          description: '   ',
          amount: 50,
          payer: p,
          participants: [p],
          splitType: SplitType.equally,
        ),
        'La descripción es obligatoria.',
      );

      expect(
        ExpenseValidator.validate(
          description: 'Válido',
          amount: 0,
          payer: p,
          participants: [p],
          splitType: SplitType.equally,
        ),
        'El monto debe ser mayor a cero.',
      );

      expect(
        ExpenseValidator.validate(
          description: 'Válido',
          amount: -10,
          payer: p,
          participants: [p],
          splitType: SplitType.equally,
        ),
        'El monto debe ser mayor a cero.',
      );

      expect(
        ExpenseValidator.validate(
          description: 'Válido',
          amount: 100,
          payer: null,
          payers: [],
          participants: [p],
          splitType: SplitType.equally,
        ),
        'Seleccioná quién pagó.',
      );

      expect(
        ExpenseValidator.validate(
          description: 'Válido',
          amount: 100,
          payer: p,
          participants: [],
          splitType: SplitType.equally,
        ),
        'Seleccioná al menos un participante.',
      );
    });

    test('5. Multi-moneda: conversión de BRL a ARS', () {
      final original = Money.fromString('150.50', Currency.brl);
      final converted = original.convertTo(Currency.ars, 200.0);

      expect(converted.currency, Currency.ars);
      // 150.50 * 200 = 30100.00 ARS -> 3010000 centavos
      expect(converted.cents, 3010000);
      expect(converted.decimalValue, 30100.00);
    });
  });
}
