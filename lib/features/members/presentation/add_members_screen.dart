import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/local_group_repository.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/person.dart';
import '../../../shared/group_visuals.dart';
import '../../expenses/presentation/create_expense_screen.dart';
import '../../groups/application/group_operations.dart';

class AddMembersScreen extends StatefulWidget {
  const AddMembersScreen({
    super.key,
    required this.repository,
    required this.group,
  });
  final LocalGroupRepository repository;
  final Group group;

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  final _controller = TextEditingController();
  late Group _group = widget.group;
  bool _saving = false;

  List<Person> get _members =>
      _group.members.where((item) => !item.isArchived).toList();
  bool get _canAdd => _controller.text.trim().isNotEmpty && !_saving;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (!_canAdd) return;
    setState(() => _saving = true);
    try {
      final result = await GroupOperations(
        widget.repository,
      ).addMember(_group, _controller.text);
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _group = result;
        _saving = false;
      });
    } on ArgumentError catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message?.toString() ?? 'Revisá el nombre.'),
        ),
      );
    }
  }

  Future<void> _archive(Person person) async {
    final result = await GroupOperations(
      widget.repository,
    ).setMemberArchived(_group, person.id, true);
    if (mounted) setState(() => _group = result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final members = _members;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 24, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Volver',
                      ),
                      const SizedBox(width: 4),
                      _GroupIdentity(group: _group),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Quiénes viajan?',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sumá a las personas que van a compartir gastos en este grupo.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _Entry(
                          controller: _controller,
                          active: _canAdd,
                          saving: _saving,
                          onChanged: (_) => setState(() {}),
                          onAdd: _add,
                        ),
                        const SizedBox(height: 20),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: members.isEmpty
                              ? const _EmptyMembers(key: ValueKey('empty'))
                              : _MembersList(
                                  key: const ValueKey('list'),
                                  members: members,
                                  onArchive: _archive,
                                ),
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
                          key: const Key('continue-to-expenses'),
                          onPressed: members.isEmpty
                              ? null
                              : () async {
                                  final completed =
                                      await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => CreateExpenseScreen(
                                        repository: widget.repository,
                                        group: _group,
                                      ),
                                    ),
                                  );
                                  if (completed == true && context.mounted) {
                                    Navigator.of(context).pop(true);
                                  }
                                },
                          style: FilledButton.styleFrom(
                            disabledBackgroundColor:
                                colors.surfaceContainerHighest,
                            disabledForegroundColor: colors.onSurfaceVariant,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Continuar a los gastos'),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Después vas a poder editar las personas del grupo.',
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

class _GroupIdentity extends StatelessWidget {
  const _GroupIdentity({required this.group});
  final Group group;
  @override
  Widget build(BuildContext context) {
    final color = groupColorFromHex(group.colorHex);
    final icon = groupIconFromName(group.iconName);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 17,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          group.name,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.controller,
    required this.active,
    required this.saving,
    required this.onChanged,
    required this.onAdd,
  });
  final TextEditingController controller;
  final bool active;
  final bool saving;
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? colors.primary : colors.outlineVariant,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre de la persona',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: active ? colors.primary : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextField(
          key: const Key('member-name-field'),
                  controller: controller,
                  onChanged: onChanged,
                  onSubmitted: (_) => onAdd(),
                  textCapitalization: TextCapitalization.words,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ej. Ana',
                    hintStyle: theme.textTheme.titleLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 6, bottom: 6),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          label: 'Agregar persona',
          button: true,
          child: InkWell(
            key: const Key('add-member'),
            onTap: saving ? null : onAdd,
            customBorder: const CircleBorder(),
            child: Ink(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: saving
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.add_rounded, color: colors.onPrimary, size: 30),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: key,
      width: double.infinity,
      height: 412,
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DottedAvatars(),
              const SizedBox(height: 20),
              Text(
                'Agregate primero y después sumá al resto.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembersList extends StatelessWidget {
  const _MembersList({
    super.key,
    required this.members,
    required this.onArchive,
  });
  final List<Person> members;
  final ValueChanged<Person> onArchive;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Integrantes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${members.length} ${members.length == 1 ? 'persona' : 'personas'}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < members.length; index++) ...[
          _MemberRow(
            member: members[index],
            index: index,
            self: index == 0,
            onArchive: () => onArchive(members[index]),
          ),
          const SizedBox(height: 12),
        ],
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded),
          label: const Text('Sumar otra persona'),
          style: TextButton.styleFrom(foregroundColor: colors.primary),
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.index,
    required this.self,
    required this.onArchive,
  });
  final Person member;
  final int index;
  final bool self;
  final VoidCallback onArchive;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = [
      AppPalette.lightTeal,
      const Color(0xFFC6500A),
      const Color(0xFF6C49C8),
      const Color(0xFF3264C9),
    ];
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette[index % palette.length],
              shape: BoxShape.circle,
            ),
            child: Text(
              member.name.substring(0, 1).toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            member.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (self) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Vos',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            onPressed: onArchive,
            icon: Icon(Icons.close_rounded, color: colors.onSurfaceVariant),
            tooltip: 'Quitar ${member.name}',
          ),
        ],
      ),
    );
  }
}

class _DottedAvatars extends StatelessWidget {
  const _DottedAvatars();
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return SizedBox(
      width: 142,
      height: 58,
      child: Stack(
        children: [
          Positioned(left: 0, child: _Dot(color: c.primary)),
          const Positioned(left: 42, child: _Dot()),
          const Positioned(left: 84, child: _Dot()),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({this.color});
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final stroke = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: stroke, width: 2, style: BorderStyle.solid),
      ),
    );
  }
}
