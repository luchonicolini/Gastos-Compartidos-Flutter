import 'package:flutter/material.dart';

import '../../../domain/models/expense.dart';
import '../../../domain/models/currency.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/money.dart';
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
  late Currency _originalCurrency;
  late final TextEditingController _exchangeRateController;
  late Set<String> _selectedPayerIds;
  late Set<String> _selectedParticipantIds;
  late SplitType _splitType;
  final Map<String, TextEditingController> _detailControllers = {};
  final Map<String, TextEditingController> _payerAmountControllers = {};
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

  List<Person> get _availablePayers => _availableMembers;

  @override
  void initState() {
    super.initState();
    final expense = widget.initialExpense;
    _descriptionController = TextEditingController(text: expense?.description ?? '');
    _amountController = TextEditingController(
      text: expense == null ? '' : expense.originalAmount.decimalValue.toStringAsFixed(2),
    );
    _originalCurrency = expense?.originalCurrency ?? widget.group.referenceCurrency;
    _exchangeRateController = TextEditingController(
      text: expense == null || _originalCurrency == widget.group.referenceCurrency
          ? '1'
          : expense.exchangeRate.toString(),
    );
    _date = expense?.date ?? DateTime.now();
    _selectedPayerIds = expense != null && expense.payers.isNotEmpty
        ? expense.payers.map((payer) => payer.person.id).toSet()
        : (_activeMembers.isEmpty ? <String>{} : {_activeMembers.first.id});
    _selectedParticipantIds = expense == null
        ? _activeMembers.map((member) => member.id).toSet()
        : expense.participants.map((member) => member.id).toSet();
    _splitType = expense?.splitType ?? SplitType.equally;

    for (final entry in expense?.splitDetails?.entries ?? const <MapEntry<String, double>>[]) {
      _detailControllers[entry.key] = TextEditingController(text: entry.value.toString());
    }
    for (final payer in expense?.payers ?? const <ExpensePayer>[]) {
      _payerAmountControllers[payer.person.id] = TextEditingController(
        text: payer.amount.decimalValue.toStringAsFixed(2),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _exchangeRateController.dispose();
    for (final controller in _detailControllers.values) {
      controller.dispose();
    }
    for (final controller in _payerAmountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String personId) {
    return _detailControllers.putIfAbsent(personId, () => TextEditingController());
  }

  void _togglePayer(Person member, bool selected) {
    setState(() {
      if (selected) {
        _selectedPayerIds.add(member.id);
      } else {
        _selectedPayerIds.remove(member.id);
      }
    });
  }

  void _toggleParticipant(Person member, bool selected) {
    setState(() {
      if (selected) {
        _selectedParticipantIds.add(member.id);
      } else {
        _selectedParticipantIds.remove(member.id);
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
    final originalAmountValue = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;
    final originalAmount = Money.fromDecimal(originalAmountValue, _originalCurrency);
    final referenceCurrency = widget.group.referenceCurrency;
    final exchangeRate = _originalCurrency == referenceCurrency
        ? 1.0
        : double.tryParse(_exchangeRateController.text.trim().replaceAll(',', '.')) ?? 0;
    final convertedAmount = originalAmount.convertTo(referenceCurrency, exchangeRate);
    final amount = convertedAmount.decimalValue;
    final participants = _availableMembers
        .where((member) => _selectedParticipantIds.contains(member.id))
        .toList();
    final selectedPayers = _availablePayers
        .where((member) => _selectedPayerIds.contains(member.id))
        .toList();
    final payers = selectedPayers.map((member) {
      final payerAmount = selectedPayers.length == 1
          ? Money.fromDecimal(amount, referenceCurrency)
          : Money.fromDecimal(
              double.tryParse(_payerAmountControllers[member.id]?.text.replaceAll(',', '.') ?? '0') ?? 0,
              referenceCurrency,
            );
      return ExpensePayer(person: member, amount: payerAmount);
    }).toList();
    final details = _splitType == SplitType.equally
        ? null
        : {
            for (final member in participants)
              member.id: double.tryParse(_controllerFor(member.id).text.replaceAll(',', '.')) ?? 0,
          };
    final error = ExpenseValidator.validate(
      description: _descriptionController.text,
      amount: amount,
      payer: selectedPayers.length == 1 ? selectedPayers.first : null,
      payers: payers,
      participants: participants,
      splitType: _splitType,
      splitDetails: details,
      referenceCurrency: referenceCurrency,
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
        originalAmount: originalAmount,
        originalCurrency: _originalCurrency,
        convertedAmount: convertedAmount,
        referenceCurrency: referenceCurrency,
        exchangeRate: exchangeRate,
        date: _date,
        payer: selectedPayers.length == 1 ? selectedPayers.first : null,
        payers: payers,
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
                    decoration: InputDecoration(
                      labelText: 'Importe original (${_originalCurrency.code})',
                      prefixText: '${_originalCurrency.symbol} ',
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Currency>(
                    initialValue: _originalCurrency,
                    decoration: const InputDecoration(labelText: 'Moneda del gasto', prefixIcon: Icon(Icons.currency_exchange_outlined)),
                    items: Currency.supported
                        .map((currency) => DropdownMenuItem(value: currency, child: Text('${currency.code} — ${currency.name}')))
                        .toList(),
                    onChanged: (value) => setState(() {
                      _originalCurrency = value ?? Currency.ars;
                      if (_originalCurrency == widget.group.referenceCurrency) _exchangeRateController.text = '1';
                    }),
                  ),
                  if (_originalCurrency != widget.group.referenceCurrency) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _exchangeRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: '1 ${_originalCurrency.code} = ? ${widget.group.referenceCurrency.code}', prefixIcon: const Icon(Icons.swap_horiz)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Fecha'),
                    subtitle: Text('${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickDate,
                  ),
                  const Text('Pagaron', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availablePayers
                        .map(
                          (member) => FilterChip(
                            label: Text(member.name),
                            selected: _selectedPayerIds.contains(member.id),
                            onSelected: (selected) => _togglePayer(member, selected),
                          ),
                        )
                        .toList(),
                  ),
                  if (_selectedPayerIds.length > 1) ...[
                    const SizedBox(height: 12),
                    ..._availablePayers.where((member) => _selectedPayerIds.contains(member.id)).map(
                          (member) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextField(
                              controller: _payerAmountControllers.putIfAbsent(member.id, () => TextEditingController()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: 'Pagó ${member.name}', prefixText: r'$ '),
                            ),
                          ),
                        ),
                  ],
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
