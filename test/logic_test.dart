import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/domain/models/expense.dart';
import 'package:gastos_compartidos/domain/models/split_type.dart';
import 'package:gastos_compartidos/domain/models/settlement_payment.dart';
import 'package:gastos_compartidos/logic/balance_calculator.dart';
import 'package:gastos_compartidos/logic/settlement_calculator.dart';

void main() {
  group('BalanceCalculator & SettlementCalculator Tests', () {
    late Person frodo;
    late Person sam;

    setUp(() {
      frodo = Person(id: '1', name: 'Frodo');
      sam = Person(id: '2', name: 'Sam');
    });

    test('División equitativa entre 2 personas con ajuste de centavo impar', () {
      final expense = Expense(
        description: 'Cena',
        amount: 100.01,
        payer: frodo,
        participants: [frodo, sam],
        splitType: SplitType.equally,
      );

      final shares = BalanceCalculator.calculateShares(
        expense: expense,
        participants: [frodo, sam],
      );

      // 100.01 / 2 = 50.005 -> redondeado a 50.00 cada uno.
      // 100.01 - 100.00 = 0.01 residual asignado al primer participante.
      final totalCalculated = (shares[frodo.id]! + shares[sam.id]!).roundToPlaces(2);
      expect(totalCalculated, 100.01);
      expect((shares[frodo.id]! - shares[sam.id]!).abs(), lessThanOrEqualTo(0.01));
    });

    test('Cálculo de balances y sugerencia de liquidación de cuentas', () {
      // Frodo paga 100 por Frodo y Sam (50 cada uno)
      // Sam debe 50 a Frodo
      final expense1 = Expense(
        description: 'Hotel',
        amount: 100.00,
        payer: frodo,
        participants: [frodo, sam],
      );

      final group = Group(
        name: 'Viaje a Mordor',
        members: [frodo, sam],
        expenses: [expense1],
      );

      final balances = BalanceCalculator.calculateMemberBalances(group);
      final frodoBalance = balances.firstWhere((b) => b.id == frodo.id);
      final samBalance = balances.firstWhere((b) => b.id == sam.id);

      expect(frodoBalance.balance, 50.00);
      expect(samBalance.balance, -50.00);

      final settlements = SettlementCalculator.suggestFormattedSettlements(balances);
      expect(settlements.length, 1);
      expect(settlements.first.payerName, 'Sam');
      expect(settlements.first.payeeName, 'Frodo');
      expect(settlements.first.amount, 50.00);
    });

    test('Confirmación de pago de liquidación salda la deuda', () {
      final expense1 = Expense(
        description: 'Comida',
        amount: 60.00,
        payer: frodo,
        participants: [frodo, sam],
      );

      // Sam paga los 30 que debía
      final payment = SettlementPayment(
        payerId: sam.id,
        payeeId: frodo.id,
        amount: 30.00,
        payerName: sam.name,
        payeeName: frodo.name,
      );

      final group = Group(
        name: 'Cuentas',
        members: [frodo, sam],
        expenses: [expense1],
        settlementPayments: [payment],
      );

      final balances = BalanceCalculator.calculateMemberBalances(group);
      final frodoBalance = balances.firstWhere((b) => b.id == frodo.id);
      final samBalance = balances.firstWhere((b) => b.id == sam.id);

      expect(frodoBalance.balance, 0.0);
      expect(samBalance.balance, 0.0);

      final settlements = SettlementCalculator.suggestFormattedSettlements(balances);
      expect(settlements.isEmpty, true);
    });
  });
}
