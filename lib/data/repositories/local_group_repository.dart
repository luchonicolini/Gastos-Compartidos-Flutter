import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/group.dart' as domain;
import '../../domain/models/expense.dart' as domain;
import '../../domain/models/person.dart' as domain;
import '../../domain/models/currency.dart' as domain_currency;
import '../../domain/models/money.dart' as domain_money;
import '../../domain/models/split_type.dart';
import '../../domain/models/settlement_payment.dart' as domain_settlement;
import '../database/app_database.dart';

class LocalGroupRepository {
  LocalGroupRepository(this._database);

  final AppDatabase _database;

  Future<void> save(domain.Group group) async {
    await _database.transaction(() async {
      await _database
          .into(_database.groups)
          .insertOnConflictUpdate(
            GroupsCompanion.insert(
              id: group.id,
              name: group.name,
              creationDate: group.creationDate,
              iconName: Value(group.iconName),
              colorHex: Value(group.colorHex),
              referenceCurrencyCode: Value(group.referenceCurrency.code),
              isArchived: Value(group.isArchived),
              budgetCents: Value(group.budgetCents),
            ),
          );

      await (_database.delete(
        _database.groupMembers,
      )..where((member) => member.groupId.equals(group.id))).go();

      for (final member in group.members) {
        await _database
            .into(_database.persons)
            .insertOnConflictUpdate(
              PersonsCompanion.insert(
                id: member.id,
                name: member.name,
                creationDate: member.creationDate,
                isArchived: Value(member.isArchived),
              ),
            );

        await _database
            .into(_database.groupMembers)
            .insertOnConflictUpdate(
              GroupMembersCompanion.insert(
                groupId: group.id,
                personId: member.id,
              ),
            );
      }

      final oldExpenses = await (_database.select(
        _database.expenses,
      )..where((expense) => expense.groupId.equals(group.id))).get();
      for (final expense in oldExpenses) {
        await (_database.delete(
          _database.expenseParticipants,
        )..where((item) => item.expenseId.equals(expense.id))).go();
        await (_database.delete(
          _database.expenseSplits,
        )..where((item) => item.expenseId.equals(expense.id))).go();
        await (_database.delete(
          _database.expensePayers,
        )..where((item) => item.expenseId.equals(expense.id))).go();
        await (_database.delete(
          _database.expenses,
        )..where((item) => item.id.equals(expense.id))).go();
      }

      for (final expense in group.expenses) {
        await _database
            .into(_database.expenses)
            .insert(
              ExpensesCompanion.insert(
                id: expense.id,
                groupId: group.id,
                description: expense.description,
                amount: expense.amount,
                date: expense.date,
                payerId: Value(expense.payer?.id),
                splitType: expense.splitType.index,
                splitDetailsJson: Value(
                  expense.splitDetails == null
                      ? null
                      : jsonEncode(expense.splitDetails),
                ),
                originalAmountCents: Value(expense.originalAmount.cents),
                originalCurrencyCode: Value(expense.originalCurrency.code),
                referenceCurrencyCode: Value(expense.referenceCurrency.code),
                exchangeRate: Value(expense.exchangeRate),
                convertedAmountCents: Value(expense.convertedAmount.cents),
                category: Value(expense.category),
                notes: Value(expense.notes),
              ),
            );

        for (final payer in expense.payers) {
          await _database
              .into(_database.expensePayers)
              .insert(
                ExpensePayersCompanion.insert(
                  expenseId: expense.id,
                  personId: payer.person.id,
                  amountCents: payer.amount.cents,
                  currencyCode: payer.amount.currency.code,
                ),
              );
        }

        for (final participant in expense.participants) {
          await _database
              .into(_database.expenseParticipants)
              .insert(
                ExpenseParticipantsCompanion.insert(
                  expenseId: expense.id,
                  personId: participant.id,
                ),
              );
        }

        for (final entry
            in expense.splitDetails?.entries ??
                const <MapEntry<String, double>>[]) {
          await _database
              .into(_database.expenseSplits)
              .insert(
                ExpenseSplitsCompanion.insert(
                  expenseId: expense.id,
                  personId: entry.key,
                  value: entry.value,
                ),
              );
        }
      }

      await (_database.delete(
        _database.settlements,
      )..where((settlement) => settlement.groupId.equals(group.id))).go();
      for (final settlement in group.settlementPayments) {
        if (settlement.currency != group.referenceCurrency) {
          throw ArgumentError(
            'La liquidación ${settlement.id} debe usar la moneda de referencia del grupo.',
          );
        }
        await _database
            .into(_database.settlements)
            .insert(
              SettlementsCompanion.insert(
                id: settlement.id,
                groupId: group.id,
                payerId: settlement.payerId,
                payeeId: settlement.payeeId,
                payerName: settlement.payerName,
                payeeName: settlement.payeeName,
                amountCents: settlement.money.cents,
                currencyCode: settlement.currency.code,
                date: settlement.date,
              ),
            );
      }
    });
  }

  Future<void> delete(String groupId) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.groupMembers,
      )..where((member) => member.groupId.equals(groupId))).go();
      final expenses = await (_database.select(
        _database.expenses,
      )..where((expense) => expense.groupId.equals(groupId))).get();
      for (final expense in expenses) {
        await (_database.delete(
          _database.expenseParticipants,
        )..where((item) => item.expenseId.equals(expense.id))).go();
        await (_database.delete(
          _database.expenseSplits,
        )..where((item) => item.expenseId.equals(expense.id))).go();
        await (_database.delete(
          _database.expensePayers,
        )..where((item) => item.expenseId.equals(expense.id))).go();
      }
      await (_database.delete(
        _database.expenses,
      )..where((expense) => expense.groupId.equals(groupId))).go();
      await (_database.delete(
        _database.settlements,
      )..where((settlement) => settlement.groupId.equals(groupId))).go();
      await (_database.delete(
        _database.groups,
      )..where((group) => group.id.equals(groupId))).go();
    });
  }

  Future<void> clearAllData() async {
    await _database.transaction(() async {
      await _database.delete(_database.settlements).go();
      await _database.delete(_database.expenseParticipants).go();
      await _database.delete(_database.expenseSplits).go();
      await _database.delete(_database.expensePayers).go();
      await _database.delete(_database.expenses).go();
      await _database.delete(_database.groupMembers).go();
      await _database.delete(_database.persons).go();
      await _database.delete(_database.groups).go();
    });
  }

  /// Reemplaza todos los datos locales por [groups] en una sola transacción.
  ///
  /// Si algo falla durante la importación, se conserva la información que ya
  /// estaba guardada.
  Future<void> replaceAll(List<domain.Group> groups) async {
    await _database.transaction(() async {
      await clearAllData();
      for (final group in groups) {
        await save(group);
      }
    });
  }

  Future<List<domain.Group>> getAll({bool includeArchived = true}) async {
    final query = _database.select(_database.groups);
    if (!includeArchived) {
      query.where((g) => g.isArchived.equals(false));
    }
    query.orderBy([(group) => OrderingTerm.desc(group.creationDate)]);
    final groupRows = await query.get();

    final groups = <domain.Group>[];
    for (final groupRow in groupRows) {
      groups.add(await _loadGroup(groupRow));
    }
    return groups;
  }

  Future<domain.Group?> getById(String id) async {
    final groupRow = await (_database.select(_database.groups)
          ..where((g) => g.id.equals(id)))
        .getSingleOrNull();
    if (groupRow == null) return null;
    return _loadGroup(groupRow);
  }

  /// Emite la lista de grupos y se actualiza automáticamente ante cualquier cambio
  Stream<List<domain.Group>> watchAll({bool includeArchived = true}) async* {
    yield await getAll(includeArchived: includeArchived);
    yield* _database.tableUpdates().asyncMap((_) => getAll(includeArchived: includeArchived));
  }

  /// Emite un grupo específico y se actualiza reactivamente ante cualquier cambio
  Stream<domain.Group?> watchById(String id) async* {
    yield await getById(id);
    yield* _database.tableUpdates().asyncMap((_) => getById(id));
  }

  /// Operación granular: Guarda o actualiza un gasto específico sin reescribir todo el grupo
  Future<void> saveExpense(String groupId, domain.Expense expense) async {
    await _database.transaction(() async {
      await _database.into(_database.expenses).insertOnConflictUpdate(
        ExpensesCompanion.insert(
          id: expense.id,
          groupId: groupId,
          description: expense.description,
          amount: expense.amount,
          date: expense.date,
          payerId: Value(expense.payer?.id),
          splitType: expense.splitType.index,
          splitDetailsJson: Value(
            expense.splitDetails == null
                ? null
                : jsonEncode(expense.splitDetails),
          ),
          originalAmountCents: Value(expense.originalAmount.cents),
          originalCurrencyCode: Value(expense.originalCurrency.code),
          referenceCurrencyCode: Value(expense.referenceCurrency.code),
          exchangeRate: Value(expense.exchangeRate),
          convertedAmountCents: Value(expense.convertedAmount.cents),
          category: Value(expense.category),
          notes: Value(expense.notes),
        ),
      );

      // Limpiar relaciones anteriores de este gasto
      await (_database.delete(_database.expensePayers)
            ..where((item) => item.expenseId.equals(expense.id)))
          .go();
      await (_database.delete(_database.expenseParticipants)
            ..where((item) => item.expenseId.equals(expense.id)))
          .go();
      await (_database.delete(_database.expenseSplits)
            ..where((item) => item.expenseId.equals(expense.id)))
          .go();

      // Insertar pagadores
      for (final payer in expense.payers) {
        await _database.into(_database.expensePayers).insert(
          ExpensePayersCompanion.insert(
            expenseId: expense.id,
            personId: payer.person.id,
            amountCents: payer.amount.cents,
            currencyCode: payer.amount.currency.code,
          ),
        );
      }

      // Insertar participantes
      for (final participant in expense.participants) {
        await _database.into(_database.expenseParticipants).insert(
          ExpenseParticipantsCompanion.insert(
            expenseId: expense.id,
            personId: participant.id,
          ),
        );
      }

      // Insertar splits
      for (final entry in expense.splitDetails?.entries ??
          const <MapEntry<String, double>>[]) {
        await _database.into(_database.expenseSplits).insert(
          ExpenseSplitsCompanion.insert(
            expenseId: expense.id,
            personId: entry.key,
            value: entry.value,
          ),
        );
      }
    });
  }

  /// Operación granular: Elimina un gasto puntual y sus relaciones
  Future<void> deleteExpense(String expenseId) async {
    await _database.transaction(() async {
      await (_database.delete(_database.expensePayers)
            ..where((item) => item.expenseId.equals(expenseId)))
          .go();
      await (_database.delete(_database.expenseParticipants)
            ..where((item) => item.expenseId.equals(expenseId)))
          .go();
      await (_database.delete(_database.expenseSplits)
            ..where((item) => item.expenseId.equals(expenseId)))
          .go();
      await (_database.delete(_database.expenses)
            ..where((item) => item.id.equals(expenseId)))
          .go();
    });
  }

  /// Operación granular: Agrega un nuevo miembro al grupo
  Future<void> addMember(String groupId, domain.Person member) async {
    await _database.transaction(() async {
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
          groupId: groupId,
          personId: member.id,
        ),
      );
    });
  }

  /// Operación granular: Actualiza los datos de un miembro (nombre, archivo)
  Future<void> updateMember(domain.Person member) async {
    await _database.into(_database.persons).insertOnConflictUpdate(
      PersonsCompanion.insert(
        id: member.id,
        name: member.name,
        creationDate: member.creationDate,
        isArchived: Value(member.isArchived),
      ),
    );
  }

  /// Operación granular: Guarda una liquidación/pago
  Future<void> saveSettlement(
    String groupId,
    domain_settlement.SettlementPayment settlement,
  ) async {
    await _database.into(_database.settlements).insertOnConflictUpdate(
      SettlementsCompanion.insert(
        id: settlement.id,
        groupId: groupId,
        payerId: settlement.payerId,
        payeeId: settlement.payeeId,
        payerName: settlement.payerName,
        payeeName: settlement.payeeName,
        amountCents: settlement.money.cents,
        currencyCode: settlement.currency.code,
        date: settlement.date,
      ),
    );
  }

  /// Operación granular: Elimina una liquidación
  Future<void> deleteSettlement(String settlementId) async {
    await (_database.delete(_database.settlements)
          ..where((item) => item.id.equals(settlementId)))
        .go();
  }

  /// Operación granular: Archiva o desarchiva un grupo
  Future<void> setGroupArchived(String groupId, bool archived) async {
    await (_database.update(_database.groups)
          ..where((g) => g.id.equals(groupId)))
        .write(GroupsCompanion(isArchived: Value(archived)));
  }

  Future<domain.Group> _loadGroup(Group groupRow) async {
    final memberRows =
        await (_database.select(_database.persons).join([
                innerJoin(
                  _database.groupMembers,
                  _database.groupMembers.personId.equalsExp(
                    _database.persons.id,
                  ),
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

    final expenseRows =
        await (_database.select(_database.expenses)
              ..where((expense) => expense.groupId.equals(groupRow.id))
              ..orderBy([(expense) => OrderingTerm.desc(expense.date)]))
            .get();
    final expenses = <domain.Expense>[];
    for (final expenseRow in expenseRows) {
      final participantRows =
          await (_database.select(_database.persons).join([
                innerJoin(
                  _database.expenseParticipants,
                  _database.expenseParticipants.personId.equalsExp(
                    _database.persons.id,
                  ),
                ),
              ])..where(
                _database.expenseParticipants.expenseId.equals(expenseRow.id),
              ))
              .get();
      final participants = participantRows
          .map((row) => _toPerson(row.readTable(_database.persons)))
          .toList();

      final payerRows =
          await (_database.select(_database.persons).join([
                innerJoin(
                  _database.expensePayers,
                  _database.expensePayers.personId.equalsExp(
                    _database.persons.id,
                  ),
                ),
              ])..where(
                _database.expensePayers.expenseId.equals(expenseRow.id),
              ))
              .get();
      final payers = payerRows.map((row) {
        final person = _toPerson(row.readTable(_database.persons));
        final payer = row.readTable(_database.expensePayers);
        return domain.ExpensePayer(
          person: person,
          amount: domain_money.Money(
            cents: payer.amountCents,
            currency: domain_currency.Currency.fromCode(payer.currencyCode),
          ),
        );
      }).toList();

      domain.Person? payer;
      final payerId = expenseRow.payerId;
      if (payerId != null) {
        final payerRow = await (_database.select(
          _database.persons,
        )..where((person) => person.id.equals(payerId))).getSingleOrNull();
        if (payerRow != null) payer = _toPerson(payerRow);
      }

      final details = expenseRow.splitDetailsJson == null
          ? null
          : (jsonDecode(expenseRow.splitDetailsJson!) as Map<String, dynamic>)
                .map(
                  (key, value) => MapEntry(key, (value as num).toDouble()),
                );

      final effectiveConvertedCents = expenseRow.convertedAmountCents > 0
          ? expenseRow.convertedAmountCents
          : (expenseRow.amount * 100).round();
      final effectiveOriginalCents = expenseRow.originalAmountCents > 0
          ? expenseRow.originalAmountCents
          : (expenseRow.amount * 100).round();

      expenses.add(
        domain.Expense(
          id: expenseRow.id,
          description: expenseRow.description,
          amount: expenseRow.amount,
          date: expenseRow.date,
          payer: payer,
          payers: payers.isNotEmpty
              ? payers
              : payer == null
              ? const []
              : [
                  domain.ExpensePayer(
                    person: payer,
                    amount: domain_money.Money(
                      cents: effectiveConvertedCents,
                      currency: domain_currency.Currency.fromCode(
                        expenseRow.referenceCurrencyCode,
                      ),
                    ),
                  ),
                ],
          participants: participants,
          groupId: expenseRow.groupId,
          splitType: SplitType.values[expenseRow.splitType],
          splitDetails: details,
          originalAmount: domain_money.Money(
            cents: effectiveOriginalCents,
            currency: domain_currency.Currency.fromCode(
              expenseRow.originalCurrencyCode,
            ),
          ),
          originalCurrency: domain_currency.Currency.fromCode(
            expenseRow.originalCurrencyCode,
          ),
          convertedAmount: domain_money.Money(
            cents: effectiveConvertedCents,
            currency: domain_currency.Currency.fromCode(
              expenseRow.referenceCurrencyCode,
            ),
          ),
          referenceCurrency: domain_currency.Currency.fromCode(
            expenseRow.referenceCurrencyCode,
          ),
          exchangeRate: expenseRow.exchangeRate,
          category: expenseRow.category,
          notes: expenseRow.notes,
        ),
      );
    }

    final settlementRows =
        await (_database.select(_database.settlements)
              ..where((settlement) => settlement.groupId.equals(groupRow.id))
              ..orderBy([(settlement) => OrderingTerm.desc(settlement.date)]))
            .get();
    final settlements = settlementRows
        .map(
          (row) => domain_settlement.SettlementPayment(
            id: row.id,
            payerId: row.payerId,
            payeeId: row.payeeId,
            payerName: row.payerName,
            payeeName: row.payeeName,
            money: domain_money.Money(
              cents: row.amountCents,
              currency: domain_currency.Currency.fromCode(row.currencyCode),
            ),
            date: row.date,
            groupId: row.groupId,
          ),
        )
        .toList();

    return domain.Group(
      id: groupRow.id,
      name: groupRow.name,
      creationDate: groupRow.creationDate,
      iconName: groupRow.iconName,
      colorHex: groupRow.colorHex,
      referenceCurrency: domain_currency.Currency.fromCode(
        groupRow.referenceCurrencyCode,
      ),
      members: members,
      expenses: expenses,
      settlementPayments: settlements,
      isArchived: groupRow.isArchived,
      budgetCents: groupRow.budgetCents,
    );
  }

  domain.Person _toPerson(Person person) => domain.Person(
    id: person.id,
    name: person.name,
    creationDate: person.creationDate,
    isArchived: person.isArchived,
  );
}
