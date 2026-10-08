import 'package:flutter/material.dart';

import '../../../data/repositories/local_group_repository.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/expense.dart';
import '../../../domain/models/person.dart';
import '../../expenses/presentation/expense_form_sheet.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.group, required this.repository});

  final Group group;
  final LocalGroupRepository repository;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Group _group;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  Future<void> _saveGroup(Group group) async {
    await widget.repository.save(group);
    if (!mounted) return;
    setState(() => _group = group);
  }

  Future<void> _addMember() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _MemberFormSheet(),
    );
    if (name == null) return;

    final alreadyExists = _group.members.any(
      (member) => member.name.toLowerCase() == name.toLowerCase(),
    );
    if (alreadyExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya existe un miembro con ese nombre.')),
        );
      }
      return;
    }

    await _saveGroup(_group.copyWith(members: [..._group.members, Person(name: name)]));
  }

  Future<void> _toggleArchive(Person member) async {
    final action = member.isArchived ? 'reactivar' : 'archivar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${member.isArchived ? 'Reactivar' : 'Archivar'} miembro'),
        content: Text('¿Querés $action a ${member.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: Text(member.isArchived ? 'Reactivar' : 'Archivar')),
        ],
      ),
    );
    if (confirmed != true) return;

    final members = _group.members
        .map((item) => item.id == member.id ? item.copyWith(isArchived: !item.isArchived) : item)
        .toList();
    await _saveGroup(_group.copyWith(members: members));
  }

  Future<void> _addExpense() async {
    final expense = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ExpenseFormSheet(group: _group),
    );
    if (expense == null) return;
    await _saveGroup(_group.copyWith(expenses: [..._group.expenses, expense]));
  }

  Future<void> _editExpense(Expense expense) async {
    final updated = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ExpenseFormSheet(group: _group, initialExpense: expense),
    );
    if (updated == null) return;
    final expenses = _group.expenses.map((item) => item.id == updated.id ? updated : item).toList();
    await _saveGroup(_group.copyWith(expenses: expenses));
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Querés eliminar “${expense.description}”?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _saveGroup(_group.copyWith(expenses: _group.expenses.where((item) => item.id != expense.id).toList()));
  }

  @override
  Widget build(BuildContext context) {
    final activeMembers = _group.members.where((member) => !member.isArchived).toList();
    final archivedMembers = _group.members.where((member) => member.isArchived).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_group.name),
        actions: [
          IconButton(onPressed: _addExpense, icon: const Icon(Icons.add_card_outlined), tooltip: 'Agregar gasto'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          _SummaryCard(group: _group),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Miembros', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text('${activeMembers.length} activos', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 8),
          if (activeMembers.isEmpty)
            const _InfoTile(icon: Icons.person_off_outlined, text: 'No hay miembros activos.')
          else
            ...activeMembers.map((member) => _MemberTile(member: member, onToggle: () => _toggleArchive(member))),
          if (archivedMembers.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Archivados', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...archivedMembers.map((member) => _MemberTile(member: member, onToggle: () => _toggleArchive(member))),
          ],
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gastos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text('${_group.expenses.length}', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 8),
          if (_group.expenses.isEmpty)
            const _InfoTile(icon: Icons.receipt_long_outlined, text: 'Todavía no hay gastos.')
          else
            ..._group.expenses.map(
              (expense) => _ExpenseTile(
                expense: expense,
                onEdit: () => _editExpense(expense),
                onDelete: () => _deleteExpense(expense),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMember,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Agregar miembro'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(Icons.groups_outlined, size: 28, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Creado localmente', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onToggle});

  final Person member;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text(member.name.characters.first.toUpperCase())),
        title: Text(member.name),
        subtitle: member.isArchived ? const Text('Conserva su historial') : null,
        trailing: TextButton(
          onPressed: onToggle,
          child: Text(member.isArchived ? 'Reactivar' : 'Archivar'),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(child: ListTile(leading: Icon(icon), title: Text(text)));
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.onEdit, required this.onDelete});

  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
        title: Text(expense.description),
        subtitle: Text(
          'Pagó ${expense.payer?.name ?? (expense.payers.length > 1 ? 'varias personas' : 'Sin definir')} • '
          '${expense.originalCurrency.symbol}${expense.originalAmount.decimalValue.toStringAsFixed(2)} ${expense.originalCurrency.code} • '
          '${expense.splitType.localizedDescription}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\$${expense.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberFormSheet extends StatefulWidget {
  const _MemberFormSheet();

  @override
  State<_MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends State<_MemberFormSheet> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Ingresá un nombre');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 20),
          Text('Agregar miembro', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(labelText: 'Nombre', hintText: 'Ej. Ana', errorText: _errorText, prefixIcon: const Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _submit, child: const Text('Agregar')),
        ],
      ),
    );
  }
}
