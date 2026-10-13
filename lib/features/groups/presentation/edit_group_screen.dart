import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/local_group_repository.dart';
import '../../../domain/models/currency.dart';
import '../../../domain/models/group.dart';
import '../application/group_operations.dart';

class _GroupIconChoice {
  const _GroupIconChoice(this.name, this.icon);
  final String name;
  final IconData icon;
}

class _GroupColorChoice {
  const _GroupColorChoice(this.hex, this.color);
  final String hex;
  final Color color;
}

/// Pantalla de Editar grupo con diseño idéntico a las imágenes de referencia.
class EditGroupScreen extends StatefulWidget {
  const EditGroupScreen({
    super.key,
    required this.group,
    required this.repository,
  });

  final Group group;
  final LocalGroupRepository repository;

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  static const _choices = <_GroupIconChoice>[
    _GroupIconChoice('grill', Icons.outdoor_grill_outlined),
    _GroupIconChoice('food', Icons.restaurant_outlined),
    _GroupIconChoice('home', Icons.home_outlined),
    _GroupIconChoice('flight', Icons.flight_takeoff_rounded),
    _GroupIconChoice('beach', Icons.beach_access_outlined),
    _GroupIconChoice('toast', Icons.wine_bar_outlined),
    _GroupIconChoice('soccer', Icons.sports_soccer_outlined),
    _GroupIconChoice('cart', Icons.shopping_cart_outlined),
    _GroupIconChoice('gift', Icons.card_giftcard_outlined),
    _GroupIconChoice('briefcase', Icons.business_center_outlined),
    _GroupIconChoice('mountain', Icons.terrain_outlined),
    _GroupIconChoice('celebration', Icons.celebration_outlined),
  ];

  static const _colors = <_GroupColorChoice>[
    _GroupColorChoice('#0D7E88', AppPalette.lightTeal),
    _GroupColorChoice('#C6500A', Color(0xFFC6500A)),
    _GroupColorChoice('#6C49C8', Color(0xFF6C49C8)),
    _GroupColorChoice('#3264C9', Color(0xFF3264C9)),
    _GroupColorChoice('#2F8557', Color(0xFF2F8557)),
    _GroupColorChoice('#C53678', Color(0xFFC53678)),
  ];

  late final TextEditingController _nameController =
      TextEditingController(text: widget.group.name);
  late final FocusNode _nameFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late String _iconName = widget.group.iconName ?? 'flight';
  late String _colorHex = widget.group.colorHex ?? '#0D7E88';
  late Currency _referenceCurrency = widget.group.referenceCurrency;

  bool _isScrolled = false;
  bool _isSaving = false;

  String get _name =>
      _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');

  bool get _hasChanges {
    final initialName = widget.group.name.trim();
    final initialIcon = widget.group.iconName ?? 'flight';
    final initialColor = widget.group.colorHex ?? '#0D7E88';
    final initialCurrency = widget.group.referenceCurrency;

    return (_name.isNotEmpty && _name != initialName) ||
        _iconName != initialIcon ||
        _colorHex != initialColor ||
        _referenceCurrency != initialCurrency;
  }

  bool get _canSave => _name.isNotEmpty && _hasChanges && !_isSaving;

  _GroupIconChoice get _selectedIcon => _choices.firstWhere(
        (choice) => choice.name == _iconName,
        orElse: () => _choices.first,
      );

  Color get _selectedColor => _colors.firstWhere(
        (choice) => choice.hex == _colorHex,
        orElse: () => _colors.first,
      ).color;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _nameFocusNode.addListener(() => setState(() {}));
  }

  void _onScroll() {
    final scrolled =
        _scrollController.hasClients && _scrollController.offset > 32;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    try {
      await GroupOperations(widget.repository).editGroup(
        widget.group,
        name: _name,
        iconName: _iconName,
        colorHex: _colorHex,
        referenceCurrency: _referenceCurrency,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron guardar los cambios.'),
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  void _selectReferenceCurrency() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4DBDF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Moneda de referencia',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF11232D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Se utilizará para convertir balances y pagos sugeridos de este grupo.',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 14,
                      color: Color(0xFF586974),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final curr in Currency.supported) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${curr.name} · ${curr.code}',
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 16,
                          fontWeight: _referenceCurrency == curr
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: const Color(0xFF11232D),
                        ),
                      ),
                      trailing: _referenceCurrency == curr
                          ? const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF0D7E88),
                            )
                          : null,
                      onTap: () {
                        setState(() => _referenceCurrency = curr);
                        Navigator.of(context).pop();
                      },
                    ),
                    const Divider(color: Color(0xFFF0F4F6), height: 1),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showArchiveSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle indicator
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Archive icon badge
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE2F4F2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF0D7E88),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    '¿Archivar ${widget.group.name}?',
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF11232D),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Description
                  const Text(
                    'El grupo dejará de aparecer en Mis grupos, pero sus gastos, personas y cuentas se conservarán.',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                      color: Color(0xFF586974),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Secondary note
                  const Text(
                    'Podés recuperarlo cuando quieras.',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Primary Button: Archivar grupo
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      key: const Key('confirm-archive-group-button'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'El grupo "${widget.group.name}" fue archivado.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D7E88),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Archivar grupo',
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

                  // Secondary Button: Cancelar
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: TextButton(
                      key: const Key('cancel-archive-group-button'),
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF11232D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
  }

  void _confirmDeleteGroup() {
    final expensesCount = widget.group.expenses.length;
    final membersCount = widget.group.members.length;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle indicator
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Delete trash icon badge
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDEEE9),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFC2410C),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    '¿Eliminar ${widget.group.name}?',
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF11232D),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Description
                  Text(
                    'Se eliminarán permanentemente $expensesCount gastos, $membersCount personas y los pagos registrados.',
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                      color: Color(0xFF586974),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Warning alert box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF0EA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFC2410C),
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Esta acción no se puede deshacer.',
                            style: TextStyle(
                              fontFamily: 'Figtree',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8B2500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Primary Button: Eliminar grupo
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      key: const Key('confirm-delete-group-button'),
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        nav.pop();
                        await GroupOperations(widget.repository)
                            .deleteGroup(widget.group);
                        if (mounted) {
                          nav.pop(true);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC2410C),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Eliminar grupo',
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

                  // Secondary Button: Cancelar
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: TextButton(
                      key: const Key('cancel-delete-group-button'),
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF11232D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
  }

  @override
  Widget build(BuildContext context) {
    final activeMembersCount =
        widget.group.members.where((m) => !m.isArchived).length;
    final expensesCount = widget.group.expenses.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // Sticky Header with back arrow & optional inline title
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FBFB),
                    border: Border(
                      bottom: BorderSide(
                        color: _isScrolled
                            ? const Color(0xFFE2E8EA)
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('edit-group-back-button'),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF11232D),
                          size: 26,
                        ),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      if (_isScrolled) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'Editar grupo',
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF11232D),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Scrollable Form
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      // Large Title
                      const Text(
                        'Editar grupo',
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: Color(0xFF11232D),
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 1. INFORMACIÓN DEL GRUPO
                      _buildSectionTitle('Información del grupo'),
                      const SizedBox(height: 12),
                      _buildNameInputCard(),
                      const SizedBox(height: 28),

                      // 2. PERSONALIZACIÓN
                      _buildSectionTitle('Personalización'),
                      const SizedBox(height: 4),
                      const Text(
                        'Elegí cómo reconocer este grupo en tu lista.',
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF586974),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildIconPicker(),
                      const SizedBox(height: 14),
                      _buildColorPicker(),
                      const SizedBox(height: 20),

                      // Vista previa
                      const Text(
                        'Vista previa',
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF586974),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildPreviewCard(activeMembersCount, expensesCount),
                      const SizedBox(height: 28),

                      // 3. MONEDA DEL GRUPO
                      _buildSectionTitle('Moneda del grupo'),
                      const SizedBox(height: 12),
                      _buildCurrencyCard(),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Cambiarla no modifica los gastos ya cargados.',
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF586974),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 4. ACCIONES DEL GRUPO
                      _buildSectionTitle('Acciones del grupo'),
                      const SizedBox(height: 12),
                      _buildActionsCard(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Bottom Fixed Action Button: "Guardar cambios"
                Container(
                  color: const Color(0xFFF7FBFB),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      key: const Key('save-group-changes-button'),
                      onPressed: _canSave ? _saveChanges : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D7E88),
                        disabledBackgroundColor: const Color(0xFFD5DEE2),
                        disabledForegroundColor: const Color(0xFF586974),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar cambios',
                              style: TextStyle(
                                fontFamily: 'Figtree',
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Figtree',
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: Color(0xFF11232D),
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildNameInputCard() {
    final isFocused = _nameFocusNode.hasFocus;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFocused
              ? const Color(0xFF0D7E88)
              : const Color(0xFFE5ECEE),
          width: isFocused ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nombre del grupo',
            style: TextStyle(
              fontFamily: 'Figtree',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D7E88),
            ),
          ),
          const SizedBox(height: 2),
          TextField(
            key: const Key('edit-group-name-field'),
            controller: _nameController,
            focusNode: _nameFocusNode,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              fontFamily: 'Figtree',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF11232D),
              letterSpacing: -0.4,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildIconPicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final choice in _choices)
          InkWell(
            key: Key('edit-icon-${choice.name}'),
            onTap: () => setState(() => _iconName = choice.name),
            customBorder: const CircleBorder(),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _iconName == choice.name ? _selectedColor : Colors.white,
                shape: BoxShape.circle,
                border: _iconName == choice.name
                    ? null
                    : Border.all(color: const Color(0xFFD4DBDF), width: 1.2),
              ),
              child: Icon(
                choice.icon,
                color: _iconName == choice.name
                    ? Colors.white
                    : const Color(0xFF11232D),
                size: 24,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final choice in _colors)
          InkWell(
            key: Key('edit-color-${choice.hex}'),
            onTap: () => setState(() => _colorHex = choice.hex),
            customBorder: const CircleBorder(),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: choice.color,
                shape: BoxShape.circle,
                border: _colorHex == choice.hex
                    ? Border.all(color: Colors.white, width: 3.5)
                    : null,
                boxShadow: _colorHex == choice.hex
                    ? [
                        BoxShadow(
                          color: choice.color,
                          blurRadius: 0,
                          spreadRadius: 2.5,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewCard(int membersCount, int expensesCount) {
    final displayName = _name.isEmpty ? widget.group.name : _name;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5ECEE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _selectedColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedIcon.icon,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF11232D),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '$membersCount personas · $expensesCount gastos',
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
        ],
      ),
    );
  }

  Widget _buildCurrencyCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const Key('edit-group-currency-tile'),
        borderRadius: BorderRadius.circular(20),
        onTap: _selectReferenceCurrency,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5ECEE), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F4F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.paid_outlined,
                  color: Color(0xFF0D7E88),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Moneda de referencia',
                      style: TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF11232D),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Se usa para balances y pagos sugeridos.',
                      style: TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF586974),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_referenceCurrency.code} · ${_referenceCurrency.symbol}',
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
    );
  }

  Widget _buildActionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5ECEE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.8),
        child: Column(
          children: [
            // Row 1: Archivar grupo
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('edit-group-archive-tile'),
                onTap: _showArchiveSheet,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEF2F4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFF586974),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Archivar grupo',
                              style: TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF11232D),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Lo ocultás de tu lista sin perder sus datos',
                              style: TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF586974),
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
            const Divider(color: Color(0xFFF0F4F6), height: 1),
            // Row 2: Eliminar grupo
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('edit-group-delete-tile'),
                onTap: _confirmDeleteGroup,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFDECEB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFBA3D2A),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Eliminar grupo',
                              style: TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFBA3D2A),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Se borrarán gastos, personas y pagos',
                              style: TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF586974),
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
          ],
        ),
      ),
    );
  }
}
