import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/group.dart' as domain;
import '../../domain/models/expense.dart' as domain;
import '../../domain/models/person.dart' as domain;
import '../../domain/models/split_type.dart';
import '../database/app_database.dart';

class LocalGroupRepository {
  LocalGroupRepository(this._database);

  final AppDatabase _database;

  Future<void> save(domain.Group group) async {
    await _database.transaction(() async {
      await _database.into(_database.groups).insertOnConflictUpdate(
            GroupsCompanion.insert(
              id: group.id,
              name: group.name,
              creationDate: group.creationDate,
              iconName: Value(group.iconName),
              colorHex: Value(group.colorHex),
            ),
          );

      await (_database.delete(_database.groupMembers)
            ..where((member) => member.groupId.equals(group.id)))
          .go();

      for (final member in group.members) {
        await _database.into(_database.persons).insertOnConflictUpdate(
              PersonsCompanion.insert(
                id: member.id,
                name: member.name,
                creationDate: member.creationDate,
                isArchived: Value(member.isArchived),
              ),
            );

        await _database.into(_database.groupMembers).insertOnConflictUpdate(
              GroupMembersCompanion.insert(
                groupId: group.id,
                personId: member.id,
              ),
            );
      }

      final oldExpenses = await (_database.select(_database.expenses)
            ..where((expense) => expense.groupId.equals(group.id)))
          .get();
      for (final expense in oldExpenses) {
        await (_database.delete(_database.expenseParticipants)
              ..where((item) => item.expenseId.equals(expense.id)))
            .go();
        await (_database.delete(_database.expenseSplits)
              ..where((item) => item.expenseId.equals(expense.id)))
            .go();
        await (_database.delete(_database.expenses)
              ..where((item) => item.id.equals(expense.id)))
            .go();
      }

      for (final expense in group.expenses) {
        await _database.into(_database.expenses).insert(
              ExpensesCompanion.insert(
                id: expense.id,
                groupId: group.id,
                description: expense.description,
                amount: expense.amount,
                date: expense.date,
                payerId: Value(expense.payer?.id),
                splitType: expense.splitType.index,
                splitDetailsJson: Value(
                  expense.splitDetails == null ? null : jsonEncode(expense.splitDetails),
                ),
              ),
            );

        for (final participant in expense.participants) {
          await _database.into(_database.expenseParticipants).insert(
                ExpenseParticipantsCompanion.insert(
                  expenseId: expense.id,
                  personId: participant.id,
                ),
              );
        }

        for (final entry in expense.splitDetails?.entries ?? const <MapEntry<String, double>>[]) {
          await _database.into(_database.expenseSplits).insert(
                ExpenseSplitsCompanion.insert(
                  expenseId: expense.id,
                  personId: entry.key,
                  value: entry.value,
                ),
              );
        }
      }
    });
  }

  Future<void> delete(String groupId) async {
    await _database.transaction(() async {
      await (_database.delete(_database.groupMembers)
            ..where((member) => member.groupId.equals(groupId)))
          .go();
      final expenses = await (_database.select(_database.expenses)
            ..where((expense) => expense.groupId.equals(groupId)))
          .get();
      for (final expense in expenses) {
        await (_database.delete(_database.expenseParticipants)
              ..where((item) => item.expenseId.equals(expense.id)))
            .go();
        await (_database.delete(_database.expenseSplits)
              ..where((item) => item.expenseId.equals(expense.id)))
            .go();
      }
      await (_database.delete(_database.expenses)
            ..where((expense) => expense.groupId.equals(groupId)))
          .go();
      await (_database.delete(_database.groups)
            ..where((group) => group.id.equals(groupId)))
          .go();
    });
  }

  Future<List<domain.Group>> getAll() async {
    final groupRows = await (_database.select(_database.groups)
          ..orderBy([(group) => OrderingTerm.desc(group.creationDate)]))
        .get();

    final groups = <domain.Group>[];
    for (final groupRow in groupRows) {
      final memberRows = await (_database.select(_database.persons).join([
        innerJoin(
          _database.groupMembers,
          _database.groupMembers.personId.equalsExp(_database.persons.id),
        ),
      ])
            ..where(_database.groupMembers.groupId.equals(groupRow.id))
            ..orderBy([
              OrderingTerm.asc(_database.persons.isArchived),
              OrderingTerm.asc(_database.persons.name),
            ]))
          .get();

      final members = memberRows.map((row) {
        final person = row.readTable(_database.persons);
        return domain.Person(
          id: person.id,
          name: person.name,
          creationDate: person.creationDate,
          isArchived: person.isArchived,
        );
      }).toList();

      final expenseRows = await (_database.select(_database.expenses)
            ..where((expense) => expense.groupId.equals(groupRow.id))
            ..orderBy([(expense) => OrderingTerm.desc(expense.date)]))
          .get();
      final expenses = <domain.Expense>[];
      for (final expenseRow in expenseRows) {
        final participantRows = await (_database.select(_database.persons).join([
          innerJoin(
            _database.expenseParticipants,
            _database.expenseParticipants.personId.equalsExp(_database.persons.id),
          ),
        ])
              ..where(_database.expenseParticipants.expenseId.equals(expenseRow.id)))
            .get();
        final participants = participantRows
            .map((row) => _toPerson(row.readTable(_database.persons)))
            .toList();

        domain.Person? payer;
        final payerId = expenseRow.payerId;
        if (payerId != null) {
          final payerRow = await (_database.select(_database.persons)
                ..where((person) => person.id.equals(payerId)))
              .getSingleOrNull();
          if (payerRow != null) payer = _toPerson(payerRow);
        }

        final details = expenseRow.splitDetailsJson == null
            ? null
            : (jsonDecode(expenseRow.splitDetailsJson!) as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, (value as num).toDouble()),
              );

        expenses.add(
          domain.Expense(
            id: expenseRow.id,
            description: expenseRow.description,
            amount: expenseRow.amount,
            date: expenseRow.date,
            payer: payer,
            participants: participants,
            groupId: expenseRow.groupId,
            splitType: SplitType.values[expenseRow.splitType],
            splitDetails: details,
          ),
        );
      }

      groups.add(
        domain.Group(
          id: groupRow.id,
          name: groupRow.name,
          creationDate: groupRow.creationDate,
          iconName: groupRow.iconName,
          colorHex: groupRow.colorHex,
          members: members,
          expenses: expenses,
        ),
      );
    }

    return groups;
  }

  domain.Person _toPerson(Person person) => domain.Person(
        id: person.id,
        name: person.name,
        creationDate: person.creationDate,
        isArchived: person.isArchived,
      );
}
