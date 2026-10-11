import 'package:uuid/uuid.dart';
import 'currency.dart';
import 'person.dart';
import 'expense.dart';
import 'settlement_payment.dart';

class Group {
  final String id;
  final String name;
  final DateTime creationDate;
  final String? iconName;
  final String? colorHex;
  final Currency referenceCurrency;
  final List<Person> members;
  final List<Expense> expenses;
  final List<SettlementPayment> settlementPayments;
  final bool isArchived;
  final int? budgetCents;

  Group({
    String? id,
    required this.name,
    DateTime? creationDate,
    this.iconName,
    this.colorHex,
    Currency? referenceCurrency,
    List<Person>? members,
    List<Expense>? expenses,
    List<SettlementPayment>? settlementPayments,
    this.isArchived = false,
    this.budgetCents,
  })  : id = id ?? const Uuid().v4(),
        creationDate = creationDate ?? DateTime.now(),
        referenceCurrency = referenceCurrency ?? Currency.ars,
        members = members ?? [],
        expenses = expenses ?? [],
        settlementPayments = settlementPayments ?? [];

  Group copyWith({
    String? id,
    String? name,
    DateTime? creationDate,
    String? iconName,
    String? colorHex,
    Currency? referenceCurrency,
    List<Person>? members,
    List<Expense>? expenses,
    List<SettlementPayment>? settlementPayments,
    bool? isArchived,
    int? budgetCents,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      creationDate: creationDate ?? this.creationDate,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      referenceCurrency: referenceCurrency ?? this.referenceCurrency,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
      settlementPayments: settlementPayments ?? this.settlementPayments,
      isArchived: isArchived ?? this.isArchived,
      budgetCents: budgetCents ?? this.budgetCents,
    );
  }
}
