import 'package:flutter/material.dart';

import '../../../domain/models/group.dart';
import '../../../data/repositories/local_group_repository.dart';
import 'group_detail_screen.dart';
import 'group_form_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final LocalGroupRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Group> _groups = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final groups = await widget.repository.getAll();
    if (!mounted) return;
    setState(() {
      _groups = groups;
      _isLoading = false;
    });
  }

  Future<void> _createGroup() async {
    final result = await showModalBottomSheet<GroupFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const GroupFormSheet(),
    );
    if (result == null) return;

    await widget.repository.save(Group(name: result.name));
    await _loadGroups();
  }

  Future<void> _editGroup(Group group) async {
    final result = await showModalBottomSheet<GroupFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => GroupFormSheet(initialName: group.name),
    );
    if (result == null) return;

    await widget.repository.save(group.copyWith(name: result.name));
    await _loadGroups();
  }

  Future<void> _deleteGroup(Group group) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: Text(
          '¿Querés eliminar “${group.name}”? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    await widget.repository.delete(group.id);
    await _loadGroups();
  }

  Future<void> _openGroup(Group group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GroupDetailScreen(group: group, repository: widget.repository),
      ),
    );
    await _loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis grupos')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGroups,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth >= 720
                      ? 32.0
                      : 16.0;
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: _groups.isEmpty
                          ? _EmptyGroups(
                              onCreate: _createGroup,
                              horizontalPadding: horizontalPadding,
                            )
                          : _GroupCollection(
                              groups: _groups,
                              horizontalPadding: horizontalPadding,
                              onOpen: _openGroup,
                              onEdit: _editGroup,
                              onDelete: _deleteGroup,
                            ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createGroup,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo grupo'),
      ),
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups({required this.onCreate, required this.horizontalPadding});

  final VoidCallback onCreate;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.14),
        Icon(
          Icons.groups_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          'Todavía no tenés grupos',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Creá un grupo para empezar a compartir gastos.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Crear mi primer grupo'),
        ),
      ],
    );
  }
}

class _GroupCollection extends StatelessWidget {
  const _GroupCollection({
    required this.groups,
    required this.horizontalPadding,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Group> groups;
  final double horizontalPadding;
  final ValueChanged<Group> onOpen;
  final ValueChanged<Group> onEdit;
  final ValueChanged<Group> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        if (isWide) {
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(horizontalPadding),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 440,
              mainAxisExtent: 104,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: groups.length,
            itemBuilder: (context, index) => _buildCard(groups[index]),
          );
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(horizontalPadding),
          itemCount: groups.length,
          itemBuilder: (context, index) => _buildCard(groups[index]),
        );
      },
    );
  }

  Widget _buildCard(Group group) {
    return _GroupCard(
      group: group,
      onTap: () => onOpen(group),
      onEdit: () => onEdit(group),
      onDelete: () => onDelete(group),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Group group;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final activeMembers = group.members
        .where((member) => !member.isArchived)
        .length;
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Semantics(
          button: true,
          label: '${group.name}, $activeMembers miembros',
          hint: 'Abrir grupo',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: Icon(
                    Icons.group_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$activeMembers ${activeMembers == 1 ? 'miembro' : 'miembros'}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Acciones para ${group.name}',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
