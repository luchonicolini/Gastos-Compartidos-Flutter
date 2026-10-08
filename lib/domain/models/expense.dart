import 'package:uuid/uuid.dart';
import 'person.dart';
import 'split_type.dart';

class Expense {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final Person? payer;
  final List<Person> participants;
  final String? groupId;
  final SplitType splitType;
  final Map<String, double>? splitDetails;

  Expense({
    String? id,
    required this.description,
    required this.amount,
    DateTime? date,
    this.payer,
    List<Person>? participants,
    this.groupId,
    this.splitType = SplitType.equally,
    this.splitDetails,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        participants = participants ?? [];

  Expense copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    Person? payer,
    List<Person>? participants,
    String? groupId,
    SplitType? splitType,
    Map<String, double>? splitDetails,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      payer: payer ?? this.payer,
      participants: participants ?? this.participants,
      groupId: groupId ?? this.groupId,
      splitType: splitType ?? this.splitType,
      splitDetails: splitDetails ?? this.splitDetails,
    );
  }
}
