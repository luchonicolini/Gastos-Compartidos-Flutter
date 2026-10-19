import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/expense.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/money.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/domain/models/split_type.dart';
import 'package:gastos_compartidos/logic/balance_calculator.dart';

/// Regresiones de gastos en moneda extranjera.
///
/// Regla: el importe original, los pagadores y la división por monto se
/// expresan en la moneda original del gasto. Los balances siempre se
/// convierten a la moneda de referencia usando la tasa guardada en el gasto.
void main() {
  late Person ana;
  late Person beto;
  late Person carla;

  setUp(() {
    ana = Person(id: 'ana', name: 'Ana');
    beto = Person(id: 'beto', name: 'Beto');
    carla = Person(id: 'carla', name: 'Carla');
  });

  double balanceOf(Group group, Person person) => BalanceCalculator
      .calculateMemberBalances(group)
      .firstWhere((balance) => balance.id == person.id)
      .balance;

  double totalBalance(Group group) => BalanceCalculator.calculateMemberBalances(
    group,
  ).fold(0, (sum, balance) => sum + balance.balance);

  test('un pagador en moneda original se convierte a la moneda de referencia', () {
    final group = Group(
      name: 'Brasil',
      members: [ana, beto],
      expenses: [
        Expense(
          description: 'Hotel',
          amount: 100000,
          originalAmount: Money.fromString('100', Currency.usd),
          originalCurrency: Currency.usd,
          convertedAmount: Money.fromString('100000', Currency.ars),
          referenceCurrency: Currency.ars,
          exchangeRate: 1000,
          payers: [
            ExpensePayer(
              person: ana,
              amount: Money.fromString('100', Currency.usd),
            ),
          ],
          participants: [ana, beto],
        ),
      ],
    );

    expect(balanceOf(group, ana), 50000);
    expect(balanceOf(group, beto), -50000);
    expect(totalBalance(group), 0);
  });

  test('varios pagadores en moneda original conservan su aporte real', () {
    final group = Group(
      name: 'Brasil',
      members: [ana, beto],
      expenses: [
        Expense(
          description: 'Hotel',
          amount: 100000,
          originalAmount: Money.fromString('100', Currency.usd),
          originalCurrency: Currency.usd,
          convertedAmount: Money.fromString('100000', Currency.ars),
          referenceCurrency: Currency.ars,
          exchangeRate: 1000,
          payers: [
            ExpensePayer(
              person: ana,
              amount: Money.fromString('60', Currency.usd),
            ),
            ExpensePayer(
              person: beto,
              amount: Money.fromString('40', Currency.usd),
            ),
          ],
          participants: [ana, beto],
        ),
      ],
    );

    // Ana puso ARS 60.000 y le corresponden ARS 50.000 => +10.000
    // Beto puso ARS 40.000 y le corresponden ARS 50.000 => -10.000
    expect(balanceOf(group, ana), 10000);
    expect(balanceOf(group, beto), -10000);
    expect(totalBalance(group), 0);
  });

  test('la división por monto en moneda original se convierte con la tasa', () {
    final group = Group(
      name: 'Brasil',
      members: [ana, beto],
      expenses: [
        Expense(
          description: 'Hotel',
          amount: 100000,
          originalAmount: Money.fromString('100', Currency.usd),
          originalCurrency: Currency.usd,
          convertedAmount: Money.fromString('100000', Currency.ars),
          referenceCurrency: Currency.ars,
          exchangeRate: 1000,
          payers: [
            ExpensePayer(
              person: ana,
              amount: Money.fromString('100', Currency.usd),
            ),
          ],
          participants: [ana, beto],
          splitType: SplitType.byAmount,
          // 20 USD y 80 USD escritos en la pantalla, en moneda original.
          splitDetails: {'ana': 20, 'beto': 80},
        ),
      ],
    );

    // Ana pagó ARS 100.000 y consume ARS 20.000 => +80.000
    // Beto consume ARS 80.000 => -80.000
    expect(balanceOf(group, ana), 80000);
    expect(balanceOf(group, beto), -80000);
    expect(totalBalance(group), 0);
  });

  test(
    'la división por monto con tasa decimal cierra exactamente el total convertido',
    () {
      final group = Group(
        name: 'Brasil',
        members: [ana, beto, carla],
        expenses: [
          Expense(
            description: 'Cena',
            amount: 66667,
            originalAmount: Money.fromString('2.00', Currency.usd),
            originalCurrency: Currency.usd,
            convertedAmount: Money.fromString('666.67', Currency.ars),
            referenceCurrency: Currency.ars,
            exchangeRate: 333.333,
            payers: [
              ExpensePayer(
                person: ana,
                amount: Money.fromString('2.00', Currency.usd),
              ),
            ],
            participants: [ana, beto, carla],
            splitType: SplitType.byAmount,
            splitDetails: {'ana': 1.00, 'beto': 1.00},
          ),
        ],
      );

      final shares = BalanceCalculator.calculateShareCents(
        expense: group.expenses.single,
        participants: [ana, beto, carla],
      );

      expect(
        shares.values.fold<int>(0, (sum, value) => sum + value),
        group.expenses.single.convertedAmount.cents,
      );
    },
  );

  test(
    'los pagadores guardados en moneda de referencia siguen calculando igual',
    () {
      final group = Group(
        name: 'Brasil',
        members: [ana, beto],
        expenses: [
          Expense(
            description: 'Hotel',
            amount: 100000,
            originalAmount: Money.fromString('100', Currency.usd),
            originalCurrency: Currency.usd,
            convertedAmount: Money.fromString('100000', Currency.ars),
            referenceCurrency: Currency.ars,
            exchangeRate: 1000,
            payers: [
              ExpensePayer(
                person: ana,
                amount: Money.fromString('100000', Currency.ars),
              ),
            ],
            participants: [ana, beto],
          ),
        ],
      );

      expect(balanceOf(group, ana), 50000);
      expect(balanceOf(group, beto), -50000);
      expect(totalBalance(group), 0);
    },
  );

  test('un grupo con gastos mixtos siempre suma balance cero', () {
    final group = Group(
      name: 'Viaje',
      members: [ana, beto, carla],
      expenses: [
        Expense(
          description: 'Cena en reales',
          amount: 25000,
          originalAmount: Money.fromString('125', Currency.brl),
          originalCurrency: Currency.brl,
          convertedAmount: Money.fromString('25000', Currency.ars),
          referenceCurrency: Currency.ars,
          exchangeRate: 200,
          payers: [
            ExpensePayer(
              person: beto,
              amount: Money.fromString('125', Currency.brl),
            ),
          ],
          participants: [ana, beto, carla],
          splitType: SplitType.byAmount,
          splitDetails: {'ana': 25, 'beto': 50, 'carla': 50},
        ),
        Expense(
          description: 'Taxi en pesos',
          amount: 9000,
          payer: carla,
          participants: [ana, beto, carla],
        ),
      ],
    );

    // Cena: Beto pagó BRL 125 = ARS 25.000 y consume ARS 10.000 => +15.000
    //       Ana consume ARS 5.000 => -5.000, Carla consume ARS 10.000 => -10.000
    // Taxi: Carla paga ARS 9.000 y consume ARS 3.000 => +6.000
    //       Ana y Beto consumen ARS 3.000 cada uno.
    expect(balanceOf(group, ana), -8000);
    expect(balanceOf(group, beto), 12000);
    expect(balanceOf(group, carla), -4000);
    expect(totalBalance(group), 0);
  });
}
