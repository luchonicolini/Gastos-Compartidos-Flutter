import 'package:intl/intl.dart';

import '../domain/models/currency.dart';
import '../domain/models/member_balance.dart';
import '../domain/models/money.dart';
import '../domain/models/settlement_payment.dart';

class SettlementCalculator {
  static List<FormattedSettlement> suggestFormattedSettlements(
    List<MemberBalance> memberBalances, {
    String? currencySymbol,
  }) {
    final debtors = memberBalances
        .where((member) => member.balance < -0.01)
        .map((member) => _BalanceInCents(
              id: member.id,
              name: member.name,
              cents: Money.fromDecimal(member.balance.abs(), Currency.ars).cents,
            ))
        .toList();
    final creditors = memberBalances
        .where((member) => member.balance > 0.01)
        .map((member) => _BalanceInCents(
              id: member.id,
              name: member.name,
              cents: Money.fromDecimal(member.balance, Currency.ars).cents,
            ))
        .toList();

    final settlements = <FormattedSettlement>[];
    final currencyFormatter = NumberFormatter(symbol: currencySymbol ?? r'$');
    while (debtors.isNotEmpty && creditors.isNotEmpty) {
      debtors.sort((a, b) => b.cents.compareTo(a.cents));
      creditors.sort((a, b) => b.cents.compareTo(a.cents));
      final debtor = debtors.removeAt(0);
      final creditor = creditors.removeAt(0);
      final amountCents = debtor.cents < creditor.cents ? debtor.cents : creditor.cents;
      final amount = amountCents / 100;

      settlements.add(
        FormattedSettlement(
          payerName: debtor.name,
          payeeName: creditor.name,
          amount: amount,
          formattedAmount: currencyFormatter.format(amount),
          payerId: debtor.id,
          payeeId: creditor.id,
        ),
      );

      debtor.cents -= amountCents;
      creditor.cents -= amountCents;
      if (debtor.cents > 0) debtors.add(debtor);
      if (creditor.cents > 0) creditors.add(creditor);
    }
    return settlements;
  }
}
class _BalanceInCents {
  _BalanceInCents({required this.id, required this.name, required this.cents});

  final String id;
  final String name;
  int cents;
}

class NumberFormatter {
  final String symbol;
  late final NumberFormat _formatter;

  NumberFormatter({this.symbol = r'$'}) {
    _formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
  }

  String format(double amount) => _formatter.format(amount);
}
