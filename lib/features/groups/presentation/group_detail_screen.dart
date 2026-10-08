import 'package:flutter/material.dart';

import '../../../data/repositories/local_group_repository.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/expense.dart';
import '../../../domain/models/currency.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/member_balance.dart';
import '../../../domain/models/person.dart';
import '../../../domain/models/settlement_payment.dart';
import '../../../logic/balance_calculator.dart';
import '../../../logic/settlement_calculator.dart';
import '../../../core/theme/app_tokens.dart';
import '../../expenses/presentation/expense_form_sheet.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.repository,
  });

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

    await _saveGroup(
      _group.copyWith(
        members: [
          ..._group.members,
          Person(name: name),
        ],
      ),
    );
  }

  Future<void> _toggleArchive(Person member) async {
    final action = member.isArchived ? 'reactivar' : 'archivar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${member.isArchived ? 'Reactivar' : 'Archivar'} miembro'),
        content: Text('¿Querés $action a ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(member.isArchived ? 'Reactivar' : 'Archivar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final members = _group.members
        .map(
          (item) => item.id == member.id
              ? item.copyWith(isArchived: !item.isArchived)
              : item,
        )
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
    final expenses = _group.expenses
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    await _saveGroup(_group.copyWith(expenses: expenses));
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Querés eliminar “${expense.description}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _saveGroup(
      _group.copyWith(
        expenses: _group.expenses
            .where((item) => item.id != expense.id)
            .toList(),
      ),
    );
  }

  Future<void> _confirmSettlement(FormattedSettlement settlement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar pago'),
        content: Text(
          '${settlement.payerName} le pagó a ${settlement.payeeName} ${settlement.formattedAmount}. ¿Querés registrarlo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final payment = SettlementPayment(
      payerId: settlement.payerId,
      payeeId: settlement.payeeId,
      money: Money.fromDecimal(settlement.amount, _group.referenceCurrency),
      groupId: _group.id,
      payerName: settlement.payerName,
      payeeName: settlement.payeeName,
    );
    await _saveGroup(
      _group.copyWith(
        settlementPayments: [..._group.settlementPayments, payment],
      ),
    );
  }

  Future<void> _deleteSettlement(SettlementPayment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar pago registrado'),
        content: Text(
          '¿Querés quitar el pago de ${payment.payerName} a ${payment.payeeName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _saveGroup(
      _group.copyWith(
        settlementPayments: _group.settlementPayments
            .where((item) => item.id != payment.id)
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMembers = _group.members
        .where((member) => !member.isArchived)
        .toList();
    final archivedMembers = _group.members
        .where((member) => member.isArchived)
        .toList();
    final balances = BalanceCalculator.calculateMemberBalances(_group);
    final pendingSettlements = SettlementCalculator.suggestFormattedSettlements(
      balances,
      referenceCurrency: _group.referenceCurrency,
    );
    final isSettled =
        balances.isNotEmpty && balances.every((balance) => balance.isNeutral);

    return Scaffold(
      appBar: AppBar(
        title: Text(_group.name),
        actions: [
          IconButton(
            onPressed: _addExpense,
            icon: const Icon(Icons.add_card_outlined),
            tooltip: 'Agregar gasto',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 720 ? 32.0 : 16.0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  100,
                ),
                children: [
                  _SummaryCard(group: _group),
                  const SizedBox(height: 24),
                  Text(
                    '¿Cómo vamos?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_group.members.isEmpty)
                    const _InfoTile(
                      icon: Icons.insights_outlined,
                      text: 'Agregá miembros para ver balances.',
                    )
                  else if (_group.expenses.isEmpty)
                    const _InfoTile(
                      icon: Icons.insights_outlined,
                      text: 'Agregá un gasto para calcular balances.',
                    )
                  else ...[
                    if (isSettled)
                      const _SettledCard()
                    else
                      ...balances.map(
                        (balance) => _BalanceTile(
                          balance: balance,
                          currency: _group.referenceCurrency,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Pagos sugeridos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (pendingSettlements.isEmpty)
                      const _InfoTile(
                        icon: Icons.check_circle_outline,
                        text: 'No hay pagos pendientes.',
                      )
                    else
                      ...pendingSettlements.map(
                        (settlement) => _SuggestedSettlementTile(
                          settlement: settlement,
                          onConfirm: () => _confirmSettlement(settlement),
                        ),
                      ),
                  ],
                  if (_group.settlementPayments.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Pagos registrados',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._group.settlementPayments.map(
                      (payment) => _SettlementHistoryTile(
                        payment: payment,
                        onDelete: () => _deleteSettlement(payment),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Miembros',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${activeMembers.length} activos',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (activeMembers.isEmpty)
                    const _InfoTile(
                      icon: Icons.person_off_outlined,
                      text: 'No hay miembros activos.',
                    )
                  else
                    ...activeMembers.map(
                      (member) => _MemberTile(
                        member: member,
                        onToggle: () => _toggleArchive(member),
                      ),
                    ),
                  if (archivedMembers.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Archivados',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...archivedMembers.map(
                      (member) => _MemberTile(
                        member: member,
                        onToggle: () => _toggleArchive(member),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gastos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_group.expenses.length}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_group.expenses.isEmpty)
                    const _InfoTile(
                      icon: Icons.receipt_long_outlined,
                      text: 'Todavía no hay gastos.',
                    )
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
            ),
          );
        },
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
    final colors = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final total = group.expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    return Card(
      color: tokens.surfaceSecondary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(
                    Icons.groups_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Total registrado',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: tokens.labelSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '${group.referenceCurrency.symbol}${total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${group.expenses.length} ${group.expenses.length == 1 ? 'gasto' : 'gastos'} · ${group.referenceCurrency.code}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.labelSecondary),
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
        leading: CircleAvatar(
          child: Text(member.name.characters.first.toUpperCase()),
        ),
        title: Text(member.name),
        subtitle: member.isArchived
            ? const Text('Conserva su historial')
            : null,
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
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(text),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.balance, required this.currency});

  final MemberBalance balance;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = balance.isCreditor
        ? colors.tertiary
        : balance.isDebtor
        ? colors.error
        : colors.onSurfaceVariant;
    final sign = balance.balance > 0 ? '+' : '';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(balance.name.characters.first.toUpperCase()),
        ),
        title: Text(balance.name),
        trailing: Text(
          '$sign${currency.symbol}${balance.balance.abs().toStringAsFixed(2)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _SuggestedSettlementTile extends StatelessWidget {
  const _SuggestedSettlementTile({
    required this.settlement,
    required this.onConfirm,
  });

  final FormattedSettlement settlement;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.arrow_forward_rounded, color: colors.tertiary),
        title: Text('${settlement.payerName} → ${settlement.payeeName}'),
        subtitle: Text(settlement.formattedAmount),
        trailing: TextButton(
          onPressed: onConfirm,
          child: const Text('Confirmar'),
        ),
      ),
    );
  }
}

class _SettlementHistoryTile extends StatelessWidget {
  const _SettlementHistoryTile({required this.payment, required this.onDelete});

  final SettlementPayment payment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.check_circle, color: colors.tertiary),
        title: Text('${payment.payerName} → ${payment.payeeName}'),
        subtitle: const Text('Pago registrado'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${payment.currency.symbol}${payment.amount.toStringAsFixed(2)}',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar pago',
            ),
          ],
        ),
      ),
    );
  }
}

class _SettledCard extends StatelessWidget {
  const _SettledCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.tertiaryContainer,
      child: ListTile(
        leading: Icon(
          Icons.celebration_outlined,
          color: colors.onTertiaryContainer,
        ),
        title: const Text(
          'Viaje saldado',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Nadie le debe dinero a nadie.'),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

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
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      _focusNode.requestFocus();
      return;
    }
    final name = _controller.text.trim();
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.tokens.separator,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Agregar miembro',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey<String>('close-member-form'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancelar',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey<String>('member-name-field'),
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresá un nombre'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Ana',
                  helperText: ' ',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const ValueKey<String>('save-member-form'),
                onPressed: _submit,
                child: const Text('Agregar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
