import 'package:uuid/uuid.dart';
import 'person.dart';
import 'expense.dart';
import 'settlement_payment.dart';

class Group {
  final String id;
  final String name;
  final DateTime creationDate;
  final String? iconName;
  final String? colorHex;
  final List<Person> members;
  final List<Expense> expenses;
  final List<SettlementPayment> settlementPayments;

  Group({
    String? id,
    required this.name,
    DateTime? creationDate,
    this.iconName,
    this.colorHex,
    List<Person>? members,
    List<Expense>? expenses,
    List<SettlementPayment>? settlementPayments,
  })  : id = id ?? const Uuid().v4(),
        creationDate = creationDate ?? DateTime.now(),
        members = members ?? [],
        expenses = expenses ?? [],
        settlementPayments = settlementPayments ?? [];

  Group copyWith({
    String? id,
    String? name,
    DateTime? creationDate,
    String? iconName,
    String? colorHex,
    List<Person>? members,
    List<Expense>? expenses,
    List<SettlementPayment>? settlementPayments,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      creationDate: creationDate ?? this.creationDate,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
      settlementPayments: settlementPayments ?? this.settlementPayments,
    );
  }
}
