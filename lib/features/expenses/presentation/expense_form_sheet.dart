import 'package:flutter/material.dart';

import '../../../domain/models/expense.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/person.dart';
import '../../../domain/models/split_type.dart';
import '../../../logic/expense_validator.dart';

class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({super.key, required this.group, this.initialExpense});

  final Group group;
  final Expense? initialExpense;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late DateTime _date;
  late Person? _payer;
  late Set<String> _selectedParticipantIds;
  late SplitType _splitType;
  final Map<String, TextEditingController> _detailControllers = {};
  String? _errorText;

  List<Person> get _activeMembers =>
      widget.group.members.where((member) => !member.isArchived).toList();

  List<Person> get _availableMembers {
    final members = [..._activeMembers];
    final existingExpense = widget.initialExpense;
    if (existingExpense != null) {
      for (final member in [...existingExpense.participants, if (existingExpense.payer != null) existingExpense.payer!]) {
        if (!members.any((item) => item.id == member.id)) members.add(member);
      }
    }
    return members;
  }

  @override
  void initState() {
    super.initState();
    final expense = widget.initialExpense;
    _descriptionController = TextEditingController(text: expense?.description ?? '');
    _amountController = TextEditingController(
      text: expense == null ? '' : expense.amount.toStringAsFixed(2),
    );
    _date = expense?.date ?? DateTime.now();
    _payer = expense?.payer ?? (_activeMembers.isEmpty ? null : _activeMembers.first);
    _selectedParticipantIds = expense == null
        ? _activeMembers.map((member) => member.id).toSet()
        : expense.participants.map((member) => member.id).toSet();
    _splitType = expense?.splitType ?? SplitType.equally;

    for (final entry in expense?.splitDetails?.entries ?? const <MapEntry<String, double>>[]) {
      _detailControllers[entry.key] = TextEditingController(text: entry.value.toString());
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    for (final controller in _detailControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String personId) {
    return _detailControllers.putIfAbsent(personId, () => TextEditingController());
  }

  void _toggleParticipant(Person member, bool selected) {
    setState(() {
      if (selected) {
        _selectedParticipantIds.add(member.id);
      } else {
        _selectedParticipantIds.remove(member.id);
        if (_payer?.id == member.id) _payer = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;
    final participants = _availableMembers
        .where((member) => _selectedParticipantIds.contains(member.id))
        .toList();
    final details = _splitType == SplitType.equally
        ? null
        : {
            for (final member in participants)
              member.id: double.tryParse(_controllerFor(member.id).text.replaceAll(',', '.')) ?? 0,
          };
    final error = ExpenseValidator.validate(
      description: _descriptionController.text,
      amount: amount,
      payer: _payer,
      participants: participants,
      splitType: _splitType,
      splitDetails: details,
    );
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    Navigator.of(context).pop(
      Expense(
        id: widget.initialExpense?.id,
        description: _descriptionController.text.trim(),
        amount: amount,
        date: _date,
        payer: _payer,
        participants: participants,
        groupId: widget.group.id,
        splitType: _splitType,
        splitDetails: details,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final participants = _availableMembers
        .where((member) => _selectedParticipantIds.contains(member.id))
        .toList();
    final isEditing = widget.initialExpense != null;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.92,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Text(isEditing ? 'Editar gasto' : 'Nuevo gasto', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  TextField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Descripción', prefixIcon: Icon(Icons.receipt_long_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Monto', prefixText: r'$ ', prefixIcon: Icon(Icons.payments_outlined)),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Fecha'),
                    subtitle: Text('${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickDate,
                  ),
                  DropdownButtonFormField<Person>(
                    initialValue: _payer,
                    decoration: const InputDecoration(labelText: 'Pagó', prefixIcon: Icon(Icons.person_outline)),
                    items: _availableMembers
                        .map((member) => DropdownMenuItem(value: member, child: Text(member.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _payer = value),
                  ),
                  const SizedBox(height: 20),
                  const Text('Participantes', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableMembers
                        .map(
                          (member) => FilterChip(
                            label: Text(member.name),
                            selected: _selectedParticipantIds.contains(member.id),
                            onSelected: (selected) => _toggleParticipant(member, selected),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<SplitType>(
                    initialValue: _splitType,
                    decoration: const InputDecoration(labelText: 'Forma de dividir', prefixIcon: Icon(Icons.call_split_outlined)),
                    items: SplitType.values
                        .map((type) => DropdownMenuItem(value: type, child: Text(type.localizedDescription)))
                        .toList(),
                    onChanged: (value) => setState(() => _splitType = value ?? SplitType.equally),
                  ),
                  if (_splitType != SplitType.equally) ...[
                    const SizedBox(height: 16),
                    ...participants.map((member) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextField(
                            controller: _controllerFor(member.id),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: '${member.name} (${_splitType == SplitType.byAmount ? r'$' : _splitType == SplitType.byPercentage ? '%' : 'partes'})',
                            ),
                          ),
                        )),
                  ],
                  if (_errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
            FilledButton(onPressed: _submit, child: Text(isEditing ? 'Guardar cambios' : 'Guardar gasto')),
          ],
        ),
      ),
    );
  }
}
