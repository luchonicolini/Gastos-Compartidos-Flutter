import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/local_group_repository.dart';
import '../../../domain/models/expense.dart';
import '../../../domain/models/group.dart';
import '../../groups/application/group_operations.dart';
import '../../groups/presentation/group_detail_screen.dart';
import 'create_expense_screen.dart';

/// Pantalla completa de Todos los gastos del grupo.
/// Delega directamente a [GroupDetailScreen] con la pestaña 0 seleccionada.
class AllExpensesScreen extends StatelessWidget {
  const AllExpensesScreen({
    super.key,
    required this.group,
    required this.repository,
  });

  final Group group;
  final LocalGroupRepository repository;

  @override
  Widget build(BuildContext context) {
    return GroupDetailScreen(
      group: group,
      repository: repository,
      initialTab: 0,
    );
  }
}

/// Vista de "Todos los gastos" del grupo (Pestaña 0).
/// Implementada con máxima fidelidad visual respecto a las 4 imágenes de referencia.
class GroupExpensesView extends StatefulWidget {
  const GroupExpensesView({
    super.key,
    required this.group,
    required this.repository,
    required this.onGroupChanged,
    required this.onAddExpense,
    this.onNavigateToBalances,
  });

  final Group group;
  final LocalGroupRepository repository;
  final ValueChanged<Group> onGroupChanged;
  final VoidCallback onAddExpense;
  final VoidCallback? onNavigateToBalances;

  @override
  State<GroupExpensesView> createState() => _GroupExpensesViewState();
}

class _GroupExpensesViewState extends State<GroupExpensesView> {
  late final GroupOperations _operations = GroupOperations(widget.repository);
  String? _selectedExpenseId;

  double get _totalExpensesAmount =>
      widget.group.expenses.fold<double>(0.0, (sum, item) => sum + item.amount);

  List<Expense> get _sortedExpenses {
    final list = [...widget.group.expenses];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Map<String, List<Expense>> get _groupedExpenses {
    final groups = <String, List<Expense>>{};
    for (final expense in _sortedExpenses) {
      final header = _formatDateHeader(expense.date);
      groups.putIfAbsent(header, () => []).add(expense);
    }
    return groups;
  }

  Future<void> _openEditExpense(Expense expense) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateExpenseScreen(
          repository: widget.repository,
          group: widget.group,
          initialExpense: expense,
        ),
      ),
    );
    if (result == true && mounted) {
      final updated = await widget.repository.getById(widget.group.id);
      if (updated != null) {
        widget.onGroupChanged(updated);
      }
    }
  }

  Future<void> _confirmDeleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE53935),
                  size: 38,
                ),
                const SizedBox(height: 16),
                const Text(
                  '¿Eliminar este gasto?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: Color(0xFF11232D),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Los balances del grupo se recalcularán.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF586974),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        key: const Key('cancel-delete-expense-button'),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D7E88),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        key: const Key('confirm-delete-expense-button'),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Eliminar',
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final updated = await _operations.deleteExpense(widget.group, expense.id);
      widget.onGroupChanged(updated);
    }
  }

  Future<void> _showExpenseMenu(
    BuildContext cardContext,
    Expense expense,
  ) async {
    setState(() => _selectedExpenseId = expense.id);

    final renderBox = cardContext.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (renderBox == null || overlay == null) {
      if (mounted) setState(() => _selectedExpenseId = null);
      return;
    }

    final cardRect = Rect.fromPoints(
      renderBox.localToGlobal(Offset.zero, ancestor: overlay),
      renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero),
          ancestor: overlay),
    );

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        cardRect.right - 190,
        cardRect.bottom + 4,
        cardRect.right,
        overlay.size.height - cardRect.bottom,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          height: 48,
          child: Row(
            children: const [
              Icon(Icons.edit_outlined, size: 20, color: Color(0xFF11232D)),
              SizedBox(width: 12),
              Text(
                'Editar',
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF11232D),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          height: 48,
          child: Row(
            children: const [
              Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Color(0xFFE53935),
              ),
              SizedBox(width: 12),
              Text(
                'Eliminar',
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFFE53935),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (mounted) {
      setState(() => _selectedExpenseId = null);
    }

    if (selected == 'edit') {
      _openEditExpense(expense);
    } else if (selected == 'delete') {
      _confirmDeleteExpense(expense);
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expenseDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(expenseDay).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    const months = [
      'ene.',
      'feb.',
      'mar.',
      'abr.',
      'may.',
      'jun.',
      'jul.',
      'ago.',
      'sep.',
      'oct.',
      'nov.',
      'dic.'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatAmount(double value) {
    final isNegative = value < 0;
    final absVal = value.abs();
    final whole = absVal.truncate().toString();
    final buffer = StringBuffer();
    final len = whole.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buffer.write('.');
      buffer.write(whole[i]);
    }
    final formattedWhole = buffer.toString();
    if (absVal == absVal.truncateToDouble()) {
      return '${isNegative ? '-' : ''}$formattedWhole';
    }
    final decimal =
        (absVal - absVal.truncate()).toStringAsFixed(2).substring(2);
    return '${isNegative ? '-' : ''}$formattedWhole,$decimal';
  }

  @override
  Widget build(BuildContext context) {
    final hasExpenses = widget.group.expenses.isNotEmpty;

    return hasExpenses
        ? _buildExpensesList(context)
        : _buildEmptyState(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y subtítulo
          const Text(
            'Todos los gastos',
            style: TextStyle(
              fontFamily: 'Figtree',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: Color(0xFF11232D),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Revisá y editá los gastos de este grupo.',
            style: TextStyle(
              fontFamily: 'Figtree',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF586974),
            ),
          ),
          const SizedBox(height: 20),

          // Tarjeta menta grande de estado vacío (Imagen 2)
          Container(
            width: double.infinity,
            height: 440,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF1EF),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Círculo blanco con icono de factura/recibo en teal
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: Color(0xFF0D7E88),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Título de estado vacío
                    const Text(
                      'Todavía no cargaste\ngastos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: Color(0xFF11232D),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtítulo
                    const Text(
                      'Anotá el primero para empezar a\nordenar las cuentas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF586974),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(BuildContext context) {
    final currencySymbol = widget.group.referenceCurrency.symbol;
    final totalSpentText =
        '$currencySymbol${_formatAmount(_totalExpensesAmount)}';
    final expensesCount = widget.group.expenses.length;
    final countText =
        '$expensesCount ${expensesCount == 1 ? "gasto" : "gastos"}';

    final grouped = _groupedExpenses;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y subtítulo
          const Text(
            'Todos los gastos',
            style: TextStyle(
              fontFamily: 'Figtree',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: Color(0xFF11232D),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Revisá y editá los gastos de este grupo.',
            style: TextStyle(
              fontFamily: 'Figtree',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF586974),
            ),
          ),
          const SizedBox(height: 20),

          // Hero Card "Total gastado" (Imágenes 1, 3, 4)
          Material(
            color: const Color(0xFFDDF1EF),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: widget.onNavigateToBalances,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total gastado',
                            style: TextStyle(
                              fontFamily: 'Figtree',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF586974),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            totalSpentText,
                            style: const TextStyle(
                              fontFamily: 'Figtree',
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.0,
                              color: Color(0xFF11232D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      countText,
                      style: const TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF11232D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Grupos de gastos por fecha (Hoy, Ayer, 12 ene. 2026...)
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF586974),
                ),
              ),
            ),
            for (final expense in entry.value) ...[
              Builder(
                builder: (cardContext) {
                  final isSelected = _selectedExpenseId == expense.id;
                  final payerName = expense.payer?.name ??
                      (expense.payers.isNotEmpty
                          ? expense.payers.first.person.name
                          : 'Alguien');

                  final payerIndex = widget.group.members
                      .indexWhere((m) => m.name == payerName);
                  final avatarColor = AppPalette.memberColor(
                      payerIndex >= 0 ? payerIndex : 0);

                  final participantsCount = expense.participants.length;
                  final participantsSubtitle =
                      'Pagó $payerName · Entre $participantsCount ${participantsCount == 1 ? "persona" : "personas"}';

                  final isMultiCurrency = expense.originalCurrency !=
                      widget.group.referenceCurrency;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Slidable(
                        key: ValueKey('slidable-${expense.id}'),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: 0.48,
                          children: [
                            SlidableAction(
                              key: Key('slidable-edit-${expense.id}'),
                              onPressed: (_) => _openEditExpense(expense),
                              backgroundColor: const Color(0xFF0D7E88),
                              foregroundColor: Colors.white,
                              icon: Icons.edit_outlined,
                              label: 'Editar',
                            ),
                            SlidableAction(
                              key: Key('slidable-delete-${expense.id}'),
                              onPressed: (_) => _confirmDeleteExpense(expense),
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              icon: Icons.delete_outline_rounded,
                              label: 'Eliminar',
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0D7E88)
                                  : Colors.transparent,
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            key: Key('expense-card-${expense.id}'),
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => _showExpenseMenu(cardContext, expense),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            // Avatar del pagador con su inicial
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: avatarColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                payerName.isNotEmpty
                                    ? payerName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontFamily: 'Figtree',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Descripción y subtítulo de participantes
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense.description,
                                    style: const TextStyle(
                                      fontFamily: 'Figtree',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                      color: Color(0xFF11232D),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    participantsSubtitle,
                                    style: const TextStyle(
                                      fontFamily: 'Figtree',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF586974),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Monto en moneda de referencia (y moneda original si aplica)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$currencySymbol${_formatAmount(expense.amount)}',
                                  style: const TextStyle(
                                    fontFamily: 'Figtree',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: Color(0xFF11232D),
                                  ),
                                ),
                                if (isMultiCurrency) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${expense.originalCurrency.symbol} ${_formatAmount(expense.originalAmount.decimalValue)} · ${expense.originalCurrency.code}',
                                    style: const TextStyle(
                                      fontFamily: 'Figtree',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF586974),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}
