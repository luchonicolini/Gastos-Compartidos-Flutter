import 'dart:convert';

import '../../domain/models/currency.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/group.dart';
import '../../domain/models/money.dart';
import '../../domain/models/person.dart';
import '../../domain/models/settlement_payment.dart';
import '../../domain/models/split_type.dart';

/// Error de formato al leer un respaldo (archivo inválido, versión no
/// soportada o datos inconsistentes).
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Contenido de un respaldo ya decodificado.
class BackupPayload {
  const BackupPayload({
    required this.version,
    required this.exportedAt,
    required this.groups,
    this.selfMemberIds = const {},
  });

  final int version;
  final DateTime? exportedAt;
  final List<Group> groups;

  /// Ids de los miembros marcados como "Vos", por grupo.
  final Map<String, String> selfMemberIds;
}

/// Convierte los grupos locales a un archivo JSON versionado y viceversa.
///
/// Es una capa pura: no toca archivos ni plugins, así que se puede probar con
/// tests de unidad. Conserva el importe original, la moneda, el tipo de cambio
/// y el importe convertido de cada gasto, además del estado archivado de
/// grupos y miembros.
class BackupCodec {
  const BackupCodec();

  static const format = 'gastos-compartidos-backup';
  static const version = 2;

  String encode(
    List<Group> groups, {
    DateTime? exportedAt,
    Map<String, String> selfMemberIds = const {},
  }) {
    final payload = <String, dynamic>{
      'format': format,
      'version': version,
      'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'groups': groups.map(_encodeGroup).toList(),
      'selfMemberIds': selfMemberIds,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  BackupPayload decode(String raw) {
    if (raw.trim().isEmpty) {
      throw const BackupFormatException('El archivo está vacío.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const BackupFormatException(
        'El archivo no tiene un formato JSON válido.',
      );
    }

    if (decoded is! Map) {
      throw const BackupFormatException(
        'El archivo no es un respaldo de Kune.',
      );
    }
    final json = decoded.cast<String, dynamic>();

    if (json['format'] != format) {
      throw const BackupFormatException(
        'El archivo no es un respaldo de Kune.',
      );
    }

    final rawVersion = json['version'];
    if (rawVersion is! int) {
      throw const BackupFormatException('El respaldo no indica su versión.');
    }
    if (rawVersion > version) {
      throw BackupFormatException(
        'El respaldo fue creado con una versión más nueva de la app '
        '(v$rawVersion). Actualizá la app para poder importarlo.',
      );
    }
    if (rawVersion < 1) {
      throw BackupFormatException(
        'El respaldo usa una versión no soportada (v$rawVersion).',
      );
    }

    final rawGroups = json['groups'];
    if (rawGroups is! List) {
      throw const BackupFormatException('El respaldo no contiene grupos.');
    }

    final exportedAt = json['exportedAt'];
    return BackupPayload(
      version: rawVersion,
      exportedAt: exportedAt is String ? DateTime.tryParse(exportedAt) : null,
      groups: rawGroups
          .map((group) => _decodeGroup(_asMap(group, 'grupo')))
          .toList(),
      selfMemberIds: _decodeSelfMemberIds(json['selfMemberIds']),
    );
  }

  Map<String, String> _decodeSelfMemberIds(Object? raw) {
    if (raw is! Map) return const {};
    final result = <String, String>{};
    raw.forEach((key, value) {
      if (key is String && value is String && value.isNotEmpty) {
        result[key] = value;
      }
    });
    return result;
  }

  Map<String, dynamic> _encodeGroup(Group group) => {
    'id': group.id,
    'name': group.name,
    'creationDate': group.creationDate.toIso8601String(),
    'iconName': group.iconName,
    'colorHex': group.colorHex,
    'referenceCurrency': group.referenceCurrency.code,
    'isArchived': group.isArchived,
    'budgetCents': group.budgetCents,
    'members': group.members.map(_encodePerson).toList(),
    'expenses': group.expenses.map(_encodeExpense).toList(),
    'settlements': group.settlementPayments.map(_encodeSettlement).toList(),
  };

  Map<String, dynamic> _encodePerson(Person person) => {
    'id': person.id,
    'name': person.name,
    'creationDate': person.creationDate.toIso8601String(),
    'isArchived': person.isArchived,
  };

  Map<String, dynamic> _encodeExpense(Expense expense) => {
    'id': expense.id,
    'description': expense.description,
    'amount': expense.amount,
    'date': expense.date.toIso8601String(),
    'splitType': expense.splitType.name,
    'splitDetails': expense.splitDetails,
    'category': expense.category,
    'notes': expense.notes,
    'originalAmountCents': expense.originalAmount.cents,
    'originalCurrency': expense.originalCurrency.code,
    'referenceCurrency': expense.referenceCurrency.code,
    'exchangeRate': expense.exchangeRate,
    'convertedAmountCents': expense.convertedAmount.cents,
    'payers': expense.payers
        .map(
          (payer) => {
            'personId': payer.person.id,
            'amountCents': payer.amount.cents,
            'currency': payer.amount.currency.code,
          },
        )
        .toList(),
    'participantIds': expense.participants.map((person) => person.id).toList(),
  };

  Map<String, dynamic> _encodeSettlement(SettlementPayment settlement) => {
    'id': settlement.id,
    'payerId': settlement.payerId,
    'payeeId': settlement.payeeId,
    'payerName': settlement.payerName,
    'payeeName': settlement.payeeName,
    'amountCents': settlement.money.cents,
    'currency': settlement.currency.code,
    'date': settlement.date.toIso8601String(),
  };

  Group _decodeGroup(Map<String, dynamic> json) {
    final members = _listOf(json['members'], 'integrantes')
        .map((member) => _decodePerson(_asMap(member, 'integrante')))
        .toList();
    final peopleById = {for (final member in members) member.id: member};

    final groupId = _requiredString(json, 'id');

    return Group(
      id: groupId,
      name: _requiredString(json, 'name'),
      creationDate: _requiredDate(json, 'creationDate'),
      iconName: _optionalString(json['iconName']),
      colorHex: _optionalString(json['colorHex']),
      referenceCurrency: Currency.fromCode(
        _requiredString(json, 'referenceCurrency'),
      ),
      members: members,
      expenses: _listOf(json['expenses'], 'gastos')
          .map(
            (expense) => _decodeExpense(
              _asMap(expense, 'gasto'),
              groupId: groupId,
              peopleById: peopleById,
            ),
          )
          .toList(),
      settlementPayments: _listOf(json['settlements'], 'liquidaciones')
          .map(
            (settlement) =>
                _decodeSettlement(_asMap(settlement, 'liquidación'), groupId),
          )
          .toList(),
      isArchived: _optionalBool(json['isArchived']),
      budgetCents: _optionalInt(json['budgetCents']),
    );
  }

  Person _decodePerson(Map<String, dynamic> json) => Person(
    id: _requiredString(json, 'id'),
    name: _requiredString(json, 'name'),
    creationDate: _requiredDate(json, 'creationDate'),
    isArchived: _optionalBool(json['isArchived']),
  );

  Expense _decodeExpense(
    Map<String, dynamic> json, {
    required String groupId,
    required Map<String, Person> peopleById,
  }) {
    final originalCurrency = Currency.fromCode(
      _requiredString(json, 'originalCurrency'),
    );
    final referenceCurrency = Currency.fromCode(
      _requiredString(json, 'referenceCurrency'),
    );

    final payers = _listOf(json['payers'], 'pagadores')
        .map((payer) {
          final map = _asMap(payer, 'pagador');
          return ExpensePayer(
            person: _personById(
              peopleById,
              _requiredString(map, 'personId'),
              'pagador',
            ),
            amount: Money(
              cents: _requiredInt(map, 'amountCents'),
              currency: Currency.fromCode(_requiredString(map, 'currency')),
            ),
          );
        })
        .toList();

    final participants = _stringList(json['participantIds'], 'participantes')
        .map((id) => _personById(peopleById, id, 'participante'))
        .toList();

    return Expense(
      id: _requiredString(json, 'id'),
      description: _requiredString(json, 'description'),
      amount: _requiredDouble(json, 'amount'),
      date: _requiredDate(json, 'date'),
      payers: payers,
      participants: participants,
      groupId: groupId,
      splitType: _splitType(_requiredString(json, 'splitType')),
      splitDetails: _decodeSplitDetails(json['splitDetails']),
      originalAmount: Money(
        cents: _requiredInt(json, 'originalAmountCents'),
        currency: originalCurrency,
      ),
      originalCurrency: originalCurrency,
      convertedAmount: Money(
        cents: _requiredInt(json, 'convertedAmountCents'),
        currency: referenceCurrency,
      ),
      referenceCurrency: referenceCurrency,
      exchangeRate: _requiredDouble(json, 'exchangeRate'),
      category: _optionalString(json['category']),
      notes: _optionalString(json['notes']),
    );
  }

  SettlementPayment _decodeSettlement(
    Map<String, dynamic> json,
    String groupId,
  ) => SettlementPayment(
    id: _requiredString(json, 'id'),
    payerId: _requiredString(json, 'payerId'),
    payeeId: _requiredString(json, 'payeeId'),
    payerName: _requiredString(json, 'payerName'),
    payeeName: _requiredString(json, 'payeeName'),
    money: Money(
      cents: _requiredInt(json, 'amountCents'),
      currency: Currency.fromCode(_requiredString(json, 'currency')),
    ),
    date: _requiredDate(json, 'date'),
    groupId: groupId,
  );

  Person _personById(
    Map<String, Person> peopleById,
    String id,
    String context,
  ) {
    final person = peopleById[id];
    if (person == null) {
      throw BackupFormatException(
        'El respaldo referencia a un integrante que no existe ($id).',
      );
    }
    return person;
  }

  SplitType _splitType(String name) {
    for (final value in SplitType.values) {
      if (value.name == name) return value;
    }
    throw BackupFormatException('Tipo de división desconocido: "$name".');
  }

  Map<String, double>? _decodeSplitDetails(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) {
      throw const BackupFormatException(
        'La división del gasto tiene un formato inválido.',
      );
    }
    return raw.map(
      (key, value) => MapEntry(key.toString(), _asDouble(value, 'división')),
    );
  }

  Map<String, dynamic> _asMap(Object? value, String context) {
    if (value is! Map) {
      throw BackupFormatException('El respaldo tiene un $context inválido.');
    }
    return value.cast<String, dynamic>();
  }

  List<Object?> _listOf(Object? value, String context) {
    if (value == null) return const [];
    if (value is! List) {
      throw BackupFormatException(
        'El respaldo tiene una lista de $context inválida.',
      );
    }
    return value;
  }

  List<String> _stringList(Object? value, String context) => _listOf(
    value,
    context,
  ).map((item) => _asString(item, context)).toList();

  String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw BackupFormatException('Falta el campo "$key" en el respaldo.');
    }
    return value;
  }

  String? _optionalString(Object? value) => value is String ? value : null;

  bool _optionalBool(Object? value) => value is bool ? value : false;

  int? _optionalInt(Object? value) => value is num ? value.toInt() : null;

  String _asString(Object? value, String context) {
    if (value is! String || value.isEmpty) {
      throw BackupFormatException('El respaldo tiene $context inválidos.');
    }
    return value;
  }

  int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! num) {
      throw BackupFormatException('Falta el campo "$key" en el respaldo.');
    }
    return value.toInt();
  }

  double _requiredDouble(Map<String, dynamic> json, String key) =>
      _asDouble(json[key], 'campo "$key"');

  double _asDouble(Object? value, String context) {
    if (value is! num) {
      throw BackupFormatException('El respaldo tiene un $context inválido.');
    }
    return value.toDouble();
  }

  DateTime _requiredDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw BackupFormatException('Falta el campo "$key" en el respaldo.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw BackupFormatException('El campo "$key" no es una fecha válida.');
    }
    return parsed;
  }
}
