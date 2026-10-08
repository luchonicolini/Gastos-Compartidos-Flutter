import 'package:uuid/uuid.dart';

import 'currency.dart';
import 'money.dart';
import 'person.dart';
import 'split_type.dart';

class ExpensePayer {
  const ExpensePayer({required this.person, required this.amount});

  final Person person;
  final Money amount;
}

class Expense {
  final String id;
  final String description;
  // Kept as a compatibility getter for the current UI/calculators. It is the
  // converted amount in the reference currency; exact values live in Money.
  final double amount;
  final DateTime date;
  final List<ExpensePayer> payers;
  final List<Person> participants;
  final String? groupId;
  final SplitType splitType;
  final Map<String, double>? splitDetails;
  final Money originalAmount;
  final Currency originalCurrency;
  final Money convertedAmount;
  final Currency referenceCurrency;
  final double exchangeRate;

  Expense({
    String? id,
    required this.description,
    required this.amount,
    DateTime? date,
    Person? payer,
    List<ExpensePayer>? payers,
    List<Person>? participants,
    this.groupId,
    this.splitType = SplitType.equally,
    this.splitDetails,
    Currency? originalCurrency,
    Currency? referenceCurrency,
    Money? originalAmount,
    Money? convertedAmount,
    this.exchangeRate = 1,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        payers = payers ??
            (payer == null
                ? const []
                : [
                    ExpensePayer(
                      person: payer,
                      amount: convertedAmount ??
                          Money.fromDecimal(amount, referenceCurrency ?? Currency.ars),
                    ),
                  ]),
        participants = participants ?? [],
        originalCurrency = originalCurrency ?? Currency.ars,
        referenceCurrency = referenceCurrency ?? Currency.ars,
        originalAmount = originalAmount ??
            Money.fromDecimal(amount, originalCurrency ?? Currency.ars),
        convertedAmount = convertedAmount ??
            Money.fromDecimal(amount, referenceCurrency ?? Currency.ars);

  Person? get payer => payers.length == 1 ? payers.single.person : null;

  Expense copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    Person? payer,
    List<ExpensePayer>? payers,
    List<Person>? participants,
    String? groupId,
    SplitType? splitType,
    Map<String, double>? splitDetails,
    Money? originalAmount,
    Currency? originalCurrency,
    Money? convertedAmount,
    Currency? referenceCurrency,
    double? exchangeRate,
  }) {
    final nextAmount = amount ?? this.amount;
    final nextReferenceCurrency = referenceCurrency ?? this.referenceCurrency;
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: nextAmount,
      date: date ?? this.date,
      payer: payer,
      payers: payers ?? (payer == null ? this.payers : null),
      participants: participants ?? this.participants,
      groupId: groupId ?? this.groupId,
      splitType: splitType ?? this.splitType,
      splitDetails: splitDetails ?? this.splitDetails,
      originalAmount: originalAmount ?? this.originalAmount,
      originalCurrency: originalCurrency ?? this.originalCurrency,
      convertedAmount: convertedAmount ?? (amount == null ? this.convertedAmount : null),
      referenceCurrency: nextReferenceCurrency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
    );
  }
}

