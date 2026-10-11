import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/local_group_repository.dart';
import '../../members/presentation/add_members_screen.dart';
import '../application/group_operations.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({
    super.key,
    required this.repository,
    this.hasExistingGroups = false,
  });

  final LocalGroupRepository repository;
  final bool hasExistingGroups;

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  static const _choices = <_GroupIconChoice>[
    _GroupIconChoice('flight', Icons.flight_takeoff_rounded),
    _GroupIconChoice('briefcase', Icons.business_center_outlined),
    _GroupIconChoice('beach', Icons.beach_access_outlined),
    _GroupIconChoice('mountain', Icons.terrain_outlined),
    _GroupIconChoice('home', Icons.home_outlined),
    _GroupIconChoice('toast', Icons.wine_bar_outlined),
  ];

  static const _colors = <_GroupColorChoice>[
    _GroupColorChoice('#0D7E88', AppPalette.lightTeal),
    _GroupColorChoice('#C6500A', Color(0xFFC6500A)),
    _GroupColorChoice('#6C49C8', Color(0xFF6C49C8)),
    _GroupColorChoice('#3264C9', Color(0xFF3264C9)),
    _GroupColorChoice('#2F8557', Color(0xFF2F8557)),
    _GroupColorChoice('#C53678', Color(0xFFC53678)),
  ];

  final _nameController = TextEditingController();
  String _iconName = 'flight';
  String _colorHex = '#0D7E88';
  bool _isSaving = false;

  String get _name =>
      _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
  bool get _canContinue => _name.isNotEmpty && !_isSaving;
  _GroupIconChoice get _selectedIcon =>
      _choices.firstWhere((choice) => choice.name == _iconName);
  Color get _selectedColor =>
      _colors.firstWhere((choice) => choice.hex == _colorHex).color;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_canContinue) return;
    setState(() => _isSaving = true);
    try {
      final group = await GroupOperations(
        widget.repository,
      ).createGroup(name: _name, iconName: _iconName, colorHex: _colorHex);
      if (mounted) {
        final completed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                AddMembersScreen(repository: widget.repository, group: group),
          ),
        );
        if (completed == true && mounted) Navigator.of(context).pop(true);
      }
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message?.toString() ?? 'Revisá el nombre.'),
        ),
      );
      setState(() => _isSaving = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo crear el grupo. Intentá de nuevo.'),
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canGoBack = widget.hasExistingGroups;

    return PopScope(
      canPop: canGoBack,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(canGoBack ? 12 : 24, 14, 24, 0),
                    child: Row(
                      children: [
                        if (canGoBack) ...[
                          IconButton(
                            key: const Key('create-group-back-button'),
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            tooltip: 'Volver a Mis grupos',
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          'Crear grupo',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿A dónde viajan?',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Dale un nombre a este grupo. Después vas a poder sumar personas y cargar gastos.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _GroupNameField(
                          controller: _nameController,
                          isActive: _name.isNotEmpty,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'Personalizalo',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Opcional',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Elegí un ícono y un color para reconocerlo más fácil.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _IconPicker(
                          choices: _choices,
                          selected: _iconName,
                          color: _selectedColor,
                          onSelected: (choice) =>
                              setState(() => _iconName = choice.name),
                        ),
                        const SizedBox(height: 10),
                        _ColorPicker(
                          choices: _colors,
                          selected: _colorHex,
                          onSelected: (choice) =>
                              setState(() => _colorHex = choice.hex),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'VISTA PREVIA',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _GroupPreview(
                          groupName: _name.isEmpty ? 'Nombre del grupo' : _name,
                          color: _selectedColor,
                          icon: _selectedIcon.icon,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const Key('continue-create-group'),
                          onPressed: _canContinue ? _createGroup : null,
                          style: FilledButton.styleFrom(
                            disabledBackgroundColor:
                                colors.surfaceContainerHighest,
                            disabledForegroundColor: colors.onSurfaceVariant,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Continuar'),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'En el próximo paso vas a sumar a las personas.',
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
    ),
  );
}
}

class _GroupNameField extends StatelessWidget {
  const _GroupNameField({
    required this.controller,
    required this.isActive,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isActive;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? Border.all(color: colors.primary, width: 1.5) : null,
        boxShadow: isActive
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nombre del grupo',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isActive ? colors.primary : colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: 'Ej. Brasil 2026',
              hintStyle: theme.textTheme.titleLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 6, bottom: 6),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.choices,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final List<_GroupIconChoice> choices;
  final String selected;
  final Color color;
  final ValueChanged<_GroupIconChoice> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final choice in choices)
          Semantics(
            label: 'Ícono ${choice.name}',
            selected: selected == choice.name,
            button: true,
            child: InkWell(
              onTap: () => onSelected(choice),
              customBorder: const CircleBorder(),
              child: Ink(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected == choice.name ? color : colors.surface,
                  shape: BoxShape.circle,
                  border: selected == choice.name
                      ? null
                      : Border.all(color: colors.outlineVariant),
                ),
                child: Icon(
                  choice.icon,
                  color: selected == choice.name
                      ? Colors.white
                      : colors.onSurface,
                  size: 23,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.choices,
    required this.selected,
    required this.onSelected,
  });

  final List<_GroupColorChoice> choices;
  final String selected;
  final ValueChanged<_GroupColorChoice> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final choice in choices)
          Semantics(
            label: 'Color ${choice.hex}',
            selected: selected == choice.hex,
            button: true,
            child: InkWell(
              onTap: () => onSelected(choice),
              customBorder: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: choice.color,
                  shape: BoxShape.circle,
                  border: selected == choice.hex
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: selected == choice.hex
                      ? [
                          BoxShadow(
                            color: choice.color,
                            blurRadius: 0,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GroupPreview extends StatelessWidget {
  const _GroupPreview({
    required this.groupName,
    required this.color,
    required this.icon,
  });

  final String groupName;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: groupName == 'Nombre del grupo'
                        ? colors.onSurfaceVariant
                        : colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Todavía no hay gastos',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const _FutureMembers(),
        ],
      ),
    );
  }
}

class _FutureMembers extends StatelessWidget {
  const _FutureMembers();

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox(
      width: 70,
      height: 30,
      child: Stack(
        children: [
          for (var index = 0; index < 3; index++)
            Positioned(
              left: index * 19.0,
              child: _DashedCircle(color: outline),
            ),
        ],
      ),
    );
  }
}

class _DashedCircle extends StatelessWidget {
  const _DashedCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(30, 30),
      painter: _DashedCirclePainter(color),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const dash = 0.21;
    for (var start = 0.0; start < 6.283; start += dash * 2) {
      canvas.drawArc(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        start,
        dash,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

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
