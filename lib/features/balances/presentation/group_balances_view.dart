import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/local_group_repository.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/member_balance.dart';
import '../../../domain/models/person.dart';
import '../../../domain/models/settlement_payment.dart';
import '../../../logic/balance_calculator.dart';
import '../../../logic/settlement_calculator.dart';
import '../../groups/application/group_operations.dart';

/// Vista de "Cuentas" del grupo.
/// Implementada con máxima fidelidad visual respecto a las pantallas de referencia.
class GroupBalancesView extends StatefulWidget {
  const GroupBalancesView({
    super.key,
    required this.group,
    required this.repository,
    required this.onGroupChanged,
    required this.onNavigateToExpenses,
  });

  final Group group;
  final LocalGroupRepository repository;
  final ValueChanged<Group> onGroupChanged;
  final VoidCallback onNavigateToExpenses;

  @override
  State<GroupBalancesView> createState() => _GroupBalancesViewState();
}

class _GroupBalancesViewState extends State<GroupBalancesView> {
  late final GroupOperations _operations = GroupOperations(widget.repository);

  List<MemberBalance> get _memberBalances =>
      BalanceCalculator.calculateMemberBalances(widget.group);

  List<FormattedSettlement> get _suggestedSettlements =>
      SettlementCalculator.suggestFormattedSettlements(
        _memberBalances,
        referenceCurrency: widget.group.referenceCurrency,
      );

  double get _totalExpensesAmount => widget.group.expenses
      .fold<double>(0.0, (sum, item) => sum + item.amount);

  List<Person> get _activeMembers =>
      widget.group.members.where((m) => !m.isArchived).toList();

  Timer? _toastTimer;
  bool _showPaymentRegisteredToast = false;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showToast() {
    _toastTimer?.cancel();
    setState(() {
      _showPaymentRegisteredToast = true;
    });
    _toastTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showPaymentRegisteredToast = false;
        });
      }
    });
  }

  Future<void> _openConfirmPaymentModal(FormattedSettlement settlement) async {
    final result = await showModalBottomSheet<_ConfirmPaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConfirmPaymentBottomSheet(
        settlement: settlement,
        allMembers: widget.group.members,
        currencySymbol: widget.group.referenceCurrency.symbol,
        formatAmount: _formatAmount,
      ),
    );

    if (result != null && mounted) {
      final updated = await _operations.confirmSettlement(
        widget.group,
        settlement,
        date: result.date,
      );
      widget.onGroupChanged(updated);
      _showToast();
    }
  }

  Future<void> _deleteSettlement(SettlementPayment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar pago'),
        content: Text(
          '¿Querés anular el pago de ${payment.payerName} a ${payment.payeeName} por \$${_formatAmount(payment.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final updated =
          await _operations.deleteSettlement(widget.group, payment.id);
      widget.onGroupChanged(updated);
    }
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      final whole = value.toInt().toString();
      final buffer = StringBuffer();
      final len = whole.length;
      for (var i = 0; i < len; i++) {
        if (i > 0 && (len - i) % 3 == 0) buffer.write('.');
        buffer.write(whole[i]);
      }
      return buffer.toString();
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final hasExpenses = widget.group.expenses.isNotEmpty;
    final balances = _memberBalances;
    final suggested = _suggestedSettlements;
    final currencySymbol = widget.group.referenceCurrency.symbol;
    final totalSpentText =
        '$currencySymbol${_formatAmount(_totalExpensesAmount)}';
    final expensesCount = widget.group.expenses.length;
    final activeMembersCount = _activeMembers.length;
    final expensesSubtitle =
        '$expensesCount ${expensesCount == 1 ? "gasto" : "gastos"} · $activeMembersCount ${activeMembersCount == 1 ? "persona" : "personas"}';

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Título principal
          const Text(
            'Así van las cuentas',
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

          // Subtítulo
          const Text(
            'Cuando termine el viaje, te vamos a mostrar\nla forma más simple de saldar.',
            style: TextStyle(
              fontFamily: 'Figtree',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.35,
              color: Color(0xFF586974),
            ),
          ),
          const SizedBox(height: 20),

          // Estado sin gastos (Imagen 1)
          if (!hasExpenses)
            _EmptyBalancesCard(
              onNavigateToExpenses: widget.onNavigateToExpenses,
            )
          else ...[
            // Card Hero: Total gastado (Imágenes 2 y 3)
            _TotalSpentHeroCard(
              totalSpentText: totalSpentText,
              subtitle: expensesSubtitle,
            ),
            const SizedBox(height: 24),

            // Sección: Balances
            const Text(
              'Balances',
              style: TextStyle(
                fontFamily: 'Figtree',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: Color(0xFF11232D),
              ),
            ),
            const SizedBox(height: 12),

            // Card con lista de balances de cada miembro
            _BalancesListCard(
              balances: balances,
              allMembers: widget.group.members,
              currencySymbol: currencySymbol,
              formatAmount: _formatAmount,
            ),
            const SizedBox(height: 24),

            // Sección: Pagos sugeridos o ¡Cuentas claras!
            if (suggested.isNotEmpty) ...[
              const Text(
                'Pagos sugeridos',
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: Color(0xFF11232D),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Con estos pagos, las cuentas quedan equilibradas.',
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF586974),
                ),
              ),
              const SizedBox(height: 14),
              for (final item in suggested) ...[
                _SuggestedPaymentCard(
                  settlement: item,
                  allMembers: widget.group.members,
                  currencySymbol: currencySymbol,
                  formatAmount: _formatAmount,
                  onConfirm: () => _openConfirmPaymentModal(item),
                ),
                const SizedBox(height: 12),
              ],
            ] else ...[
              // ¡Cuentas claras! (Imagen 3)
              const _SettledAccountsCard(),
            ],

            // Pagos ya confirmados (si hay liquidaciones registradas)
            if (widget.group.settlementPayments.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Pagos registrados',
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: Color(0xFF11232D),
                ),
              ),
              const SizedBox(height: 12),
              for (final payment in widget.group.settlementPayments) ...[
                _ConfirmedPaymentCard(
                  payment: payment,
                  currencySymbol: currencySymbol,
                  formatAmount: _formatAmount,
                  onDelete: () => _deleteSettlement(payment),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ],
      ),
    ),
    if (_showPaymentRegisteredToast)
      const Positioned(
        left: 16,
        right: 16,
        bottom: 12,
        child: _PaymentRegisteredBanner(),
      ),
  ],
);
}
}

/// Estado vacío fiel a la Imagen 1
class _EmptyBalancesCard extends StatelessWidget {
  const _EmptyBalancesCard({required this.onNavigateToExpenses});

  final VoidCallback onNavigateToExpenses;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 380,
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
              // Círculo teal con ícono de flechas de intercambio
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D7E88),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),

              // Texto explicativo
              const Text(
                'Todavía no hay cuentas para calcular.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: Color(0xFF11232D),
                ),
              ),
              const SizedBox(height: 18),

              // Botón blanco "Ir a gastos"
              InkWell(
                key: const Key('go-to-expenses-button'),
                onTap: onNavigateToExpenses,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Ir a gastos',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      color: Color(0xFF0D7E88),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero card "Total gastado" (Imágenes 2 y 3)
class _TotalSpentHeroCard extends StatelessWidget {
  const _TotalSpentHeroCard({
    required this.totalSpentText,
    required this.subtitle,
  });

  final String totalSpentText;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF1EF),
        borderRadius: BorderRadius.circular(24),
      ),
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
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              color: Color(0xFF11232D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Figtree',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF586974),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con la lista de balances de los integrantes (Imágenes 2 y 3)
class _BalancesListCard extends StatelessWidget {
  const _BalancesListCard({
    required this.balances,
    required this.allMembers,
    required this.currencySymbol,
    required this.formatAmount,
  });

  final List<MemberBalance> balances;
  final List<Person> allMembers;
  final String currencySymbol;
  final String Function(double) formatAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < balances.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE9EDF0),
              ),
            _MemberBalanceRow(
              balanceItem: balances[i],
              index: i,
              isSelf: i == 0,
              allMembers: allMembers,
              currencySymbol: currencySymbol,
              formatAmount: formatAmount,
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberBalanceRow extends StatelessWidget {
  const _MemberBalanceRow({
    required this.balanceItem,
    required this.index,
    required this.isSelf,
    required this.allMembers,
    required this.currencySymbol,
    required this.formatAmount,
  });

  final MemberBalance balanceItem;
  final int index;
  final bool isSelf;
  final List<Person> allMembers;
  final String currencySymbol;
  final String Function(double) formatAmount;

  @override
  Widget build(BuildContext context) {
    final memberIndex =
        allMembers.indexWhere((m) => m.id == balanceItem.id);
    final avatarColor = AppPalette.memberColor(
      memberIndex >= 0 ? memberIndex : index,
    );
    final initial = balanceItem.name.isNotEmpty
        ? balanceItem.name[0].toUpperCase()
        : '?';

    final isCreditor = balanceItem.balance > 0.01;
    final isDebtor = balanceItem.balance < -0.01;

    String statusText;
    Color statusColor;

    if (isCreditor) {
      statusText = 'Le deben $currencySymbol${formatAmount(balanceItem.balance)}';
      statusColor = const Color(0xFF0D7E88); // Teal
    } else if (isDebtor) {
      statusText =
          'Debe $currencySymbol${formatAmount(balanceItem.balance.abs())}';
      statusColor = const Color(0xFFC6500A); // Rust/Orange
    } else {
      statusText = 'Al día · ${currencySymbol}0';
      statusColor = const Color(0xFF586974); // Gray
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                fontFamily: 'Figtree',
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Nombre de la persona y badge Vos
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    balanceItem.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: Color(0xFF11232D),
                    ),
                  ),
                ),
                if (isSelf) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDF1EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Vos',
                      style: TextStyle(
                        fontFamily: 'Figtree',
                        color: Color(0xFF0D7E88),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Estado del balance
          Text(
            statusText,
            style: TextStyle(
              fontFamily: 'Figtree',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de pago sugerido (Imagen 2)
class _SuggestedPaymentCard extends StatelessWidget {
  const _SuggestedPaymentCard({
    required this.settlement,
    required this.allMembers,
    required this.currencySymbol,
    required this.formatAmount,
    required this.onConfirm,
  });

  final FormattedSettlement settlement;
  final List<Person> allMembers;
  final String currencySymbol;
  final String Function(double) formatAmount;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final payerIndex =
        allMembers.indexWhere((m) => m.id == settlement.payerId);
    final payeeIndex =
        allMembers.indexWhere((m) => m.id == settlement.payeeId);

    final payerColor = AppPalette.memberColor(payerIndex >= 0 ? payerIndex : 0);
    final payeeColor = AppPalette.memberColor(payeeIndex >= 0 ? payeeIndex : 1);

    final payerInitial = settlement.payerName.isNotEmpty
        ? settlement.payerName[0].toUpperCase()
        : '?';
    final payeeInitial = settlement.payeeName.isNotEmpty
        ? settlement.payeeName[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fila superior: Avatares + Texto "X paga a Y" + Monto
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                // Avatar pagador
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: payerColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    payerInitial,
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Flecha
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Color(0xFF586974),
                ),
                const SizedBox(width: 8),

                // Avatar cobrador
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: payeeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    payeeInitial,
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Texto descriptivo
                Expanded(
                  child: Text(
                    '${settlement.payerName} paga a ${settlement.payeeName}',
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF11232D),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Importe
                Text(
                  '$currencySymbol${formatAmount(settlement.amount)}',
                  style: const TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF11232D),
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE9EDF0),
          ),

          // Botón "Marcar como pagado"
          InkWell(
            key: Key('settle-button-${settlement.payerId}-${settlement.payeeId}'),
            onTap: onConfirm,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(22),
            ),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Color(0xFF0D7E88),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Marcar como pagado',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      color: Color(0xFF0D7E88),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado "¡Cuentas claras!" fiel a la Imagen 3
class _SettledAccountsCard extends StatelessWidget {
  const _SettledAccountsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF1EF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Círculo teal con checkmark blanco
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF0D7E88),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),

          // Título
          const Text(
            '¡Cuentas claras!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Figtree',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: Color(0xFF11232D),
            ),
          ),
          const SizedBox(height: 8),

          // Subtítulo
          const Text(
            'No quedan pagos pendientes en este grupo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Figtree',
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w400,
              color: Color(0xFF586974),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de pago ya registrado / confirmado
class _ConfirmedPaymentCard extends StatelessWidget {
  const _ConfirmedPaymentCard({
    required this.payment,
    required this.currencySymbol,
    required this.formatAmount,
    required this.onDelete,
  });

  final SettlementPayment payment;
  final String currencySymbol;
  final String Function(double) formatAmount;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E7EB), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 22,
            color: Color(0xFF0D7E88),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payment.payerName} pagó a ${payment.payeeName}',
                  style: const TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF11232D),
                  ),
                ),
                Text(
                  '$currencySymbol${formatAmount(payment.amount)}',
                  style: const TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D7E88),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: const Color(0xFF586974),
            onPressed: onDelete,
            tooltip: 'Anular pago',
          ),
        ],
      ),
    );
  }
}

class _ConfirmPaymentResult {
  const _ConfirmPaymentResult({
    required this.date,
    this.note,
  });

  final DateTime date;
  final String? note;
}

/// Modal inferior de confirmación de pago (Imagen 1)
class _ConfirmPaymentBottomSheet extends StatefulWidget {
  const _ConfirmPaymentBottomSheet({
    required this.settlement,
    required this.allMembers,
    required this.currencySymbol,
    required this.formatAmount,
  });

  final FormattedSettlement settlement;
  final List<Person> allMembers;
  final String currencySymbol;
  final String Function(double) formatAmount;

  @override
  State<_ConfirmPaymentBottomSheet> createState() =>
      _ConfirmPaymentBottomSheetState();
}

class _ConfirmPaymentBottomSheetState
    extends State<_ConfirmPaymentBottomSheet> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF0D7E88),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final settlement = widget.settlement;
    final payerIndex =
        widget.allMembers.indexWhere((m) => m.id == settlement.payerId);
    final payeeIndex =
        widget.allMembers.indexWhere((m) => m.id == settlement.payeeId);

    final payerColor =
        AppPalette.memberColor(payerIndex >= 0 ? payerIndex : 0);
    final payeeColor =
        AppPalette.memberColor(payeeIndex >= 0 ? payeeIndex : 1);

    final payerInitial = settlement.payerName.isNotEmpty
        ? settlement.payerName[0].toUpperCase()
        : '?';
    final payeeInitial = settlement.payeeName.isNotEmpty
        ? settlement.payeeName[0].toUpperCase()
        : '?';

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 20 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle superior gris centrado
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Título
              const Text(
                '¿Confirmar pago?',
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Color(0xFF11232D),
                ),
              ),
              const SizedBox(height: 6),

              // Subtítulo
              const Text(
                'Este pago se registrará en el grupo y actualizará las cuentas.',
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                  color: Color(0xFF586974),
                ),
              ),
              const SizedBox(height: 18),

              // Tarjeta menta con los avatares, flecha y monto grande
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F1EF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Avatar pagador
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: payerColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            payerInitial,
                            style: const TextStyle(
                              fontFamily: 'Figtree',
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          settlement.payerName,
                          style: const TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF11232D),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Color(0xFF586974),
                        ),
                        const SizedBox(width: 8),
                        // Avatar cobrador
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: payeeColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            payeeInitial,
                            style: const TextStyle(
                              fontFamily: 'Figtree',
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          settlement.payeeName,
                          style: const TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF11232D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${widget.currencySymbol}${widget.formatAmount(settlement.amount)}',
                      style: const TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        color: Color(0xFF11232D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pago sugerido para saldar cuentas',
                      style: TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF586974),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Campo 1: Fecha del pago
              InkWell(
                key: const Key('modal-pick-date-button'),
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E7EB),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fecha del pago',
                            style: TextStyle(
                              fontFamily: 'Figtree',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF586974),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isToday(_selectedDate)
                                ? 'Hoy'
                                : _formatDate(_selectedDate),
                            style: const TextStyle(
                              fontFamily: 'Figtree',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF11232D),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Color(0xFF0D7E88),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Campo 2: Nota opcional
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E7EB),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nota opcional',
                      style: TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF586974),
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      key: const Key('modal-payment-note-field'),
                      controller: _noteController,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: 'Ej. Transferencia bancaria',
                        hintStyle: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8C98A0),
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF11232D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botón principal "Confirmar pago"
              FilledButton(
                key: const Key('modal-confirm-payment-button'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D7E88),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(
                    _ConfirmPaymentResult(
                      date: _selectedDate,
                      note: _noteController.text.trim().isEmpty
                          ? null
                          : _noteController.text.trim(),
                    ),
                  );
                },
                child: const Text(
                  'Confirmar pago',
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Botón secundario "Cancelar"
              Center(
                child: TextButton(
                  key: const Key('modal-cancel-payment-button'),
                  onPressed: () => Navigator.of(context).pop(null),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating toast/banner "Pago registrado" (Imágenes 2 y 3)
class _PaymentRegisteredBanner extends StatelessWidget {
  const _PaymentRegisteredBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const Key('payment-registered-toast'),
        width: double.infinity,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF112028),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'Pago registrado',
              style: TextStyle(
                fontFamily: 'Figtree',
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
