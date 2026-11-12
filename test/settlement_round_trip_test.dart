import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/expense.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/money.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/domain/models/settlement_payment.dart';
import 'package:gastos_compartidos/logic/balance_calculator.dart';
import 'package:gastos_compartidos/logic/settlement_calculator.dart';

Map<String, int> balanceCents(Group group) => {
  for (final balance in BalanceCalculator.calculateMemberBalances(group))
    balance.id: (balance.balance * 100).round(),
};

Group applySuggestedPayments(Group group) {
  final suggestions = SettlementCalculator.suggestFormattedSettlements(
    BalanceCalculator.calculateMemberBalances(group),
    referenceCurrency: group.referenceCurrency,
  );
  return group.copyWith(
    settlementPayments: [
      ...group.settlementPayments,
      for (final suggestion in suggestions)
        SettlementPayment(
          payerId: suggestion.payerId,
          payeeId: suggestion.payeeId,
          money: Money.fromDecimal(suggestion.amount, group.referenceCurrency),
          payerName: suggestion.payerName,
          payeeName: suggestion.payeeName,
        ),
    ],
  );
}

void main() {
  late Person ana;
  late Person bruno;
  late Person carla;

  setUp(() {
    ana = Person(id: 'ana', name: 'Ana');
    bruno = Person(id: 'bruno', name: 'Bruno');
    carla = Person(id: 'carla', name: 'Carla');
  });

  test('settling several expenses clears every member balance', () {
    final members = [ana, bruno, carla];
    final group = Group(
      name: 'Trip',
      members: members,
      expenses: [
        Expense(description: 'Hotel', amount: 120, payer: ana,
            participants: members),
        Expense(description: 'Taxi', amount: 30, payer: bruno,
            participants: members),
      ],
    );
    expect(balanceCents(group), {'ana': 7000, 'bruno': -2000, 'carla': -5000});

    final settled = applySuggestedPayments(group);
    expect(settled.settlementPayments, hasLength(2));
    expect(balanceCents(settled), {'ana': 0, 'bruno': 0, 'carla': 0});
    expect(
      SettlementCalculator.suggestFormattedSettlements(
        BalanceCalculator.calculateMemberBalances(settled),
        referenceCurrency: Currency.ars,
      ),
      isEmpty,
    );

    // Removing the recorded payments restores the original debt.
    final restored = settled.copyWith(settlementPayments: []);
    expect(balanceCents(restored), balanceCents(group));
  });

  test('uneven cent amounts remain balanced after settlement', () {
    final members = [ana, bruno, carla, Person(id: 'dani', name: 'Dani')];
    for (final amount in [10.01, 99.99, 123.45]) {
      final group = Group(
        name: 'Rounding',
        members: members,
        expenses: [
          Expense(description: 'Dinner', amount: amount, payer: ana,
              participants: members),
        ],
      );
      expect(balanceCents(group).values.fold<int>(0, (sum, value) => sum + value),
          0, reason: 'Balances must conserve the total for $amount');
      expect(balanceCents(applySuggestedPayments(group)).values, everyElement(0),
          reason: 'Payments must settle the exact cent amounts for $amount');
    }
  });

  test('same-name members remain distinct through settlement', () {
    final first = ana.copyWith(name: 'Alex');
    final second = bruno.copyWith(name: 'Alex');
    final group = Group(
      name: 'Names',
      members: [first, second],
      expenses: [
        Expense(description: 'Lunch', amount: 80, payer: first,
            participants: [first, second]),
      ],
    );
    final settled = applySuggestedPayments(group);
    final payment = settled.settlementPayments.single;
    expect(payment.payerId, second.id);
    expect(payment.payeeId, first.id);
    expect(balanceCents(settled), {'ana': 0, 'bruno': 0});
  });

  test('archiving a member preserves their historical debt', () {
    final archived = bruno.copyWith(isArchived: true);
    final group = Group(
      name: 'History',
      members: [ana, archived],
      expenses: [
        Expense(description: 'Lunch', amount: 80, payer: ana,
            participants: [ana, bruno]),
      ],
    );
    expect(balanceCents(group), {'ana': 4000, 'bruno': -4000});
    expect(balanceCents(applySuggestedPayments(group)), {'ana': 0, 'bruno': 0});
  });
}
