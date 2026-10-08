import '../domain/models/group.dart';
import '../domain/models/person.dart';
import '../domain/models/expense.dart';
import '../domain/models/split_type.dart';
import '../domain/models/settlement_payment.dart';
import '../domain/models/member_balance.dart';

extension DoubleRounding on double {
  double roundToPlaces(int places) {
    return double.parse(toStringAsFixed(places));
  }
}

class BalanceCalculator {
  static List<MemberBalance> calculateMemberBalances(Group group) {
    if (group.members.isEmpty) return [];

    final currentMemberIds = group.members.map((m) => m.id).toSet();
    final balances = <String, double>{
      for (final member in group.members) member.id: 0.0,
    };

    // 1. Procesar gastos normales
    _processExpenses(group.expenses, currentMemberIds, balances);

    // 2. Procesar pagos de liquidación
    _processSettlementPayments(group.settlementPayments, currentMemberIds, balances);

    // 3. Convertir a lista de MemberBalance ordenada por nombre
    final result = group.members.map((member) {
      final balance = (balances[member.id] ?? 0.0).roundToPlaces(2);
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
    Map<String, double> balances,
  ) {
    for (final expense in expenses) {
      if (expense.payers.isEmpty || expense.amount <= 0) continue;

      for (final payer in expense.payers) {
        if (currentMemberIds.contains(payer.person.id)) {
          balances[payer.person.id] =
              (balances[payer.person.id] ?? 0.0) + payer.amount.decimalValue;
        }
      }

      final currentParticipants = expense.participants
          .where((p) => currentMemberIds.contains(p.id))
          .toList();
      if (currentParticipants.isEmpty) continue;

      final sharesToDebit = calculateShares(
        expense: expense,
        participants: currentParticipants,
      );

      for (final entry in sharesToDebit.entries) {
        if (currentMemberIds.contains(entry.key)) {
          balances[entry.key] = (balances[entry.key] ?? 0.0) - entry.value;
        }
      }
    }
  }

  static void _processSettlementPayments(
    List<SettlementPayment> payments,
    Set<String> currentMemberIds,
    Map<String, double> balances,
  ) {
    for (final payment in payments) {
      if (currentMemberIds.contains(payment.payerId)) {
        balances[payment.payerId] = (balances[payment.payerId] ?? 0.0) + payment.amount;
      }
      if (currentMemberIds.contains(payment.payeeId)) {
        balances[payment.payeeId] = (balances[payment.payeeId] ?? 0.0) - payment.amount;
      }
    }
  }

  static Map<String, double> calculateShares({
    required Expense expense,
    required List<Person> participants,
  }) {
    switch (expense.splitType) {
      case SplitType.equally:
        return _calculateEqualShares(expense, participants);
      case SplitType.byAmount:
        return _calculateAmountShares(expense, participants);
      case SplitType.byPercentage:
        return _calculatePercentageShares(expense, participants);
      case SplitType.byShares:
        return _calculateProportionalShares(expense, participants);
    }
  }

  static Map<String, double> _calculateEqualShares(
    Expense expense,
    List<Person> participants,
  ) {
    final sharesToDebit = <String, double>{};
    final expenseAmountRounded = expense.amount.roundToPlaces(2);
    final count = participants.length;

    if (count > 0) {
      final share = (expense.amount / count).roundToPlaces(2);
      double totalRoundedShare = 0.0;

      for (final p in participants) {
        sharesToDebit[p.id] = share;
        totalRoundedShare += share;
      }

      final diff = (expenseAmountRounded - totalRoundedShare).roundToPlaces(2);
      if (diff.abs() > 0.001 && participants.isNotEmpty) {
        final firstId = participants.first.id;
        sharesToDebit[firstId] = (sharesToDebit[firstId] ?? 0.0) + diff;
      }
    }

    return sharesToDebit;
  }

  static Map<String, double> _calculateAmountShares(
    Expense expense,
    List<Person> participants,
  ) {
    final details = expense.splitDetails;
    if (details == null) {
      return _calculateEqualShares(expense, participants);
    }

    final sharesToDebit = <String, double>{};
    for (final p in participants) {
      final specificAmount = (details[p.id] ?? 0.0).roundToPlaces(2);
      sharesToDebit[p.id] = specificAmount;
    }

    return sharesToDebit;
  }

  static Map<String, double> _calculatePercentageShares(
    Expense expense,
    List<Person> participants,
  ) {
    final details = expense.splitDetails;
    if (details == null) {
      return _calculateEqualShares(expense, participants);
    }

    final sharesToDebit = <String, double>{};
    final expenseAmountRounded = expense.amount.roundToPlaces(2);
    double calculatedSum = 0.0;

    for (final p in participants) {
      final percentage = details[p.id] ?? 0.0;
      final amount = (expense.amount * (percentage / 100.0)).roundToPlaces(2);
      sharesToDebit[p.id] = amount;
      calculatedSum += amount;
    }

    final diff = (expenseAmountRounded - calculatedSum).roundToPlaces(2);
    if (diff.abs() > 0.001 && participants.isNotEmpty) {
      final firstId = participants.first.id;
      sharesToDebit[firstId] = (sharesToDebit[firstId] ?? 0.0) + diff;
    }

    return sharesToDebit;
  }

  static Map<String, double> _calculateProportionalShares(
    Expense expense,
    List<Person> participants,
  ) {
    final details = expense.splitDetails;
    if (details == null) {
      return _calculateEqualShares(expense, participants);
    }

    double totalShares = 0.0;
    for (final p in participants) {
      totalShares += details[p.id] ?? 0.0;
    }

    if (totalShares <= 0) {
      return _calculateEqualShares(expense, participants);
    }

    final sharesToDebit = <String, double>{};
    final expenseAmountRounded = expense.amount.roundToPlaces(2);
    double calculatedSum = 0.0;

    for (final p in participants) {
      final participantShares = details[p.id] ?? 0.0;
      final amount = (expense.amount * (participantShares / totalShares)).roundToPlaces(2);
      sharesToDebit[p.id] = amount;
      calculatedSum += amount;
    }

    final diff = (expenseAmountRounded - calculatedSum).roundToPlaces(2);
    if (diff.abs() > 0.001 && participants.isNotEmpty) {
      final firstId = participants.first.id;
      sharesToDebit[firstId] = (sharesToDebit[firstId] ?? 0.0) + diff;
    }

    return sharesToDebit;
  }
}
