import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/currency.dart';
import '../../../domain/models/person.dart';
import '../../../domain/models/split_type.dart';

/// Resultado devuelto por [SplitExpenseScreen] al confirmar.
class SplitExpenseResult {
  const SplitExpenseResult({
    required this.payerAmounts,
    required this.splitType,
    required this.splitDetails,
    required this.participantIds,
  });

  /// personaId -> monto aportado por cada pagador.
  final Map<String, double> payerAmounts;

  /// Tipo de división elegida.
  final SplitType splitType;

  /// Detalles numéricos por participante según la modalidad elegida:
  /// - `byAmount`: monto asignado
  /// - `byPercentage`: porcentaje asignado (0-100)
  /// - `byShares`: cantidad de partes asignadas
  /// - `equally`: mapa vacío o nulo
  final Map<String, double> splitDetails;

  /// Conjunto de IDs de participantes que entran en la división.
  final Set<String> participantIds;
}

/// Pantalla «Dividir gasto» fiel a las 4 referencias visuales:
/// - Imagen 1: Sección ¿Quién pagó? + Tab «Igual»
/// - Imagen 2: Tab «%» con porcentajes y subtotales calculados
/// - Imagen 3: Tab «Montos» con alerta «Faltan $10.000...» y botón «Listo» deshabilitado
/// - Imagen 4: Tab «Partes» con steppers (- / +) y resumen de valor por parte
class SplitExpenseScreen extends StatefulWidget {
  const SplitExpenseScreen({
    super.key,
    required this.description,
    required this.totalAmount,
    required this.currency,
    required this.members,
    this.initialPayers,
    this.initialSplitType = SplitType.equally,
    this.initialSplitDetails,
    this.initialParticipantIds,
  });

  final String description;
  final double totalAmount;
  final Currency currency;
  final List<Person> members;
  final Map<String, double>? initialPayers;
  final SplitType initialSplitType;
  final Map<String, double>? initialSplitDetails;
  final Set<String>? initialParticipantIds;

  @override
  State<SplitExpenseScreen> createState() => _SplitExpenseScreenState();
}

class _SplitExpenseScreenState extends State<SplitExpenseScreen> {
  late SplitType _splitType;
  late Set<String> _selectedParticipantIds;

  // Montos aportados por cada persona (personId -> monto)
  late Map<String, double> _payerAmounts;

  // Modalidad Montos fijos (personId -> monto)
  late Map<String, double> _fixedAmounts;

  // Modalidad Porcentajes (personId -> porcentaje)
  late Map<String, double> _percentages;

  // Modalidad Partes (personId -> partes)
  late Map<String, int> _shares;

  @override
  void initState() {
    super.initState();
    _splitType = widget.initialSplitType;

    // Participantes seleccionados
    _selectedParticipantIds = widget.initialParticipantIds != null &&
            widget.initialParticipantIds!.isNotEmpty
        ? Set<String>.from(widget.initialParticipantIds!)
        : widget.members.map((m) => m.id).toSet();

    // Pagadores iniciales
    _payerAmounts = {};
    if (widget.initialPayers != null && widget.initialPayers!.isNotEmpty) {
      for (final m in widget.members) {
        _payerAmounts[m.id] = widget.initialPayers![m.id] ?? 0.0;
      }
    } else {
      // Por defecto, la primera persona paga el 100%
      for (var i = 0; i < widget.members.length; i++) {
        final m = widget.members[i];
        _payerAmounts[m.id] = i == 0 ? widget.totalAmount : 0.0;
      }
    }

    // Montos fijos
    _fixedAmounts = {};
    if (widget.initialSplitDetails != null &&
        widget.initialSplitType == SplitType.byAmount) {
      for (final m in widget.members) {
        _fixedAmounts[m.id] = widget.initialSplitDetails![m.id] ?? 0.0;
      }
    } else {
      final count = _selectedParticipantIds.length;
      final perPerson = count > 0 ? (widget.totalAmount / count) : 0.0;
      for (final m in widget.members) {
        _fixedAmounts[m.id] =
            _selectedParticipantIds.contains(m.id) ? perPerson : 0.0;
      }
    }

    // Porcentajes
    _percentages = {};
    if (widget.initialSplitDetails != null &&
        widget.initialSplitType == SplitType.byPercentage) {
      for (final m in widget.members) {
        _percentages[m.id] = widget.initialSplitDetails![m.id] ?? 0.0;
      }
    } else {
      final count = _selectedParticipantIds.length;
      final perPersonPct = count > 0 ? (100.0 / count) : 0.0;
      for (final m in widget.members) {
        _percentages[m.id] =
            _selectedParticipantIds.contains(m.id) ? perPersonPct : 0.0;
      }
    }

    // Partes
    _shares = {};
    if (widget.initialSplitDetails != null &&
        widget.initialSplitType == SplitType.byShares) {
      for (final m in widget.members) {
        _shares[m.id] =
            (widget.initialSplitDetails![m.id] ?? 1.0).round().clamp(0, 99);
      }
    } else {
      for (final m in widget.members) {
        _shares[m.id] = _selectedParticipantIds.contains(m.id) ? 1 : 0;
      }
    }
  }

  // -------------------------------------------------------------
  // Formateo y utilidades matemáticas
  // -------------------------------------------------------------

  static String _formatWithDots(String digits) {
    final buffer = StringBuffer();
    final len = digits.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String _formatCurrency(double val, {bool spaced = false}) {
    final integerPart = val.round().abs();
    final dots = _formatWithDots(integerPart.toString());
    final sym = widget.currency.symbol;
    return spaced ? '$sym $dots' : '$sym$dots';
  }

  double get _totalPaid =>
      _payerAmounts.values.fold(0.0, (acc, val) => acc + val);

  bool get _isPayersSumValid => (_totalPaid - widget.totalAmount).abs() < 0.01;

  double get _totalFixedAmounts => _selectedParticipantIds.fold(
        0.0,
        (acc, id) => acc + (_fixedAmounts[id] ?? 0.0),
      );

  bool get _isFixedAmountsValid =>
      (_totalFixedAmounts - widget.totalAmount).abs() < 0.01;

  double get _totalPercentages => _selectedParticipantIds.fold(
        0.0,
        (acc, id) => acc + (_percentages[id] ?? 0.0),
      );

  bool get _isPercentagesValid => (_totalPercentages - 100.0).abs() < 0.01;

  int get _totalSharesCount => _selectedParticipantIds.fold(
        0,
        (acc, id) => acc + (_shares[id] ?? 0),
      );

  bool get _isSharesValid => _totalSharesCount > 0;

  bool get _isSplitValid {
    return switch (_splitType) {
      SplitType.equally => _selectedParticipantIds.isNotEmpty,
      SplitType.byAmount => _isFixedAmountsValid,
      SplitType.byPercentage => _isPercentagesValid,
      SplitType.byShares => _isSharesValid,
    };
  }

  bool get _canSubmit => _isPayersSumValid && _isSplitValid;

  // -------------------------------------------------------------
  // Acciones de Pagadores
  // -------------------------------------------------------------

  void _togglePayer(Person person) {
    setState(() {
      final current = _payerAmounts[person.id] ?? 0.0;
      if (current > 0) {
        _payerAmounts[person.id] = 0.0;
      } else {
        // Asignar lo que falte para completar el total, o el total si nada está asignado
        final remaining = widget.totalAmount - _totalPaid;
        if (remaining > 0) {
          _payerAmounts[person.id] = remaining;
        } else {
          // Si ya está completo, repartir equitativamente entre los activos + este nuevo
          final activeIds = _payerAmounts.entries
              .where((e) => e.value > 0)
              .map((e) => e.key)
              .toSet();
          activeIds.add(person.id);
          final perPayer = widget.totalAmount / activeIds.length;
          for (final m in widget.members) {
            _payerAmounts[m.id] = activeIds.contains(m.id) ? perPayer : 0.0;
          }
        }
      }
    });
  }

  Future<void> _editPayerAmount(Person person) async {
    final current = _payerAmounts[person.id] ?? 0.0;
    final newVal = await _showNumericInputDialog(
      title: '¿Cuánto pagó ${person.name}?',
      initialValue: current,
      prefix: '${widget.currency.symbol} ',
    );

    if (newVal != null) {
      setState(() {
        _payerAmounts[person.id] = newVal;
      });
    }
  }

  // -------------------------------------------------------------
  // Acciones de División
  // -------------------------------------------------------------

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

  Future<void> _editFixedAmount(Person person) async {
    final current = _fixedAmounts[person.id] ?? 0.0;
    final newVal = await _showNumericInputDialog(
      title: 'Monto para ${person.name}',
      initialValue: current,
      prefix: '${widget.currency.symbol} ',
    );

    if (newVal != null) {
      setState(() {
        _fixedAmounts[person.id] = newVal;
        _selectedParticipantIds.add(person.id);
      });
    }
  }

  Future<void> _editPercentage(Person person) async {
    final current = _percentages[person.id] ?? 0.0;
    final newVal = await _showNumericInputDialog(
      title: 'Porcentaje para ${person.name}',
      initialValue: current,
      suffix: ' %',
    );

    if (newVal != null) {
      setState(() {
        _percentages[person.id] = newVal;
        _selectedParticipantIds.add(person.id);
      });
    }
  }

  void _incrementShares(Person person) {
    setState(() {
      _selectedParticipantIds.add(person.id);
      final curr = _shares[person.id] ?? 0;
      _shares[person.id] = (curr + 1).clamp(0, 99);
    });
  }

  void _decrementShares(Person person) {
    setState(() {
      final curr = _shares[person.id] ?? 0;
      if (curr > 0) {
        _shares[person.id] = curr - 1;
      }
    });
  }

  // -------------------------------------------------------------
  // Diálogo numérico modal estilo iOS
  // -------------------------------------------------------------

  Future<double?> _showNumericInputDialog({
    required String title,
    required double initialValue,
    String? prefix,
    String? suffix,
  }) async {
    final initialText = initialValue > 0 ? initialValue.round().toString() : '';
    final controller = TextEditingController(
      text: initialText.isNotEmpty ? _formatWithDots(initialText) : '',
    );

    return showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF11232D),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0D7E88),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (prefix != null)
                        Text(
                          prefix,
                          style: const TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF11232D),
                          ),
                        ),
                      Expanded(
                        child: TextField(
                          key: const Key('numeric-input-dialog-field'),
                          controller: controller,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF11232D),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                          ),
                          onChanged: (val) {
                            final clean = val.replaceAll('.', '');
                            if (clean.isEmpty) return;
                            final formatted = _formatWithDots(clean);
                            if (formatted != val) {
                              controller.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                  offset: formatted.length,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      if (suffix != null)
                        Text(
                          suffix,
                          style: const TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF11232D),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    key: const Key('numeric-input-confirm-button'),
                    onPressed: () {
                      final clean =
                          controller.text.replaceAll('.', '').trim();
                      final val = double.tryParse(clean) ?? 0.0;
                      Navigator.of(ctx).pop(val);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D7E88),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Aceptar',
                      style: TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // Confirmación final
  // -------------------------------------------------------------

  void _submit() {
    if (!_canSubmit) return;

    final Map<String, double> finalDetails = switch (_splitType) {
      SplitType.equally => {},
      SplitType.byAmount => Map.from(_fixedAmounts),
      SplitType.byPercentage => Map.from(_percentages),
      SplitType.byShares => _shares.map((k, v) => MapEntry(k, v.toDouble())),
    };

    final result = SplitExpenseResult(
      payerAmounts: Map.from(_payerAmounts),
      splitType: _splitType,
      splitDetails: finalDetails,
      participantIds: Set.from(_selectedParticipantIds),
    );

    Navigator.of(context).pop(result);
  }

  // -------------------------------------------------------------
  // UI Build
  // -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final descText = widget.description.trim().isEmpty
        ? 'Gasto'
        : widget.description.trim();
    final overTitle =
        '$descText · ${_formatCurrency(widget.totalAmount)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header con back arrow, sobre-título y título grande
            _buildHeader(overTitle),

            // Contenido desplazable
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // 1. ¿Quién pagó?
                  _buildPayersSection(),
                  const SizedBox(height: 28),

                  // 2. ¿Cómo se divide?
                  _buildSplitSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Botón inferior fijo «Listo»
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String overTitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            key: const Key('split-expense-back-button'),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF11232D),
              size: 26,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overTitle,
                  style: const TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF586974),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Dividir gasto',
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF11232D),
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Sección 1: ¿Quién pagó?
  // -------------------------------------------------------------

  Widget _buildPayersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Quién pagó?',
          style: TextStyle(
            fontFamily: 'Figtree',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF11232D),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Marcá a quienes pusieron plata e indicá cuánto.',
          style: TextStyle(
            fontFamily: 'Figtree',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF586974),
          ),
        ),
        const SizedBox(height: 14),

        // Tarjeta contenedora de miembros
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8EA)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < widget.members.length; i++) ...[
                if (i > 0)
                  const Divider(color: Color(0xFFF1F5F7), height: 1),
                _buildPayerRow(widget.members[i], i),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Estado / Verificación inferior
        _buildPayersStatus(),
      ],
    );
  }

  Widget _buildPayerRow(Person person, int index) {
    final amount = _payerAmounts[person.id] ?? 0.0;
    final isChecked = amount > 0;
    final avatarColor = AppPalette.memberColor(index);

    return InkWell(
      onTap: () => _togglePayer(person),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Checkbox personalizado estilo iOS
            _buildCheckbox(
              key: Key('payer-checkbox-${person.id}'),
              isChecked: isChecked,
              onTap: () => _togglePayer(person),
            ),
            const SizedBox(width: 12),

            // Avatar circular con color e inicial
            _buildAvatarCircle(avatarColor, person.name),
            const SizedBox(width: 12),

            // Nombre
            Expanded(
              child: Text(
                person.name,
                style: const TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF11232D),
                ),
              ),
            ),

            // Input pill de monto aportado
            GestureDetector(
              onTap: () => _editPayerAmount(person),
              child: Container(
                key: Key('payer-amount-pill-${person.id}'),
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatCurrency(amount, spaced: true),
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isChecked
                        ? const Color(0xFF11232D)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayersStatus() {
    final diff = widget.totalAmount - _totalPaid;

    if (_isPayersSumValid) {
      return Row(
        children: [
          const Icon(Icons.check_rounded, color: Color(0xFF0D7E88), size: 18),
          const SizedBox(width: 6),
          Text(
            'Suma ${_formatCurrency(_totalPaid)} de ${_formatCurrency(widget.totalAmount)}',
            style: const TextStyle(
              fontFamily: 'Figtree',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D7E88),
            ),
          ),
        ],
      );
    } else if (diff > 0) {
      return Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFC2410C),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            'Faltan ${_formatCurrency(diff)} para llegar a ${_formatCurrency(widget.totalAmount)}',
            style: const TextStyle(
              fontFamily: 'Figtree',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC2410C),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFC2410C),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            'Sobran ${_formatCurrency(-diff)} (supera los ${_formatCurrency(widget.totalAmount)})',
            style: const TextStyle(
              fontFamily: 'Figtree',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC2410C),
            ),
          ),
        ],
      );
    }
  }

  // -------------------------------------------------------------
  // Sección 2: ¿Cómo se divide?
  // -------------------------------------------------------------

  Widget _buildSplitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Cómo se divide?',
          style: TextStyle(
            fontFamily: 'Figtree',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF11232D),
          ),
        ),
        const SizedBox(height: 12),

        // Segmented Control de 4 opciones: Igual | Montos | % | Partes
        _buildSegmentedTabs(),
        const SizedBox(height: 14),

        // Tarjeta con la lista según el tab seleccionado
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8EA)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < widget.members.length; i++) ...[
                if (i > 0)
                  const Divider(color: Color(0xFFF1F5F7), height: 1),
                _buildSplitRow(widget.members[i], i),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Estado inferior de la división elegida
        _buildSplitStatus(),
      ],
    );
  }

  Widget _buildSegmentedTabs() {
    final tabs = [
      (SplitType.equally, 'Igual', 'tab-split-equally'),
      (SplitType.byAmount, 'Montos', 'tab-split-amounts'),
      (SplitType.byPercentage, '%', 'tab-split-percentage'),
      (SplitType.byShares, 'Partes', 'tab-split-shares'),
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFD8E2E5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _splitType == tab.$1;
          return Expanded(
            child: GestureDetector(
              key: Key(tab.$3),
              onTap: () => setState(() => _splitType = tab.$1),
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF0D7E88) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tab.$2,
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w700,
                    color:
                        isSelected ? Colors.white : const Color(0xFF586974),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSplitRow(Person person, int index) {
    final isSelected = _selectedParticipantIds.contains(person.id);
    final avatarColor = AppPalette.memberColor(index);

    return InkWell(
      onTap: () => _toggleParticipant(person),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Checkbox
            _buildCheckbox(
              key: Key('participant-checkbox-${person.id}'),
              isChecked: isSelected,
              onTap: () => _toggleParticipant(person),
            ),
            const SizedBox(width: 12),

            // Avatar
            _buildAvatarCircle(avatarColor, person.name),
            const SizedBox(width: 12),

            // Nombre y subtítulo opcional
            Expanded(
              child: _buildParticipantLabelAndSubtitle(person, isSelected),
            ),

            // Control a la derecha según el modo de división
            _buildSplitRowTrailing(person, isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantLabelAndSubtitle(Person person, bool isSelected) {
    final nameWidget = Text(
      person.name,
      style: const TextStyle(
        fontFamily: 'Figtree',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF11232D),
      ),
    );

    if (!isSelected) {
      return nameWidget;
    }

    // Subtítulo con el valor calculado en monedas para % y Partes (Imágenes 2 y 4)
    if (_splitType == SplitType.byPercentage) {
      final pct = _percentages[person.id] ?? 0.0;
      final val = widget.totalAmount * (pct / 100.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          nameWidget,
          Text(
            _formatCurrency(val),
            style: const TextStyle(
              fontFamily: 'Figtree',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF586974),
            ),
          ),
        ],
      );
    } else if (_splitType == SplitType.byShares) {
      final sh = _shares[person.id] ?? 0;
      final totalSh = _totalSharesCount;
      final val = totalSh > 0
          ? widget.totalAmount * (sh / totalSh.toDouble())
          : 0.0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          nameWidget,
          Text(
            _formatCurrency(val),
            style: const TextStyle(
              fontFamily: 'Figtree',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF586974),
            ),
          ),
        ],
      );
    }

    return nameWidget;
  }

  Widget _buildSplitRowTrailing(Person person, bool isSelected) {
    if (!isSelected) {
      return const SizedBox.shrink();
    }

    switch (_splitType) {
      // 1. Modalidad Igual (Imagen 1): texto simple con el monto exacto
      case SplitType.equally:
        final count = _selectedParticipantIds.length;
        final share = count > 0 ? (widget.totalAmount / count) : 0.0;
        return Text(
          _formatCurrency(share),
          style: const TextStyle(
            fontFamily: 'Figtree',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF11232D),
          ),
        );

      // 2. Modalidad Montos (Imagen 3): Pill interactivo con monto editable
      case SplitType.byAmount:
        final amount = _fixedAmounts[person.id] ?? 0.0;
        return GestureDetector(
          onTap: () => _editFixedAmount(person),
          child: Container(
            key: Key('split-amount-pill-${person.id}'),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatCurrency(amount, spaced: true),
              style: const TextStyle(
                fontFamily: 'Figtree',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF11232D),
              ),
            ),
          ),
        );

      // 3. Modalidad % (Imagen 2): Pill con porcentaje editable
      case SplitType.byPercentage:
        final pct = _percentages[person.id] ?? 0.0;
        final pctDisplay = pct % 1 == 0
            ? pct.toInt().toString()
            : pct.toStringAsFixed(1);
        return GestureDetector(
          onTap: () => _editPercentage(person),
          child: Container(
            key: Key('split-percentage-pill-${person.id}'),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$pctDisplay %',
              style: const TextStyle(
                fontFamily: 'Figtree',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF11232D),
              ),
            ),
          ),
        );

      // 4. Modalidad Partes (Imagen 4): Stepper circular (- y +)
      case SplitType.byShares:
        final sh = _shares[person.id] ?? 1;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón menos circular
            GestureDetector(
              key: Key('shares-minus-${person.id}'),
              onTap: () => _decrementShares(person),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F7),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.remove_rounded,
                  size: 20,
                  color: Color(0xFF11232D),
                ),
              ),
            ),
            // Cantidad
            SizedBox(
              width: 32,
              child: Text(
                '$sh',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF11232D),
                ),
              ),
            ),
            // Botón más circular
            GestureDetector(
              key: Key('shares-plus-${person.id}'),
              onTap: () => _incrementShares(person),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F7),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: Color(0xFF11232D),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildSplitStatus() {
    switch (_splitType) {
      // Imagen 1: «Cada persona paga $40.000»
      case SplitType.equally:
        final count = _selectedParticipantIds.length;
        if (count == 0) {
          return const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFC2410C),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Seleccioná al menos un participante',
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC2410C),
                ),
              ),
            ],
          );
        }
        final share = widget.totalAmount / count;
        return Row(
          children: [
            const Icon(Icons.check_rounded, color: Color(0xFF0D7E88), size: 18),
            const SizedBox(width: 6),
            Text(
              'Cada persona paga ${_formatCurrency(share)}',
              style: const TextStyle(
                fontFamily: 'Figtree',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D7E88),
              ),
            ),
          ],
        );

      // Imagen 3: «Faltan $10.000 para llegar a $120.000» o «Suma $120.000...»
      case SplitType.byAmount:
        final sum = _totalFixedAmounts;
        final diff = widget.totalAmount - sum;
        if (_isFixedAmountsValid) {
          return Row(
            children: [
              const Icon(
                Icons.check_rounded,
                color: Color(0xFF0D7E88),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Suma ${_formatCurrency(sum)} de ${_formatCurrency(widget.totalAmount)}',
                style: const TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D7E88),
                ),
              ),
            ],
          );
        } else if (diff > 0) {
          return Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFC2410C),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Faltan ${_formatCurrency(diff)} para llegar a ${_formatCurrency(widget.totalAmount)}',
                style: const TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC2410C),
                ),
              ),
            ],
          );
        } else {
          return Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFC2410C),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Sobran ${_formatCurrency(-diff)} (supera los ${_formatCurrency(widget.totalAmount)})',
                style: const TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC2410C),
                ),
              ),
            ],
          );
        }

      // Imagen 2: «Suma 100 %»
      case SplitType.byPercentage:
        final sum = _totalPercentages;
        final sumDisplay = sum % 1 == 0 ? sum.toInt() : sum.toStringAsFixed(1);
        if (_isPercentagesValid) {
          return const Row(
            children: [
              Icon(Icons.check_rounded, color: Color(0xFF0D7E88), size: 18),
              SizedBox(width: 6),
              Text(
                'Suma 100 %',
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D7E88),
                ),
              ),
            ],
          );
        } else {
          final diff = (100.0 - sum).abs();
          final diffDisplay =
              diff % 1 == 0 ? diff.toInt() : diff.toStringAsFixed(1);
          final label = sum < 100
              ? 'Suma $sumDisplay % (faltan $diffDisplay %)'
              : 'Suma $sumDisplay % (supera el 100 %)';
          return Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFC2410C),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC2410C),
                ),
              ),
            ],
          );
        }

      // Imagen 4: «4 partes · cada parte vale $30.000»
      case SplitType.byShares:
        final totalSh = _totalSharesCount;
        if (totalSh == 0) {
          return const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFC2410C),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Asigná al menos 1 parte para repartir',
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC2410C),
                ),
              ),
            ],
          );
        }
        final valuePerShare = widget.totalAmount / totalSh;
        return Row(
          children: [
            const Icon(Icons.check_rounded, color: Color(0xFF0D7E88), size: 18),
            const SizedBox(width: 6),
            Text(
              '$totalSh partes · cada parte vale ${_formatCurrency(valuePerShare)}',
              style: const TextStyle(
                fontFamily: 'Figtree',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D7E88),
              ),
            ),
          ],
        );
    }
  }

  // -------------------------------------------------------------
  // Componentes comunes
  // -------------------------------------------------------------

  Widget _buildCheckbox({
    Key? key,
    required bool isChecked,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isChecked ? const Color(0xFF0D7E88) : Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: isChecked
              ? null
              : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        ),
        alignment: Alignment.center,
        child: isChecked
            ? const Icon(
                Icons.check_rounded,
                size: 18,
                color: Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _buildAvatarCircle(Color color, String name) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontFamily: 'Figtree',
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Barra de acción fija inferior «Listo»
  // -------------------------------------------------------------

  Widget _buildBottomActionBar() {
    return Container(
      color: const Color(0xFFF7FBFB),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          key: const Key('split-expense-confirm-button'),
          onPressed: _canSubmit ? _submit : null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0D7E88),
            disabledBackgroundColor: const Color(0xFFD5DEE2),
            disabledForegroundColor: const Color(0xFF7E8F9B),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Listo',
            style: TextStyle(
              fontFamily: 'Figtree',
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
