import 'package:flutter/material.dart';

import '../../../data/repositories/local_group_repository.dart';
import '../../../domain/models/expense.dart';
import '../../../domain/models/group.dart';
import '../../../shared/group_bottom_nav.dart';
import '../../../shared/group_visuals.dart';
import '../../balances/presentation/group_balances_view.dart';
import '../../expenses/presentation/all_expenses_screen.dart';
import '../../expenses/presentation/create_expense_screen.dart';
import '../../members/presentation/group_members_view.dart';
import '../application/group_operations.dart';
import 'edit_group_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.repository,
    this.initialTab = 0,
  });

  final Group group;
  final LocalGroupRepository repository;
  final int initialTab;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Group _group = widget.group;
  late int _selectedTab = widget.initialTab;

  @override
  void initState() {
    super.initState();
    _refreshGroup();
  }

  Future<void> _refreshGroup() async {
    final updated = await widget.repository.getById(_group.id);
    if (updated != null && mounted) {
      setState(() => _group = updated);
    }
  }

  Future<void> _openAddExpense([Expense? expenseToEdit]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateExpenseScreen(
          repository: widget.repository,
          group: _group,
          initialExpense: expenseToEdit,
        ),
      ),
    );
    if (result == true && mounted) {
      await _refreshGroup();
    }
  }

  Future<void> _openEditGroup() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditGroupScreen(
          group: _group,
          repository: widget.repository,
        ),
      ),
    );
    if (result == true && mounted) {
      final updated = await widget.repository.getById(_group.id);
      if (!mounted) return;
      if (updated == null) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _group = updated);
      }
    }
  }

  Future<void> _openManageMembers() async {
    setState(() => _selectedTab = 1);
  }

  Future<void> _openAddPerson() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AddPersonDialog(
        existingNames:
            _group.members.map((m) => m.name.toLowerCase()).toSet(),
      ),
    );
    if (name != null && name.isNotEmpty && mounted) {
      try {
        final updated = await GroupOperations(widget.repository)
            .addMember(_group, name);
        setState(() => _group = updated);
      } on ArgumentError catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message?.toString() ?? 'Error al agregar persona.'),
          ),
        );
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: Text(
          '¿Querés eliminar el grupo "${_group.name}"? Esta acción no se puede deshacer.',
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
      await GroupOperations(widget.repository).deleteGroup(_group);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupColor = groupColorFromHex(_group.colorHex);
    final groupIcon = groupIconFromName(_group.iconName);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // Top Navigation Bar
                _buildTopBar(context, groupColor, groupIcon),

                // Main Content with Floating Action Button
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _buildBody(context),
                      ),
                      if (_selectedTab == 0 && !isKeyboardOpen)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _buildExtendedFab(context),
                        ),
                    ],
                  ),
                ),

                // Fixed Action Button (e.g. for Personas tab)
                if (_selectedTab == 1) _buildActionButton(context),

                // Bottom Tab Bar: Gastos, Personas, Cuentas
                GroupDetailBottomNav(
                  selectedIndex: _selectedTab,
                  onChanged: (index) {
                    setState(() => _selectedTab = index);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Color groupColor, IconData groupIcon) {
    final theme = Theme.of(context);
    final isPersonas = _selectedTab == 1;
    final isCuentas = _selectedTab == 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Volver',
          ),
          const SizedBox(width: 4),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: groupColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              groupIcon,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: (isPersonas || isCuentas)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _group.name,
                        style: const TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF586974),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isPersonas ? 'Personas' : 'Cuentas',
                        style: const TextStyle(
                          fontFamily: 'Figtree',
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xFF11232D),
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : Text(
                    _group.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          if (!isPersonas && !isCuentas)
            PopupMenuButton<String>(
              key: const Key('group-detail-menu-button'),
              icon: const Icon(Icons.more_vert_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                if (value == 'edit') _openEditGroup();
                if (value == 'members') _openManageMembers();
                if (value == 'delete') _deleteGroup();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  key: Key('group-detail-menu-edit'),
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 12),
                      Expanded(child: Text('Editar grupo')),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'members',
                  child: Row(
                    children: [
                      Icon(Icons.group_outlined, size: 20),
                      SizedBox(width: 12),
                      Expanded(child: Text('Integrantes')),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Eliminar grupo',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_selectedTab == 1) {
      return GroupMembersView(
        group: _group,
        repository: widget.repository,
        onGroupChanged: (updated) => setState(() => _group = updated),
      );
    }

    if (_selectedTab == 2) {
      return GroupBalancesView(
        group: _group,
        repository: widget.repository,
        onGroupChanged: (updated) => setState(() => _group = updated),
        onNavigateToExpenses: () => setState(() => _selectedTab = 0),
      );
    }

    return GroupExpensesView(
      group: _group,
      repository: widget.repository,
      onGroupChanged: (updated) => setState(() => _group = updated),
      onAddExpense: () => _openAddExpense(),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_selectedTab == 1) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            key: const Key('add-person-button'),
            onPressed: _openAddPerson,
            icon: const Icon(Icons.add_rounded, size: 22),
            label: const Text(
              'Agregar persona',
              style: TextStyle(
                fontFamily: 'Figtree',
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildExtendedFab(BuildContext context) {
    return FloatingActionButton.extended(
      key: const Key('load-expense-button'),
      onPressed: () => _openAddExpense(),
      backgroundColor: const Color(0xFF0D7E88),
      foregroundColor: Colors.white,
      elevation: 4,
      highlightElevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      icon: const Icon(
        Icons.add_rounded,
        size: 22,
        color: Colors.white,
      ),
      label: const Text(
        'Cargar gasto',
        style: TextStyle(
          fontFamily: 'Figtree',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

