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

    await widget.repository.save(
      Group(
        name: result.name,
      ),
    );
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
        content: Text('¿Querés eliminar “${group.name}”? Esta acción no se puede deshacer.'),
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
        builder: (_) => GroupDetailScreen(
          group: group,
          repository: widget.repository,
        ),
      ),
    );
    await _loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis grupos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGroups,
              child: _groups.isEmpty
                  ? _EmptyGroups(onCreate: _createGroup)
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        return _GroupCard(
                          group: group,
                          onTap: () => _openGroup(group),
                          onEdit: () => _editGroup(group),
                          onDelete: () => _deleteGroup(group),
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
  const _EmptyGroups({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
        Icon(Icons.groups_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 20),
        Text(
          'Todavía no tenés grupos',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Creá un grupo para empezar a compartir gastos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
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
    final activeMembers = group.members.where((member) => !member.isArchived).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(Icons.group, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '$activeMembers ${activeMembers == 1 ? 'miembro' : 'miembros'}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
