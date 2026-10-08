import 'package:uuid/uuid.dart';

class SettlementPayment {
  final String id;
  final String payerId;
  final String payeeId;
  final double amount;
  final DateTime date;
  final String? groupId;
  final String payerName;
  final String payeeName;

  SettlementPayment({
    String? id,
    required this.payerId,
    required this.payeeId,
    required this.amount,
    DateTime? date,
    this.groupId,
    required this.payerName,
    required this.payeeName,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'payerId': payerId,
        'payeeId': payeeId,
        'amount': amount,
        'date': date.toIso8601String(),
        'groupId': groupId,
        'payerName': payerName,
        'payeeName': payeeName,
      };

  factory SettlementPayment.fromJson(Map<String, dynamic> json) =>
      SettlementPayment(
        id: json['id'] as String,
        payerId: json['payerId'] as String,
        payeeId: json['payeeId'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        groupId: json['groupId'] as String?,
        payerName: json['payerName'] as String,
        payeeName: json['payeeName'] as String,
      );
}

class FormattedSettlement {
  final String id;
  final String payerName;
  final String payeeName;
  final double amount;
  final String formattedAmount;
  final String payerId;
  final String payeeId;

  FormattedSettlement({
    String? id,
    required this.payerName,
    required this.payeeName,
    required this.amount,
    required this.formattedAmount,
    required this.payerId,
    required this.payeeId,
  }) : id = id ?? const Uuid().v4();
}
