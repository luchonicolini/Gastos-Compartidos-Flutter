import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/domain/models/expense.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/money.dart';
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

    test(
      'División equitativa entre 2 personas con ajuste de centavo impar',
      () {
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
        final totalCalculated = (shares[frodo.id]! + shares[sam.id]!)
            .roundToPlaces(2);
        expect(totalCalculated, 100.01);
        expect(
          (shares[frodo.id]! - shares[sam.id]!).abs(),
          lessThanOrEqualTo(0.01),
        );
      },
    );

    test('Calcula división por monto, porcentaje y partes', () {
      final participants = [frodo, sam];
      final amountExpense = Expense(
        description: 'Hotel',
        amount: 100,
        payer: frodo,
        participants: participants,
        splitType: SplitType.byAmount,
        splitDetails: {'1': 25, '2': 75},
      );
      final percentageExpense = amountExpense.copyWith(
        splitType: SplitType.byPercentage,
        splitDetails: {'1': 25, '2': 75},
      );
      final sharesExpense = amountExpense.copyWith(
        splitType: SplitType.byShares,
        splitDetails: {'1': 1, '2': 3},
      );

      expect(
        BalanceCalculator.calculateShares(
          expense: amountExpense,
          participants: participants,
        ),
        {'1': 25, '2': 75},
      );
      expect(
        BalanceCalculator.calculateShares(
          expense: percentageExpense,
          participants: participants,
        ),
        {'1': 25, '2': 75},
      );
      expect(
        BalanceCalculator.calculateShares(
          expense: sharesExpense,
          participants: participants,
        ),
        {'1': 25, '2': 75},
      );
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

      final settlements = SettlementCalculator.suggestFormattedSettlements(
        balances,
        referenceCurrency: Currency.ars,
      );
      expect(settlements.length, 1);
      expect(settlements.first.payerName, 'Sam');
      expect(settlements.first.payeeName, 'Frodo');
      expect(settlements.first.amount, 50.00);
    });

    test('Calcula un gasto con múltiples pagadores', () {
      final expense = Expense(
        description: 'Hotel',
        amount: 200,
        payers: [
          ExpensePayer(
            person: frodo,
            amount: Money.fromString('120', Currency.ars),
          ),
          ExpensePayer(
            person: sam,
            amount: Money.fromString('80', Currency.ars),
          ),
        ],
        participants: [frodo, sam],
      );
      final group = Group(
        name: 'Viaje',
        members: [frodo, sam],
        expenses: [expense],
      );

      final balances = BalanceCalculator.calculateMemberBalances(group);

      expect(balances.firstWhere((item) => item.id == frodo.id).balance, 20);
      expect(balances.firstWhere((item) => item.id == sam.id).balance, -20);
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
        money: Money.fromString('30.00', Currency.ars),
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

      final settlements = SettlementCalculator.suggestFormattedSettlements(
        balances,
        referenceCurrency: Currency.ars,
      );
      expect(settlements.isEmpty, true);
    });

    test('liquida correctamente un grupo cuya moneda de referencia es BRL', () {
      final expense = Expense(
        description: 'Hospedagem',
        amount: 100,
        originalAmount: Money.fromString('100', Currency.brl),
        originalCurrency: Currency.brl,
        convertedAmount: Money.fromString('100', Currency.brl),
        referenceCurrency: Currency.brl,
        payer: frodo,
        participants: [frodo, sam],
      );
      final group = Group(
        name: 'Brasil',
        referenceCurrency: Currency.brl,
        members: [frodo, sam],
        expenses: [expense],
      );

      final balances = BalanceCalculator.calculateMemberBalances(group);
      final settlements = SettlementCalculator.suggestFormattedSettlements(
        balances,
        referenceCurrency: group.referenceCurrency,
      );

      expect(
        balances.firstWhere((balance) => balance.id == frodo.id).balance,
        50,
      );
      expect(
        balances.firstWhere((balance) => balance.id == sam.id).balance,
        -50,
      );
      expect(settlements.single.amount, 50);
      expect(settlements.single.formattedAmount, contains('R\$'));
    });

    test(
      'un pago de liquidación conserva sus centavos y moneda de referencia',
      () {
        final payment = SettlementPayment(
          payerId: sam.id,
          payeeId: frodo.id,
          money: Money.fromString('10.01', Currency.brl),
          payerName: sam.name,
          payeeName: frodo.name,
        );

        expect(payment.money.cents, 1001);
        expect(payment.amount, 10.01);
        expect(payment.currency, Currency.brl);
      },
    );
  });
}
