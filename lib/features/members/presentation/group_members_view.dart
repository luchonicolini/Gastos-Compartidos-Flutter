import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/local_group_repository.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/person.dart';
import '../domain/member_name_disambiguator.dart';
import '../../groups/application/group_operations.dart';

/// Vista de "Personas" del grupo.
/// Implementada con máxima fidelidad visual respecto a las pantallas de referencia.
class GroupMembersView extends StatefulWidget {
  const GroupMembersView({
    super.key,
    required this.group,
    required this.repository,
    required this.onGroupChanged,
  });

  final Group group;
  final LocalGroupRepository repository;
  final ValueChanged<Group> onGroupChanged;

  @override
  State<GroupMembersView> createState() => _GroupMembersViewState();
}

class _GroupMembersViewState extends State<GroupMembersView> {
  String? _openMenuMemberId;

  List<Person> get _activeMembers =>
      widget.group.members.where((m) => !m.isArchived).toList();

  List<Person> get _archivedMembers =>
      widget.group.members.where((m) => m.isArchived).toList();

  Future<void> _showArchiveConfirmation(Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ArchiveConfirmationDialog(person: person),
    );

    if (confirmed == true && mounted) {
      final updated = await GroupOperations(widget.repository)
          .setMemberArchived(widget.group, person.id, true);
      widget.onGroupChanged(updated);
    }
  }

  Future<void> _reactivateMember(Person person) async {
    final updated = await GroupOperations(widget.repository)
        .setMemberArchived(widget.group, person.id, false);
    widget.onGroupChanged(updated);
  }

  Future<void> _showEditNameDialog(Person person) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => _EditNameDialog(
        initialName: person.name,
        existingNames: widget.group.members
            .where((m) => m.id != person.id)
            .map((m) => m.name.toLowerCase())
            .toSet(),
      ),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      try {
        final updated = await GroupOperations(widget.repository)
            .editMember(widget.group, person.id, newName);
        widget.onGroupChanged(updated);
      } on ArgumentError catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message?.toString() ?? 'Error al editar.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeMembers;
    final archived = _archivedMembers;
    final activeCount = active.length;
    final activeCountText = activeCount == 1
        ? '1 persona activa'
        : '$activeCount personas activas';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título principal
          const Text(
            '¿Quiénes participan?',
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
            'Administrá las personas que comparten\ngastos en este grupo.',
            style: TextStyle(
              fontFamily: 'Figtree',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.35,
              color: Color(0xFF586974),
            ),
          ),
          const SizedBox(height: 12),

          // Contador de personas activas
          Text(
            activeCountText,
            style: const TextStyle(
              fontFamily: 'Figtree',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF586974),
            ),
          ),
          const SizedBox(height: 18),

          // Contenido: Lista o Estado Vacío
          if (active.isEmpty)
            const _EmptyMembersCard()
          else ...[
            for (var i = 0; i < active.length; i++) ...[
              _ActiveMemberCard(
                member: active[i],
                index: i,
                isSelf: i == 0,
                isMenuOpen: _openMenuMemberId == active[i].id,
                onMenuOpened: () =>
                    setState(() => _openMenuMemberId = active[i].id),
                onMenuClosed: () => setState(() => _openMenuMemberId = null),
                onEdit: () => _showEditNameDialog(active[i]),
                onArchive: () => _showArchiveConfirmation(active[i]),
              ),
              const SizedBox(height: 12),
            ],
          ],

          // Sección de personas archivadas (si existen)
          if (archived.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Archivadas',
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
              'No participan de gastos nuevos.',
              style: TextStyle(
                fontFamily: 'Figtree',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF586974),
              ),
            ),
            const SizedBox(height: 14),
            for (final member in archived) ...[
              _ArchivedMemberCard(
                member: member,
                onReactivate: () => _reactivateMember(member),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

/// Tarjeta de integrante activo (Ana, Marco, Julia...)
class _ActiveMemberCard extends StatelessWidget {
  const _ActiveMemberCard({
    required this.member,
    required this.index,
    required this.isSelf,
    required this.isMenuOpen,
    required this.onMenuOpened,
    required this.onMenuClosed,
    required this.onEdit,
    required this.onArchive,
  });

  final Person member;
  final int index;
  final bool isSelf;
  final bool isMenuOpen;
  final VoidCallback onMenuOpened;
  final VoidCallback onMenuClosed;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final avatarColor = AppPalette.memberColor(index);
    final initial =
        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?';

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Slidable(
        key: ValueKey('slidable-member-${member.id}'),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.48,
          children: [
            SlidableAction(
              key: Key('slidable-edit-member-${member.id}'),
              onPressed: (_) => onEdit(),
              backgroundColor: const Color(0xFF0D7E88),
              foregroundColor: Colors.white,
              icon: Icons.edit_outlined,
              label: 'Editar',
            ),
            SlidableAction(
              key: Key('slidable-archive-member-${member.id}'),
              onPressed: (_) => onArchive(),
              backgroundColor: const Color(0xFF586974),
              foregroundColor: Colors.white,
              icon: Icons.inventory_2_outlined,
              label: 'Archivar',
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isMenuOpen ? const Color(0xFF0D7E88) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
          // Avatar circular
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
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
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

          // Menú de 3 puntos
          Theme(
            data: Theme.of(context).copyWith(
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: PopupMenuButton<String>(
              key: Key('member-menu-${member.id}'),
              constraints: const BoxConstraints(
                minWidth: 180,
                maxWidth: 320,
              ),
              icon: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isMenuOpen
                      ? const Color(0xFFDDF1EF)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xFF586974),
                  size: 22,
                ),
              ),
              padding: EdgeInsets.zero,
              elevation: 8,
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              offset: const Offset(0, 48),
              onOpened: onMenuOpened,
              onCanceled: onMenuClosed,
              onSelected: (value) {
                onMenuClosed();
                if (value == 'edit') onEdit();
                if (value == 'archive') onArchive();
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  height: 48,
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: Color(0xFF11232D),
                      ),
                      SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Editar nombre',
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF11232D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'archive',
                  height: 48,
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                        color: Color(0xFF11232D),
                      ),
                      SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Archivar persona',
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF11232D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

/// Tarjeta de integrante archivado (Sofía...)
class _ArchivedMemberCard extends StatelessWidget {
  const _ArchivedMemberCard({
    required this.member,
    required this.onReactivate,
  });

  final Person member;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    final initial =
        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?';

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Slidable(
        key: ValueKey('slidable-archived-${member.id}'),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.32,
          children: [
            SlidableAction(
              key: Key('slidable-reactivate-member-${member.id}'),
              onPressed: (_) => onReactivate(),
              backgroundColor: const Color(0xFF0D7E88),
              foregroundColor: Colors.white,
              icon: Icons.unarchive_outlined,
              label: 'Reactivar',
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE2E7EB),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
        children: [
          // Avatar gris
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFD0D7DE),
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                fontFamily: 'Figtree',
                color: Color(0xFF586974),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Textos
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                member.name,
                style: const TextStyle(
                  fontFamily: 'Figtree',
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: Color(0xFF11232D),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Archivada',
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF586974),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Botón Reactivar
          TextButton(
            key: Key('reactivate-member-${member.id}'),
            onPressed: onReactivate,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Reactivar',
              style: TextStyle(
                fontFamily: 'Figtree',
                color: Color(0xFF0D7E88),
                fontWeight: FontWeight.w800,
                fontSize: 15,
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

/// Estado vacío fiel a la Imagen 2
class _EmptyMembersCard extends StatelessWidget {
  const _EmptyMembersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFFDDF1EF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DashedOverlappingCircles(),
              SizedBox(height: 24),
              Text(
                'Sumá a las personas que van a compartir gastos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.3,
                  height: 1.35,
                  color: Color(0xFF11232D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3 círculos punteados superpuestos como en la Imagen 2
class _DashedOverlappingCircles extends StatelessWidget {
  const _DashedOverlappingCircles();

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    const overlap = 38.0;
    return SizedBox(
      width: size + overlap * 2,
      height: size,
      child: const Stack(
        children: [
          Positioned(
            left: 0,
            child: _DashedCircle(
              size: size,
              color: Color(0xFF0D7E88),
              strokeWidth: 2.2,
            ),
          ),
          Positioned(
            left: overlap,
            child: _DashedCircle(
              size: size,
              color: Color(0xFF586974),
              strokeWidth: 2.2,
            ),
          ),
          Positioned(
            left: overlap * 2,
            child: _DashedCircle(
              size: size,
              color: Color(0xFF586974),
              strokeWidth: 2.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCircle extends StatelessWidget {
  const _DashedCircle({
    required this.size,
    required this.color,
    this.strokeWidth = 2.0,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DashedCirclePainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    const int dashCount = 14;
    const double totalAngle = 2 * math.pi;
    const double dashAngle = totalAngle / (dashCount * 2);

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * 2 * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Diálogo de confirmación para archivar miembro (Imagen 3)
class _ArchiveConfirmationDialog extends StatelessWidget {
  const _ArchiveConfirmationDialog({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono de caja de archivo
            const Icon(
              Icons.inventory_2_outlined,
              size: 38,
              color: Color(0xFF0D7E88),
            ),
            const SizedBox(height: 18),

            // Título
            Text(
              '¿Archivar a ${person.name}?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Figtree',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF11232D),
              ),
            ),
            const SizedBox(height: 12),

            // Descripción
            const Text(
              'No aparecerá al cargar gastos nuevos, pero sus cuentas anteriores se conservarán.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Figtree',
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w400,
                color: Color(0xFF586974),
              ),
            ),
            const SizedBox(height: 26),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  key: const Key('cancel-archive-button'),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      color: Color(0xFF0D7E88),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('confirm-archive-button'),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Archivar',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      color: Color(0xFF0D7E88),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para editar nombre de integrante
class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({
    required this.initialName,
    required this.existingNames,
  });

  final String initialName;
  final Set<String> existingNames;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);
  String? _error;
  String? _suggestedName;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() {
        _error = 'El nombre no puede estar vacío';
        _suggestedName = null;
      });
      return;
    }
    if (widget.existingNames.contains(name.toLowerCase())) {
      final suggestion =
          MemberNameDisambiguator.nextNumberedName(name, widget.existingNames);
      setState(() {
        _error = 'Ya existe un miembro con ese nombre';
        _suggestedName = suggestion;
      });
      return;
    }
    Navigator.of(context).pop(name);
  }

  void _applySuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    setState(() {
      _error = null;
      _suggestedName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.edit_outlined, size: 24, color: Color(0xFF0D7E88)),
                SizedBox(width: 10),
                Text(
                  'Editar nombre',
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF11232D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _error != null
                      ? Colors.red
                      : const Color(0xFF0D7E88),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nombre',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      color: Color(0xFF0D7E88),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextField(
                    key: const Key('edit-name-field'),
                    controller: _controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF11232D),
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(top: 4, bottom: 4),
                    ),
                    onChanged: (_) {
                      if (_error != null) {
                        setState(() {
                          _error = null;
                          _suggestedName = null;
                        });
                      }
                    },
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'Figtree',
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_suggestedName != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sugerencia: "$_suggestedName"',
                        style: const TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                    InkWell(
                      key: const Key('apply-suggested-name-button'),
                      onTap: () => _applySuggestion(_suggestedName!),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Usar',
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      color: Color(0xFF586974),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('save-name-button'),
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7E88),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para agregar persona directamente desde la vista
class AddPersonDialog extends StatefulWidget {
  const AddPersonDialog({
    super.key,
    required this.existingNames,
  });

  final Set<String> existingNames;

  @override
  State<AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends State<AddPersonDialog> {
  final _controller = TextEditingController();
  String? _error;
  String? _suggestedName;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() {
        _error = 'El nombre no puede estar vacío';
        _suggestedName = null;
      });
      return;
    }
    if (widget.existingNames.contains(name.toLowerCase())) {
      final suggestion =
          MemberNameDisambiguator.nextNumberedName(name, widget.existingNames);
      setState(() {
        _error = 'Ya existe un miembro con ese nombre';
        _suggestedName = suggestion;
      });
      return;
    }
    Navigator.of(context).pop(name);
  }

  void _applySuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    setState(() {
      _error = null;
      _suggestedName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.person_add_outlined,
                  size: 24,
                  color: Color(0xFF0D7E88),
                ),
                SizedBox(width: 10),
                Text(
                  'Agregar persona',
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF11232D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Sumá a una persona que comparta gastos en este grupo.',
              style: TextStyle(
                fontFamily: 'Figtree',
                fontSize: 14,
                color: Color(0xFF586974),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _error != null
                      ? Colors.red
                      : const Color(0xFF0D7E88),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nombre de la persona',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      color: Color(0xFF0D7E88),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextField(
                    key: const Key('add-person-name-field'),
                    controller: _controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF11232D),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Ej. Sofía',
                      hintStyle: TextStyle(
                        fontFamily: 'Figtree',
                        color: Color(0xFF586974),
                        fontWeight: FontWeight.w600,
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(top: 4, bottom: 4),
                    ),
                    onChanged: (_) {
                      if (_error != null) {
                        setState(() {
                          _error = null;
                          _suggestedName = null;
                        });
                      }
                    },
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'Figtree',
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_suggestedName != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sugerencia: "$_suggestedName"',
                        style: const TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                    InkWell(
                      key: const Key('apply-suggested-name-add-dialog-button'),
                      onTap: () => _applySuggestion(_suggestedName!),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Usar',
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      color: Color(0xFF586974),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('confirm-add-person-button'),
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7E88),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'Agregar',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
