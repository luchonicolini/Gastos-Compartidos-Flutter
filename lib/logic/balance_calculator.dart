import '../domain/models/group.dart';
import '../domain/models/person.dart';
import '../domain/models/expense.dart';
import '../domain/models/split_type.dart';
import '../domain/models/settlement_payment.dart';
import '../domain/models/member_balance.dart';
import '../domain/models/money.dart';

extension DoubleRounding on double {
  double roundToPlaces(int places) {
    return double.parse(toStringAsFixed(places));
  }
}

class BalanceCalculator {
  static List<MemberBalance> calculateMemberBalances(Group group) {
    if (group.members.isEmpty) return [];

    final currentMemberIds = group.members.map((m) => m.id).toSet();
    final balances = <String, int>{
      for (final member in group.members) member.id: 0,
    };

    // 1. Procesar gastos normales
    _processExpenses(group.expenses, currentMemberIds, balances);

    // 2. Procesar pagos de liquidación
    _processSettlementPayments(group.settlementPayments, currentMemberIds, balances);

    // 3. Convertir a lista de MemberBalance ordenada por nombre
    final result = group.members.map((member) {
      final balance = (balances[member.id] ?? 0) / 100;
      return MemberBalance(
        id: member.id,
        name: member.name,
        balance: balance,
      );
    }).toList();

    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  static void _processExpenses(
    List<Expense> expenses,
    Set<String> currentMemberIds,
    Map<String, int> balances,
  ) {
    for (final expense in expenses) {
      if (expense.payers.isEmpty || expense.amount <= 0) continue;

      for (final payer in expense.payers) {
        if (currentMemberIds.contains(payer.person.id)) {
          balances[payer.person.id] =
              (balances[payer.person.id] ?? 0) + payer.amount.cents;
        }
      }

      final currentParticipants = expense.participants
          .where((p) => currentMemberIds.contains(p.id))
          .toList();
      if (currentParticipants.isEmpty) continue;

      final sharesToDebit = calculateShareCents(
        expense: expense,
        participants: currentParticipants,
      );

      for (final entry in sharesToDebit.entries) {
        if (currentMemberIds.contains(entry.key)) {
          balances[entry.key] = (balances[entry.key] ?? 0) - entry.value;
        }
      }
    }
  }

  static void _processSettlementPayments(
    List<SettlementPayment> payments,
    Set<String> currentMemberIds,
    Map<String, int> balances,
  ) {
    for (final payment in payments) {
      if (currentMemberIds.contains(payment.payerId)) {
        balances[payment.payerId] = (balances[payment.payerId] ?? 0) + (payment.amount * 100).round();
      }
      if (currentMemberIds.contains(payment.payeeId)) {
        balances[payment.payeeId] = (balances[payment.payeeId] ?? 0) - (payment.amount * 100).round();
      }
    }
  }

  static Map<String, double> calculateShares({
    required Expense expense,
    required List<Person> participants,
  }) {
    return calculateShareCents(expense: expense, participants: participants)
        .map((key, value) => MapEntry(key, value / 100));
  }

  static Map<String, int> calculateShareCents({
    required Expense expense,
    required List<Person> participants,
  }) {
    switch (expense.splitType) {
      case SplitType.equally:
        return _calculateEqualSharesInCents(expense, participants);
      case SplitType.byAmount:
        return _calculateAmountSharesInCents(expense, participants);
      case SplitType.byPercentage:
        return _calculatePercentageSharesInCents(expense, participants);
      case SplitType.byShares:
        return _calculateProportionalSharesInCents(expense, participants);
    }
  }

  static Map<String, int> _calculateEqualSharesInCents(
    Expense expense,
    List<Person> participants,
  ) {
    final sharesToDebit = <String, int>{};
    final expenseAmountCents = expense.convertedAmount.cents;
    final count = participants.length;

    if (count > 0) {
      final share = expenseAmountCents ~/ count;
      final remainder = expenseAmountCents - (share * count);

      for (var index = 0; index < participants.length; index++) {
        final p = participants[index];
        sharesToDebit[p.id] = share + (index == 0 ? remainder : 0);
      }
    }

    return sharesToDebit;
  }

  static Map<String, int> _calculateAmountSharesInCents(
    Expense expense,
    List<Person> participants,
  ) {
    final details = expense.splitDetails;
    if (details == null) {
      return _calculateEqualSharesInCents(expense, participants);
    }

    final sharesToDebit = <String, int>{};
    for (final p in participants) {
      final specificAmount = Money.fromDecimal(
        details[p.id] ?? 0,
        expense.referenceCurrency,
      ).cents;
      sharesToDebit[p.id] = specificAmount;
    }

    return sharesToDebit;
  }

  static Map<String, int> _calculatePercentageSharesInCents(
    Expense expense,
    List<Person> participants,
  ) {
    final details = expense.splitDetails;
    if (details == null) {
      return _calculateEqualSharesInCents(expense, participants);
    }

    final sharesToDebit = <String, int>{};
    final expenseAmountCents = expense.convertedAmount.cents;
    var calculatedSum = 0;

    for (final p in participants) {
      final percentage = details[p.id] ?? 0.0;
      final amount = (expenseAmountCents * (percentage / 100.0)).round();
      sharesToDebit[p.id] = amount;
      calculatedSum += amount;
    }

    final diff = expenseAmountCents - calculatedSum;
    if (diff != 0 && participants.isNotEmpty) {
      final firstId = participants.first.id;
      sharesToDebit[firstId] = (sharesToDebit[firstId] ?? 0) + diff;
    }

    return sharesToDebit;
  }

  static Map<String, int> _calculateProportionalSharesInCents(
    Expense expense,
    List<Person> participants,
  ) {
    final details = expense.splitDetails;
    if (details == null) {
      return _calculateEqualSharesInCents(expense, participants);
    }

    double totalShares = 0.0;
    for (final p in participants) {
      totalShares += details[p.id] ?? 0.0;
    }

    if (totalShares <= 0) {
      return _calculateEqualSharesInCents(expense, participants);
    }

    final sharesToDebit = <String, int>{};
    final expenseAmountCents = expense.convertedAmount.cents;
    var calculatedSum = 0;

    for (final p in participants) {
      final participantShares = details[p.id] ?? 0.0;
      final amount = (expenseAmountCents * (participantShares / totalShares)).round();
      sharesToDebit[p.id] = amount;
      calculatedSum += amount;
    }

    final diff = expenseAmountCents - calculatedSum;
    if (diff != 0 && participants.isNotEmpty) {
      final firstId = participants.first.id;
      sharesToDebit[firstId] = (sharesToDebit[firstId] ?? 0) + diff;
    }

    return sharesToDebit;
  }
}
