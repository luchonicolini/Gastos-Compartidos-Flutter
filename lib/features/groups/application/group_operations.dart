import '../../../data/repositories/local_group_repository.dart';
import '../../../domain/models/currency.dart';
import '../../../domain/models/expense.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/person.dart';
import '../../../domain/models/settlement_payment.dart';

/// Data changes previously coordinated by the retired screens.
class GroupOperations {
  const GroupOperations(this.repository);

  final LocalGroupRepository repository;

  Future<List<Group>> listGroups() => repository.getAll();

  Future<Group> createGroup({
    required String name,
    String? iconName,
    String? colorHex,
  }) async {
    final group = Group(
      name: _requiredName(name),
      iconName: iconName,
      colorHex: colorHex,
    );
    await repository.save(group);
    return group;
  }

  Future<Group> editGroup(
    Group group, {
    required String name,
    String? iconName,
    String? colorHex,
    Currency? referenceCurrency,
  }) async {
    final updated = group.copyWith(
      name: _requiredName(name),
      iconName: iconName ?? group.iconName,
      colorHex: colorHex ?? group.colorHex,
      referenceCurrency: referenceCurrency ?? group.referenceCurrency,
    );
    await repository.save(updated);
    return updated;
  }

  Future<void> deleteGroup(Group group) => repository.delete(group.id);

  Future<Group> addMember(Group group, String name) async {
    final cleaned = _requiredName(name);
    if (group.members.any(
      (member) => member.name.toLowerCase() == cleaned.toLowerCase(),
    )) {
      throw ArgumentError.value(
        name,
        'name',
        'Ya existe un miembro con ese nombre',
      );
    }
    final newMember = Person(name: cleaned);
    await repository.addMember(group.id, newMember);
    final updated = await repository.getById(group.id);
    return updated ?? group;
  }

  Future<Group> setMemberArchived(Group group, String memberId, bool archived) async {
    final member = group.members.firstWhere(
      (m) => m.id == memberId,
      orElse: () =>
          throw ArgumentError.value(memberId, 'memberId', 'Miembro inexistente'),
    );
    await repository.updateMember(member.copyWith(isArchived: archived));
    final updated = await repository.getById(group.id);
    return updated ?? group;
  }

  Future<Group> editMember(
    Group group,
    String memberId,
    String newName,
  ) async {
    final cleaned = _requiredName(newName);
    if (!group.members.any((member) => member.id == memberId)) {
      throw ArgumentError.value(memberId, 'memberId', 'Miembro inexistente');
    }
    if (group.members.any(
      (member) =>
          member.id != memberId &&
          member.name.toLowerCase() == cleaned.toLowerCase(),
    )) {
      throw ArgumentError.value(
        newName,
        'name',
        'Ya existe un miembro con ese nombre',
      );
    }
    final member = group.members.firstWhere((m) => m.id == memberId);
    await repository.updateMember(member.copyWith(name: cleaned));
    final updated = await repository.getById(group.id);
    return updated ?? group;
  }

  Future<Group> saveExpense(Group group, Expense expense) async {
    if (expense.groupId != group.id) {
      throw ArgumentError.value(
        expense.groupId,
        'groupId',
        'El gasto pertenece a otro grupo',
      );
    }
    await repository.saveExpense(group.id, expense);
    final updated = await repository.getById(group.id);
    return updated ?? group;
  }

  Future<Group> deleteExpense(Group group, String expenseId) async {
    await repository.deleteExpense(expenseId);
    final updated = await repository.getById(group.id);
    return updated ?? group;
  }

  Future<Group> confirmSettlement(
    Group group,
    FormattedSettlement settlement, {
    DateTime? date,
  }) async {
    final payment = SettlementPayment(
      payerId: settlement.payerId,
      payeeId: settlement.payeeId,
      money: Money.fromDecimal(settlement.amount, group.referenceCurrency),
      groupId: group.id,
      payerName: settlement.payerName,
      payeeName: settlement.payeeName,
      date: date,
    );
    await repository.saveSettlement(group.id, payment);
    final updated = await repository.getById(group.id);
    return updated ?? group;
  }

  Future<Group> deleteSettlement(Group group, String paymentId) async {
    await repository.deleteSettlement(paymentId);
    final updated = await repository.getById(group.id);
    return updated ?? group;
  }

  Future<Group> setGroupArchived(Group group, bool archived) async {
    await repository.setGroupArchived(group.id, archived);
    final updated = await repository.getById(group.id);
    return updated ?? group;
  }

  static String _requiredName(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) {
      throw ArgumentError.value(value, 'name', 'El nombre es obligatorio');
    }
    return cleaned;
  }
}
