import 'package:drift/drift.dart';

import '../../domain/models/group.dart' as domain;
import '../../domain/models/person.dart' as domain;
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

      groups.add(
        domain.Group(
          id: groupRow.id,
          name: groupRow.name,
          creationDate: groupRow.creationDate,
          iconName: groupRow.iconName,
          colorHex: groupRow.colorHex,
          members: members,
        ),
      );
    }

    return groups;
  }
}
