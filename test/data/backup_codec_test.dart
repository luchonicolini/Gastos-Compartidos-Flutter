import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/data/backup/backup_codec.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/expense.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/money.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/domain/models/settlement_payment.dart';
import 'package:gastos_compartidos/domain/models/split_type.dart';

void main() {
  const codec = BackupCodec();

  Group buildGroup() {
    final ana = Person(
      id: 'p-ana',
      name: 'Ana',
      creationDate: DateTime.utc(2026, 1, 1),
    );
    final beto = Person(
      id: 'p-beto',
      name: 'Beto',
      creationDate: DateTime.utc(2026, 1, 2),
      isArchived: true,
    );

    return Group(
      id: 'g-1',
      name: 'Brasil 2026',
      creationDate: DateTime.utc(2026, 1, 3),
      iconName: 'flight',
      colorHex: '#0D7E88',
      referenceCurrency: Currency.brl,
      isArchived: true,
      budgetCents: 100000,
      members: [ana, beto],
      expenses: [
        Expense(
          id: 'e-1',
          description: 'Cena',
          amount: 123.45,
          date: DateTime.utc(2026, 2, 1),
          participants: [ana, beto],
          groupId: 'g-1',
          splitType: SplitType.byAmount,
          splitDetails: {'p-ana': 5000.0, 'p-beto': 2345.0},
          originalAmount: const Money(cents: 7345, currency: Currency.ars),
          originalCurrency: Currency.ars,
          convertedAmount: const Money(cents: 12345, currency: Currency.brl),
          referenceCurrency: Currency.brl,
          exchangeRate: 1.6808,
          category: 'Comida',
          notes: 'Cena en la playa',
          payers: [
            ExpensePayer(
              person: ana,
              amount: const Money(cents: 4000, currency: Currency.ars),
            ),
            ExpensePayer(
              person: beto,
              amount: const Money(cents: 3345, currency: Currency.ars),
            ),
          ],
        ),
      ],
      settlementPayments: [
        SettlementPayment(
          id: 's-1',
          payerId: 'p-beto',
          payeeId: 'p-ana',
          payerName: 'Beto',
          payeeName: 'Ana',
          money: const Money(cents: 1500, currency: Currency.brl),
          date: DateTime.utc(2026, 2, 2),
          groupId: 'g-1',
        ),
      ],
    );
  }

  test('el respaldo conserva todos los campos al exportar e importar', () {
    final encoded = codec.encode(
      [buildGroup()],
      exportedAt: DateTime.utc(2026, 10, 19),
    );
    final payload = codec.decode(encoded);

    expect(payload.version, BackupCodec.version);
    expect(payload.exportedAt, DateTime.utc(2026, 10, 19));
    expect(payload.groups, hasLength(1));

    final group = payload.groups.single;
    expect(group.id, 'g-1');
    expect(group.name, 'Brasil 2026');
    expect(group.iconName, 'flight');
    expect(group.colorHex, '#0D7E88');
    expect(group.referenceCurrency, Currency.brl);
    expect(group.isArchived, isTrue);
    expect(group.budgetCents, 100000);
    expect(group.creationDate, DateTime.utc(2026, 1, 3));

    expect(group.members.map((member) => member.id), ['p-ana', 'p-beto']);
    expect(group.members.first.isArchived, isFalse);
    expect(group.members.last.isArchived, isTrue);

    final expense = group.expenses.single;
    expect(expense.id, 'e-1');
    expect(expense.description, 'Cena');
    expect(expense.amount, 123.45);
    expect(expense.date, DateTime.utc(2026, 2, 1));
    expect(expense.splitType, SplitType.byAmount);
    expect(expense.splitDetails, {'p-ana': 5000.0, 'p-beto': 2345.0});
    expect(expense.originalAmount.cents, 7345);
    expect(expense.originalCurrency, Currency.ars);
    expect(expense.convertedAmount.cents, 12345);
    expect(expense.convertedAmount.currency, Currency.brl);
    expect(expense.exchangeRate, 1.6808);
    expect(expense.category, 'Comida');
    expect(expense.notes, 'Cena en la playa');
    expect(expense.groupId, 'g-1');
    expect(expense.payers, hasLength(2));
    expect(expense.payers.first.person.id, 'p-ana');
    expect(expense.payers.first.person.name, 'Ana');
    expect(expense.payers.first.amount.cents, 4000);
    expect(expense.payers.first.amount.currency, Currency.ars);
    expect(expense.payers.last.person.id, 'p-beto');
    expect(expense.participants.map((person) => person.id), [
      'p-ana',
      'p-beto',
    ]);

    final settlement = group.settlementPayments.single;
    expect(settlement.id, 's-1');
    expect(settlement.payerId, 'p-beto');
    expect(settlement.payeeId, 'p-ana');
    expect(settlement.payerName, 'Beto');
    expect(settlement.payeeName, 'Ana');
    expect(settlement.money.cents, 1500);
    expect(settlement.currency, Currency.brl);
    expect(settlement.date, DateTime.utc(2026, 2, 2));
    expect(settlement.groupId, 'g-1');
  });

  test('exporta e importa un respaldo sin grupos', () {
    final encoded = codec.encode(const [], exportedAt: DateTime.utc(2026, 10, 19));
    final payload = codec.decode(encoded);

    expect(payload.groups, isEmpty);
  });

  test('el JSON exportado identifica el formato y la versión', () {
    final payload =
        jsonDecode(codec.encode(const [])) as Map<String, dynamic>;

    expect(payload['format'], BackupCodec.format);
    expect(payload['version'], BackupCodec.version);
    expect(payload['groups'], isEmpty);
    expect(payload['selfMemberIds'], isEmpty);
  });

  test('conserva el miembro Vos al exportar e importar', () {
    final encoded = codec.encode(
      [buildGroup()],
      selfMemberIds: {'g-1': 'p-ana'},
    );
    final payload = codec.decode(encoded);

    expect(payload.selfMemberIds, {'g-1': 'p-ana'});
  });

  test('acepta un respaldo v1 sin información del miembro Vos', () {
    final encoded = jsonEncode({
      'format': BackupCodec.format,
      'version': 1,
      'groups': const [],
    });
    final payload = codec.decode(encoded);

    expect(payload.version, 1);
    expect(payload.selfMemberIds, isEmpty);
  });

  test('rechaza un archivo que no es JSON válido', () {
    expect(
      () => codec.decode('no soy un respaldo'),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('rechaza un JSON que no es un respaldo de la app', () {
    expect(
      () => codec.decode('{"hola": "mundo"}'),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('rechaza un respaldo creado por una versión más nueva', () {
    final encoded = jsonEncode({
      'format': BackupCodec.format,
      'version': BackupCodec.version + 1,
      'groups': const [],
    });

    expect(
      () => codec.decode(encoded),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('rechaza un respaldo con un integrante inexistente', () {
    final encoded = jsonEncode({
      'format': BackupCodec.format,
      'version': BackupCodec.version,
      'exportedAt': DateTime.utc(2026, 10, 19).toIso8601String(),
      'groups': [
        {
          'id': 'g-1',
          'name': 'Grupo',
          'creationDate': DateTime.utc(2026, 1, 1).toIso8601String(),
          'referenceCurrency': 'ARS',
          'members': const [],
          'expenses': [
            {
              'id': 'e-1',
              'description': 'Cena',
              'amount': 100.0,
              'date': DateTime.utc(2026, 1, 2).toIso8601String(),
              'splitType': 'equally',
              'originalAmountCents': 10000,
              'originalCurrency': 'ARS',
              'referenceCurrency': 'ARS',
              'exchangeRate': 1.0,
              'convertedAmountCents': 10000,
              'payers': const [],
              'participantIds': ['p-desconocido'],
            },
          ],
          'settlements': const [],
        },
      ],
    });

    expect(
      () => codec.decode(encoded),
      throwsA(isA<BackupFormatException>()),
    );
  });
}
