import 'package:intl/intl.dart';
import '../domain/models/member_balance.dart';
import '../domain/models/settlement_payment.dart';
import 'balance_calculator.dart';

class SettlementCalculator {
  static List<FormattedSettlement> suggestFormattedSettlements(
    List<MemberBalance> memberBalances, {
    String? currencySymbol,
  }) {
    final balancesToSettle = memberBalances
        .where((m) => m.balance.abs() > 0.01)
        .map((m) => MemberBalance(id: m.id, name: m.name, balance: m.balance))
        .toList();

    if (balancesToSettle.isEmpty) return [];

    final tempDebtors = balancesToSettle
        .where((m) => m.balance < -0.01)
        .toList()
      ..sort((a, b) => a.balance.compareTo(b.balance)); // más endeudados primero

    final tempCreditors = balancesToSettle
        .where((m) => m.balance > 0.01)
        .toList()
      ..sort((a, b) => b.balance.compareTo(a.balance)); // a los que más se les debe primero

    final settlements = <FormattedSettlement>[];
    final currencyFormatter = NumberFormatter(symbol: currencySymbol ?? '\$');

    while (tempDebtors.isNotEmpty && tempCreditors.isNotEmpty) {
      final debtor = tempDebtors.removeAt(0);
      final creditor = tempCreditors.removeAt(0);

      final amountToTransfer = (debtor.balance.abs() < creditor.balance
              ? debtor.balance.abs()
              : creditor.balance)
          .roundToPlaces(2);

      if (amountToTransfer < 0.01) {
        if (debtor.balance.abs() >= 0.01) {
          _insertSorted(debtor, tempDebtors, (a, b) => a.balance <= b.balance);
        }
        if (creditor.balance >= 0.01) {
          _insertSorted(creditor, tempCreditors, (a, b) => a.balance >= b.balance);
        }
        continue;
      }

      final formattedStr = currencyFormatter.format(amountToTransfer);

      settlements.add(FormattedSettlement(
        payerName: debtor.name,
        payeeName: creditor.name,
        amount: amountToTransfer,
        formattedAmount: formattedStr,
        payerId: debtor.id,
        payeeId: creditor.id,
      ));

      debtor.balance = (debtor.balance + amountToTransfer).roundToPlaces(2);
      creditor.balance = (creditor.balance - amountToTransfer).roundToPlaces(2);

      if (debtor.balance.abs() >= 0.01) {
        _insertSorted(debtor, tempDebtors, (a, b) => a.balance <= b.balance);
      }
      if (creditor.balance >= 0.01) {
        _insertSorted(creditor, tempCreditors, (a, b) => a.balance >= b.balance);
      }
    }

    return settlements;
  }

  static void _insertSorted<T>(
    T element,
    List<T> list,
    bool Function(T a, T b) condition,
  ) {
    final index = list.indexWhere((item) => condition(item, element));
    if (index >= 0) {
      list.insert(index, element);
    } else {
      list.append(element);
    }
  }
}

class NumberFormatter {
  final String symbol;
  late final NumberFormat _formatter;

  NumberFormatter({this.symbol = '\$'}) {
    _formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );
  }

  String format(double amount) {
    return _formatter.format(amount);
  }
}

extension ListAppend<T> on List<T> {
  void append(T element) => add(element);
}
