import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/local_group_repository.dart';
import '../../../domain/models/currency.dart';
import '../../../domain/models/expense.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/person.dart';
import '../../../domain/models/split_type.dart';
import '../../../logic/expense_validator.dart';
import '../../../shared/group_visuals.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../groups/application/group_operations.dart';
import '../../../data/preferences/self_member_store.dart';
import 'split_expense_screen.dart';

class CreateExpenseScreen extends StatefulWidget {
  const CreateExpenseScreen({
    super.key,
    required this.repository,
    required this.group,
    this.initialExpense,
  });

  final LocalGroupRepository repository;
  final Group group;
  final Expense? initialExpense;

  @override
  State<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends State<CreateExpenseScreen> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final FocusNode _descriptionFocus;
  late final FocusNode _amountFocus;

  late Currency _selectedCurrency;
  double? _exchangeRate;
  late DateTime _expenseDate;
  late Set<String> _selectedPayerIds;
  late Set<String> _selectedParticipantIds;
  late SplitType _splitType;
  final Map<String, TextEditingController> _splitDetailControllers = {};
  final Map<String, TextEditingController> _payerAmountControllers = {};

  bool _isSaving = false;

  List<Person> get _activeMembers =>
      widget.group.members.where((m) => !m.isArchived).toList();

  List<Person> get _availableMembers {
    final list = [..._activeMembers];
    final existing = widget.initialExpense;
    if (existing != null) {
      for (final p in existing.participants) {
        if (!list.any((item) => item.id == p.id)) list.add(p);
      }
      for (final payer in existing.payers) {
        if (!list.any((item) => item.id == payer.person.id)) {
          list.add(payer.person);
        }
      }
    }
    return list;
  }

  double get _amount {
    final text = _amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(text) ?? 0.0;
  }

  bool get _canSave {
    if (_isSaving) return false;
    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) return false;
    if (_amount <= 0) return false;
    if (_selectedPayerIds.isEmpty) return false;
    if (_selectedParticipantIds.isEmpty) return false;

    // Si la moneda es distinta a la de referencia, se requiere tipo de cambio válido
    if (_selectedCurrency != widget.group.referenceCurrency) {
      if (_exchangeRate == null || _exchangeRate! <= 0) return false;
    }

    final validationError = ExpenseValidator.validate(
      description: desc,
      amount: _amount,
      payer: _selectedPayerIds.length == 1
          ? _availableMembers.firstWhere((m) => m.id == _selectedPayerIds.first)
          : null,
      payers: _selectedPayerIds.length > 1
          ? _buildPayersList(_amount)
          : null,
      participants: _availableMembers
          .where((m) => _selectedParticipantIds.contains(m.id))
          .toList(),
      splitType: _splitType,
      splitDetails: _collectSplitDetails(),
      referenceCurrency: widget.group.referenceCurrency,
    );

    return validationError == null;
  }

  @override
  void initState() {
    super.initState();
    final expense = widget.initialExpense;

    _descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );
    _amountController = TextEditingController(
      text: expense == null
          ? ''
          : _formatInitialAmount(expense.originalAmount.decimalValue),
    );

    _descriptionFocus = FocusNode()..addListener(() => setState(() {}));
    _amountFocus = FocusNode()..addListener(() => setState(() {}));

    _selectedCurrency =
        expense?.originalCurrency ?? widget.group.referenceCurrency;
    _expenseDate = expense?.date ?? DateTime.now();

    if (expense != null) {
      _exchangeRate = expense.exchangeRate > 0 ? expense.exchangeRate : null;
    } else {
      _exchangeRate = _selectedCurrency == widget.group.referenceCurrency
          ? 1.0
          : _getLastExchangeRateFor(_selectedCurrency);
    }

    final members = _availableMembers;
    if (expense != null && expense.payers.isNotEmpty) {
      _selectedPayerIds = expense.payers.map((p) => p.person.id).toSet();
      // Con varios pagadores se conserva el aporte de cada uno al editar.
      // Con un solo pagador se deja vacío para que siga al importe total.
      if (expense.payers.length > 1) {
        for (final payer in expense.payers) {
          _payerAmountControllers[payer.person.id] = TextEditingController(
            text: _payerAmountInSelectedCurrency(payer, expense)
                .toStringAsFixed(2),
          );
        }
      }
    } else {
      final selfId = SelfMemberStore.activeSelfMemberId(widget.group);
      final defaultPayerId = selfId != null && members.any((m) => m.id == selfId)
          ? selfId
          : (members.isNotEmpty ? members.first.id : null);
      _selectedPayerIds =
          defaultPayerId != null ? {defaultPayerId} : <String>{};
    }

    if (expense != null && expense.participants.isNotEmpty) {
      _selectedParticipantIds =
          expense.participants.map((p) => p.id).toSet();
    } else {
      _selectedParticipantIds = members.map((m) => m.id).toSet();
    }

    _splitType = expense?.splitType ?? SplitType.equally;

    if (expense?.splitDetails != null) {
      for (final entry in expense!.splitDetails!.entries) {
        _splitDetailControllers[entry.key] = TextEditingController(
          text: entry.value.toString(),
        );
      }
    }
  }

  String _formatInitialAmount(double value) {
    if (value == value.roundToDouble()) {
      return CurrencyFormatter.formatWithDots(value.toInt().toString());
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  /// Expresa el aporte de un pagador en la moneda original del gasto, que es la
  /// que usa el formulario. Los datos guardados pueden estar en la moneda de
  /// referencia del gasto, así que se convierte con la tasa registrada.
  double _payerAmountInSelectedCurrency(ExpensePayer payer, Expense expense) {
    final amount = payer.amount;
    if (amount.currency == _selectedCurrency) return amount.decimalValue;

    final rate = expense.exchangeRate;
    if (rate <= 0) return amount.decimalValue;

    if (amount.currency == expense.referenceCurrency) {
      return amount.decimalValue / rate;
    }
    if (amount.currency == expense.originalCurrency) {
      return amount.decimalValue * rate;
    }
    return amount.decimalValue;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5);
    final lastDate = DateTime(now.year + 1, 12, 31);
    final initialDate = _expenseDate.isBefore(firstDate)
        ? firstDate
        : (_expenseDate.isAfter(lastDate) ? lastDate : _expenseDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Elegí la fecha del gasto',
    );

    if (picked != null && mounted) {
      setState(() => _expenseDate = picked);
    }
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _descriptionFocus.dispose();
    _amountFocus.dispose();
    for (final controller in _splitDetailControllers.values) {
      controller.dispose();
    }
    for (final controller in _payerAmountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, double>? _collectSplitDetails() {
    if (_splitType == SplitType.equally) return null;
    final map = <String, double>{};
    for (final id in _selectedParticipantIds) {
      final controller = _splitDetailControllers[id];
      final val = double.tryParse(controller?.text.trim() ?? '') ?? 0.0;
      map[id] = val;
    }
    return map;
  }

  List<ExpensePayer> _buildPayersList(double totalAmount) {
    final selectedMembers = _availableMembers
        .where((m) => _selectedPayerIds.contains(m.id))
        .toList();
    if (selectedMembers.isEmpty) return const [];

    final hasCustomPayerAmounts = _payerAmountControllers.values.any(
      (c) => (double.tryParse(c.text.trim()) ?? 0) > 0,
    );

    if (hasCustomPayerAmounts) {
      return selectedMembers.map((person) {
        final amountText = _payerAmountControllers[person.id]?.text.trim() ?? '';
        final amountVal = double.tryParse(amountText) ?? 0.0;
        return ExpensePayer(
          person: person,
          amount: Money.fromDecimal(amountVal, _selectedCurrency),
        );
      }).toList();
    }

    final totalCents =
        Money.fromDecimal(totalAmount, _selectedCurrency).cents;
    final count = selectedMembers.length;
    final baseCents = totalCents ~/ count;
    final remainder = totalCents % count;

    final result = <ExpensePayer>[];
    for (var i = 0; i < count; i++) {
      final cents = baseCents + (i < remainder ? 1 : 0);
      result.add(
        ExpensePayer(
          person: selectedMembers[i],
          amount: Money(cents: cents, currency: _selectedCurrency),
        ),
      );
    }
    return result;
  }

  void _onAmountChanged(String value) {
    final clean = value.replaceAll('.', '').replaceAll(' ', '');
    if (clean.isEmpty) {
      setState(() {});
      return;
    }

    if (RegExp(r'^\d+$').hasMatch(clean)) {
      final formatted = CurrencyFormatter.formatWithDots(clean);
      if (formatted != value) {
        _amountController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
    setState(() {});
  }

  void _togglePayer(Person person) {
    setState(() {
      if (_selectedPayerIds.contains(person.id)) {
        if (_selectedPayerIds.length > 1) {
          _selectedPayerIds.remove(person.id);
        }
      } else {
        _selectedPayerIds.add(person.id);
      }
    });
  }

  void _toggleParticipant(Person person) {
    setState(() {
      if (_selectedParticipantIds.contains(person.id)) {
        if (_selectedParticipantIds.length > 1) {
          _selectedParticipantIds.remove(person.id);
        }
      } else {
        _selectedParticipantIds.add(person.id);
      }
    });
  }

  String _formatAmountDecimal(double val) {
    final integerPart = val.truncate();
    final decimalPart = ((val - integerPart).abs() * 100).round();
    final intFormatted = CurrencyFormatter.formatWithDots(integerPart.toString());
    final decFormatted = decimalPart.toString().padLeft(2, '0');
    return '$intFormatted,$decFormatted';
  }

  String _formatRate(double rate) {
    if (rate % 1 == 0) {
      return CurrencyFormatter.formatWithDots(rate.toInt().toString());
    }
    return rate.toStringAsFixed(2).replaceAll('.', ',');
  }

  double? _getLastExchangeRateFor(Currency currency) {
    if (currency == widget.group.referenceCurrency) return 1.0;

    final matching = widget.group.expenses
        .where((e) => e.originalCurrency == currency && e.exchangeRate > 0)
        .toList();

    if (matching.isEmpty) return null;

    matching.sort((a, b) => b.date.compareTo(a.date));
    return matching.first.exchangeRate;
  }

  void _showCurrencyPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCurrencies = Currency.supported.where((curr) {
              final q = searchQuery.toLowerCase().trim();
              if (q.isEmpty) return true;
              return curr.name.toLowerCase().contains(q) ||
                  curr.code.toLowerCase().contains(q) ||
                  curr.symbol.toLowerCase().contains(q);
            }).toList();

            return Material(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Title
                      const Text(
                        'Elegí la moneda',
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF11232D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'El gasto conserva esta moneda y se convierte a pesos.',
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF586974),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF586974),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                key: const Key('currency-search-field'),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Buscar moneda',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Figtree',
                                    color: Color(0xFF94A3B8),
                                    fontSize: 15,
                                  ),
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 12),
                                ),
                                onChanged: (val) {
                                  setModalState(() => searchQuery = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Currency list
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredCurrencies.length,
                          separatorBuilder: (context, index) =>
                              const Divider(color: Color(0xFFF1F5F7), height: 1),
                          itemBuilder: (context, i) {
                            final curr = filteredCurrencies[i];
                            final isSelected =
                                curr.code == _selectedCurrency.code;
                            final isReference = curr.code ==
                                widget.group.referenceCurrency.code;

                            return InkWell(
                              key: Key('currency-option-${curr.code}'),
                              onTap: () {
                                setState(() {
                                  _selectedCurrency = curr;
                                  if (curr == widget.group.referenceCurrency) {
                                    _exchangeRate = 1.0;
                                  } else {
                                    _exchangeRate = _getLastExchangeRateFor(curr);
                                  }
                                });
                                Navigator.of(context).pop();
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFE2F4F2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    // Symbol circle badge
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFFE2F4F2),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        curr.symbol,
                                        style: const TextStyle(
                                          fontFamily: 'Figtree',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0D7E88),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            curr.name,
                                            style: const TextStyle(
                                              fontFamily: 'Figtree',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF11232D),
                                            ),
                                          ),
                                          Text(
                                            curr.code,
                                            style: const TextStyle(
                                              fontFamily: 'Figtree',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF586974),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isReference)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE2F4F2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Moneda del grupo',
                                          style: TextStyle(
                                            fontFamily: 'Figtree',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0D7E88),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showExchangeRateDialog() {
    final refCurrency = widget.group.referenceCurrency;
    final lastRate = _getLastExchangeRateFor(_selectedCurrency);
    final initialRate = _exchangeRate ?? lastRate;
    final initialRateText = initialRate != null && initialRate > 0
        ? (initialRate % 1 == 0
            ? initialRate.toInt().toString()
            : initialRate.toString().replaceAll('.', ','))
        : '';
    final controller = TextEditingController(text: initialRateText);
    double currentRate = initialRate ?? 0.0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final convertedPreview = _amount * currentRate;

            return Material(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    12,
                    24,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Title
                      const Text(
                        'Tipo de cambio',
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF11232D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Indicá cuántos pesos (${refCurrency.code}) valía 1 ${_selectedCurrency.name.toLowerCase()} (${_selectedCurrency.code}) cuando pagaste.',
                        style: const TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF586974),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Input row: "1 R$ = " + Input container
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '1 ${_selectedCurrency.symbol} =',
                            style: const TextStyle(
                              fontFamily: 'Figtree',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF11232D),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF0D7E88),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pesos (${refCurrency.code})',
                                    style: const TextStyle(
                                      fontFamily: 'Figtree',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0D7E88),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${refCurrency.symbol} ',
                                        style: const TextStyle(
                                          fontFamily: 'Figtree',
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF11232D),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          key: const Key(
                                              'exchange-rate-input-field'),
                                          controller: controller,
                                          autofocus: true,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          style: const TextStyle(
                                            fontFamily: 'Figtree',
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF11232D),
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            hintText: '0',
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    vertical: 2),
                                          ),
                                          onChanged: (val) {
                                            final clean = val
                                                .replaceAll('.', '')
                                                .replaceAll(',', '.');
                                            final parsed =
                                                double.tryParse(clean) ?? 0.0;
                                            setModalState(() {
                                              currentRate = parsed;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (lastRate != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFBBF7D0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                size: 14,
                                color: Color(0xFF15803D),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Última cotización en este grupo: ${refCurrency.symbol} ${_formatRate(lastRate)}',
                                style: const TextStyle(
                                  fontFamily: 'Figtree',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Preview card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F4F2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'El gasto queda así',
                              style: TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF586974),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedCurrency.symbol} ${_formatAmountDecimal(_amount)} ≈ ${refCurrency.symbol} ${_formatAmountDecimal(convertedPreview)}',
                              style: const TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF11232D),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Se aplica solo a este gasto. Los demás conservan su propio tipo de cambio.',
                              style: TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF586974),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Guardar tipo de cambio button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          key: const Key('save-exchange-rate-button'),
                          onPressed: currentRate > 0
                              ? () {
                                  setState(() {
                                    _exchangeRate = currentRate;
                                  });
                                  Navigator.of(context).pop();
                                }
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0D7E88),
                            disabledBackgroundColor: const Color(0xFFD5DEE2),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Guardar tipo de cambio',
                            style: TextStyle(
                              fontFamily: 'Figtree',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Cancelar button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: TextButton(
                          key: const Key('cancel-exchange-rate-button'),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontFamily: 'Figtree',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF11232D),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExchangeRateRow() {
    if (_exchangeRate == null || _exchangeRate! <= 0) {
      return Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFC2410C),
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Falta el tipo de cambio',
            style: TextStyle(
              fontFamily: 'Figtree',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC2410C),
            ),
          ),
          const Spacer(),
          GestureDetector(
            key: const Key('enter-exchange-rate-button'),
            onTap: _showExchangeRateDialog,
            child: const Text(
              'Ingresar',
              style: TextStyle(
                fontFamily: 'Figtree',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D7E88),
              ),
            ),
          ),
        ],
      );
    }

    final convertedAmount = _amount * _exchangeRate!;
    final refCurrency = widget.group.referenceCurrency;

    return InkWell(
      key: const Key('exchange-rate-banner'),
      onTap: _showExchangeRateDialog,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '≈ ${refCurrency.symbol} ${CurrencyFormatter.formatWithDots(convertedAmount.round().toString())}',
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D7E88),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      ' en pesos (${refCurrency.code})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF586974),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '1 ${_selectedCurrency.symbol} = ${refCurrency.symbol} ${_formatRate(_exchangeRate!)}',
                  style: const TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D7E88),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF0D7E88),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSplitExpenseScreen() async {
    final effectiveAmount = _amount;
    final initialPayers = <String, double>{};
    for (final id in _selectedPayerIds) {
      final text = _payerAmountControllers[id]?.text.trim() ?? '';
      final val = double.tryParse(text) ?? 0.0;
      initialPayers[id] = val > 0
          ? val
          : (effectiveAmount > 0
              ? (effectiveAmount / _selectedPayerIds.length)
              : 0.0);
    }

    final initialSplitDetails = _collectSplitDetails();

    final result = await Navigator.of(context).push<SplitExpenseResult>(
      MaterialPageRoute(
        builder: (_) => SplitExpenseScreen(
          description: _descriptionController.text.trim(),
          totalAmount: effectiveAmount > 0 ? effectiveAmount : 0.0,
          currency: _selectedCurrency,
          members: _availableMembers,
          initialPayers: initialPayers,
          initialSplitType: _splitType,
          initialSplitDetails: initialSplitDetails,
          initialParticipantIds: _selectedParticipantIds,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _splitType = result.splitType;
        _selectedParticipantIds = result.participantIds;

        _selectedPayerIds = result.payerAmounts.entries
            .where((e) => e.value > 0)
            .map((e) => e.key)
            .toSet();

        for (final entry in result.payerAmounts.entries) {
          final c = _payerAmountControllers.putIfAbsent(
            entry.key,
            () => TextEditingController(),
          );
          c.text = entry.value > 0 ? entry.value.toStringAsFixed(2) : '';
        }

        for (final entry in result.splitDetails.entries) {
          final c = _splitDetailControllers.putIfAbsent(
            entry.key,
            () => TextEditingController(),
          );
          c.text = entry.value % 1 == 0
              ? entry.value.toInt().toString()
              : entry.value.toStringAsFixed(2);
        }
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);

    try {
      final desc = _descriptionController.text.trim();
      final totalAmount = _amount;
      final selectedParticipants = _availableMembers
          .where((m) => _selectedParticipantIds.contains(m.id))
          .toList();

      final payersList = _buildPayersList(totalAmount);
      final singlePayer =
          payersList.length == 1 ? payersList.single.person : null;

      final refCurrency = widget.group.referenceCurrency;
      final effectiveRate = (_selectedCurrency == refCurrency)
          ? 1.0
          : (_exchangeRate ?? 1.0);
      final converted = totalAmount * effectiveRate;

      final expense = Expense(
        id: widget.initialExpense?.id,
        description: desc,
        amount: converted,
        date: _expenseDate,
        payer: singlePayer,
        payers: payersList,
        participants: selectedParticipants,
        groupId: widget.group.id,
        splitType: _splitType,
        splitDetails: _collectSplitDetails(),
        originalCurrency: _selectedCurrency,
        referenceCurrency: refCurrency,
        originalAmount: Money.fromDecimal(totalAmount, _selectedCurrency),
        convertedAmount: Money.fromDecimal(converted, refCurrency),
        exchangeRate: effectiveRate,
      );

      await GroupOperations(widget.repository).saveExpense(
        widget.group,
        expense,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar el gasto. Revisá los datos.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final members = _availableMembers;

    final groupColor = groupColorFromHex(widget.group.colorHex);
    final groupIcon = groupIconFromName(widget.group.iconName);

    final isDescActive =
        _descriptionFocus.hasFocus || _descriptionController.text.isNotEmpty;
    final isAmountActive =
        _amountFocus.hasFocus || _amountController.text.isNotEmpty;

    final formattedSplitSubtitle = switch (_splitType) {
      SplitType.equally => 'Por ahora, dividilo en partes iguales',
      SplitType.byAmount => 'Dividilo por montos exactos',
      SplitType.byPercentage => 'Dividilo por porcentajes',
      SplitType.byShares => 'Dividilo por partes proporcionales',
    };

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Volver',
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: groupColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          groupIcon,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.group.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Subtitle
                        Text(
                          'Cargá un gasto',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Anotá lo que pagaron para que las cuentas estén siempre claras.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Card 1: ¿Qué pagaron?
                        _DescriptionInputCard(
                          controller: _descriptionController,
                          focusNode: _descriptionFocus,
                          isActive: isDescActive,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),

                        // Card 2: Importe & Currency Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _AmountInputCard(
                                controller: _amountController,
                                focusNode: _amountFocus,
                                isActive: isAmountActive,
                                currencySymbol: _selectedCurrency.symbol,
                                onChanged: _onAmountChanged,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _CurrencyPickerButton(
                              currencyCode: _selectedCurrency.code,
                              onTap: _showCurrencyPicker,
                            ),
                          ],
                        ),
                        if (_selectedCurrency != widget.group.referenceCurrency) ...[
                          const SizedBox(height: 12),
                          _buildExchangeRateRow(),
                        ],
                        const SizedBox(height: 12),
                        _ExpenseDateCard(
                          dateLabel: _formatDateLabel(_expenseDate),
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 22),

                        // Section 1: ¿Quién pagó?
                        Text(
                          '¿Quién pagó?',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Elegí una o más personas',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < members.length; i++)
                              _PersonChip(
                                key: Key('payer-${members[i].id}'),
                                name: members[i].name,
                                avatarLetter: members[i].name.isNotEmpty
                                    ? members[i].name[0].toUpperCase()
                                    : '?',
                                avatarColor: AppPalette.memberColor(i),
                                isSelected:
                                    _selectedPayerIds.contains(members[i].id),
                                onTap: () => _togglePayer(members[i]),
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // Section 2: ¿Entre quiénes se divide?
                        Text(
                          '¿Entre quiénes se divide?',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedSplitSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < members.length; i++)
                              _PersonChip(
                                key: Key('participant-${members[i].id}'),
                                name: members[i].name,
                                avatarLetter: members[i].name.isNotEmpty
                                    ? members[i].name[0].toUpperCase()
                                    : '?',
                                avatarColor: AppPalette.memberColor(i),
                                isSelected: _selectedParticipantIds
                                    .contains(members[i].id),
                                onTap: () => _toggleParticipant(members[i]),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Link: Cambiar forma de dividir
                        InkWell(
                          key: const Key('change-split-type-button'),
                          onTap: _openSplitExpenseScreen,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Cambiar forma de dividir',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        // Custom split breakdown inputs if not equally
                        if (_splitType != SplitType.equally) ...[
                          const SizedBox(height: 16),
                          _CustomSplitInputsCard(
                            splitType: _splitType,
                            currencySymbol: _selectedCurrency.symbol,
                            totalAmount: _amount,
                            participants: members
                                .where(
                                  (m) =>
                                      _selectedParticipantIds.contains(m.id),
                                )
                                .toList(),
                            controllers: _splitDetailControllers,
                            onChanged: () => setState(() {}),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Live summary card
                        _LiveSummaryCard(
                          amount: _amount,
                          currencySymbol: _selectedCurrency.symbol,
                          splitType: _splitType,
                          payersCount: _selectedPayerIds.length,
                          participantsCount: _selectedParticipantIds.length,
                          payerName: _selectedPayerIds.length == 1
                              ? members
                                  .firstWhere(
                                    (m) => m.id == _selectedPayerIds.first,
                                    orElse: () => members.first,
                                  )
                                  .name
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),

                // Fixed Action Bar at Bottom
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          key: const Key('save-expense-button'),
                          onPressed: _canSave ? _saveExpense : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFFCFD8DC),
                            disabledForegroundColor:
                                const Color(0xFF586974),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Figtree',
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Guardar gasto'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Podés editarlo después.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Subwidgets reproducing the visual specification
// ---------------------------------------------------------

class _DescriptionInputCard extends StatelessWidget {
  const _DescriptionInputCard({
    required this.controller,
    required this.focusNode,
    required this.isActive,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isFocused = focusNode.hasFocus;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isFocused
            ? Border.all(color: colors.primary, width: 1.5)
            : Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.35),
                width: 1.0,
              ),
        boxShadow: isFocused
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Qué pagaron?',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isFocused ? colors.primary : colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextField(
            key: const Key('expense-description-field'),
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: 'Ej. Cena en la playa',
              hintStyle: theme.textTheme.titleLarge?.copyWith(
                color: colors.onSurfaceVariant.withValues(alpha: 0.65),
                fontWeight: FontWeight.w700,
              ),
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 6, bottom: 4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseDateCard extends StatelessWidget {
  const _ExpenseDateCard({required this.dateLabel, required this.onTap});

  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      key: const Key('expense-date-button'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.35),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_outlined,
              size: 18,
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountInputCard extends StatelessWidget {
  const _AmountInputCard({
    required this.controller,
    required this.focusNode,
    required this.isActive,
    required this.currencySymbol,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;
  final String currencySymbol;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isFocused = focusNode.hasFocus;
    final hasText = controller.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isFocused
            ? Border.all(color: colors.primary, width: 1.5)
            : Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.35),
                width: 1.0,
              ),
        boxShadow: isFocused
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Importe',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isFocused ? colors.primary : colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            children: [
              Text(
                '$currencySymbol ',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: hasText
                      ? colors.onSurface
                      : colors.onSurfaceVariant.withValues(alpha: 0.65),
                ),
              ),
              Expanded(
                child: TextField(
                  key: const Key('expense-amount-field'),
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[\d.,]'),
                    ),
                  ],
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                  decoration: InputDecoration(
                    hintText: '0,00',
                    hintStyle: theme.textTheme.titleLarge?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 6, bottom: 4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrencyPickerButton extends StatelessWidget {
  const _CurrencyPickerButton({
    required this.currencyCode,
    required this.onTap,
  });

  final String currencyCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      label: 'Moneda $currencyCode',
      button: true,
      child: InkWell(
        key: const Key('currency-picker-button'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currencyCode,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 24,
                color: colors.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({
    super.key,
    required this.name,
    required this.avatarLetter,
    required this.avatarColor,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final String avatarLetter;
  final Color avatarColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: '$name, ${isSelected ? "seleccionado" : "no seleccionado"}',
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          height: 46,
          padding: EdgeInsets.fromLTRB(6, 4, isSelected ? 12 : 16, 4),
          decoration: BoxDecoration(
            color: isSelected ? colors.secondaryContainer : colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outlineVariant.withValues(alpha: 0.6),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  avatarLetter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: colors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomSplitInputsCard extends StatelessWidget {
  const _CustomSplitInputsCard({
    required this.splitType,
    required this.currencySymbol,
    required this.totalAmount,
    required this.participants,
    required this.controllers,
    required this.onChanged,
  });

  final SplitType splitType;
  final String currencySymbol;
  final double totalAmount;
  final List<Person> participants;
  final Map<String, TextEditingController> controllers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final suffixOrPrefix = switch (splitType) {
      SplitType.byAmount => currencySymbol,
      SplitType.byPercentage => '%',
      SplitType.byShares => 'partes',
      SplitType.equally => '',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valores por participante',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final person in participants) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    person.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: controllers.putIfAbsent(
                      person.id,
                      () => TextEditingController(),
                    ),
                    onChanged: (_) => onChanged(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: splitType != SplitType.byAmount
                          ? ' $suffixOrPrefix'
                          : null,
                      prefixText: splitType == SplitType.byAmount
                          ? '$suffixOrPrefix '
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _LiveSummaryCard extends StatelessWidget {
  const _LiveSummaryCard({
    required this.amount,
    required this.currencySymbol,
    required this.splitType,
    required this.payersCount,
    required this.participantsCount,
    this.payerName,
  });

  final double amount;
  final String currencySymbol;
  final SplitType splitType;
  final int payersCount;
  final int participantsCount;
  final String? payerName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (amount <= 0 || participantsCount == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.secondaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'Ingresá un importe para ver el cálculo de división.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final perPerson = amount / participantsCount;
    final formattedPerPerson = CurrencyFormatter.formatAmount(perPerson);
    final formattedTotal = CurrencyFormatter.formatAmount(amount);

    String summaryText;
    if (splitType == SplitType.equally) {
      if (payersCount == 1 && payerName != null) {
        summaryText =
            '$payerName pagó $currencySymbol $formattedTotal. '
            'Se divide en $participantsCount ${participantsCount == 1 ? "parte" : "partes"} de $currencySymbol $formattedPerPerson c/u.';
      } else {
        summaryText =
            'Total: $currencySymbol $formattedTotal entre $payersCount ${payersCount == 1 ? "pagador" : "pagadores"}. '
            'Cada uno de los $participantsCount participantes asume $currencySymbol $formattedPerPerson.';
      }
    } else {
      summaryText =
          'Gasto total de $currencySymbol $formattedTotal repartido entre $participantsCount personas según la modalidad elegida.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: colors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              summaryText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
