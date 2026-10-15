import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../data/repositories/local_group_repository.dart';
import '../../../domain/models/currency.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/member_balance.dart';
import '../../../logic/balance_calculator.dart';
import '../../../shared/group_visuals.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../application/group_operations.dart';
import 'create_group_screen.dart';
import 'edit_group_screen.dart';
import 'group_detail_screen.dart';
import '../../onboarding/data/onboarding_status_store.dart';
import '../../settings/data/app_settings_store.dart';
import '../../settings/presentation/settings_screen.dart';

/// First destination after onboarding. It deliberately distinguishes a new
/// traveller's guided start from the future list of groups with content.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    this.onboardingStore,
    this.settingsStore,
    this.onOpenSettings,
  });

  final LocalGroupRepository repository;
  final OnboardingStatusStore? onboardingStore;
  final AppSettingsStore? settingsStore;
  final VoidCallback? onOpenSettings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Group>> _groups = widget.repository.getAll();

  Future<void> _openCreateGroup({required bool hasExistingGroups}) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(
          repository: widget.repository,
          hasExistingGroups: hasExistingGroups,
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() {
        _groups = widget.repository.getAll();
      });
    }
  }

  Future<void> _openSettings() async {
    if (widget.onOpenSettings != null) {
      widget.onOpenSettings!();
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          repository: widget.repository,
          onboardingStore: widget.onboardingStore,
          settingsStore: widget.settingsStore,
          onDataCleared: () {
            setState(() {
              _groups = widget.repository.getAll();
            });
          },
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _groups = widget.repository.getAll();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Group>>(
      future: _groups,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: SafeArea(
              child: Center(
                child: Text('No se pudieron cargar los datos locales.'),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final groups = snapshot.data!;
        if (groups.isNotEmpty) {
          return _GroupsListView(
            groups: groups,
            repository: widget.repository,
            onCreateGroup: () => _openCreateGroup(hasExistingGroups: true),
            onOpenSettings: _openSettings,
            onRefresh: () {
              setState(() {
                _groups = widget.repository.getAll();
              });
            },
          );
        }
        return _EmptyGroupsHome(
          onCreateGroup: () => _openCreateGroup(hasExistingGroups: false),
        );
      },
    );
  }
}

class _EmptyGroupsHome extends StatelessWidget {
  const _EmptyGroupsHome({required this.onCreateGroup});

  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mis grupos',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tus grupos y gastos compartidos.',
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF586974),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _JourneyStarterIllustration(),
                        const SizedBox(height: 20),
                        Text(
                          'Creá tu primer grupo',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.35,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Creá un grupo, sumá a las personas y registrá los gastos a medida que ocurren.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _GettingStartedSteps(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onCreateGroup,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Crear mi primer grupo'),
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
}

class _JourneyStarterIllustration extends StatelessWidget {
  const _JourneyStarterIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1.08,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: Container(
            width: 266,
            height: 184,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.groups_rounded,
                        color: colors.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: _FadedLine(widthFactor: .92)),
                  ],
                ),
                const SizedBox(height: 16),
                const _AvatarsRow(),
                const SizedBox(height: 16),
                const _BulletLine(widthFactor: .82),
                const SizedBox(height: 10),
                const _BulletLine(widthFactor: .60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarsRow extends StatelessWidget {
  const _AvatarsRow();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        _LetterAvatar(letter: 'A', color: colors.primary),
        const SizedBox(width: 3),
        const _LetterAvatar(letter: 'M', color: Color(0xFFC1430C)),
        const SizedBox(width: 3),
        const _LetterAvatar(letter: 'J', color: Color(0xFF3D4E97)),
        const SizedBox(width: 3),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.primary, width: 1.5),
          ),
          child: Icon(Icons.add_rounded, size: 20, color: colors.primary),
        ),
      ],
    );
  }
}

class _LetterAvatar extends StatelessWidget {
  const _LetterAvatar({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FadedLine extends StatelessWidget {
  const _FadedLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 11,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _FadedLine(widthFactor: widthFactor)),
      ],
    );
  }
}

class _GettingStartedSteps extends StatelessWidget {
  const _GettingStartedSteps();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Pasos para empezar: crear grupo, sumar personas y cargar gastos.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StepItem(
                icon: Icons.create_new_folder_outlined,
                number: 'Paso 1',
                label: 'Crear grupo',
              ),
            ),
            _StepArrow(),
            Expanded(
              child: _StepItem(
                icon: Icons.group_add_outlined,
                number: 'Paso 2',
                label: 'Sumar\npersonas',
              ),
            ),
            _StepArrow(),
            Expanded(
              child: _StepItem(
                icon: Icons.receipt_long_outlined,
                number: 'Paso 3',
                label: 'Cargar\ngastos',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepArrow extends StatelessWidget {
  const _StepArrow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Icon(
        Icons.chevron_right_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.icon,
    required this.number,
    required this.label,
  });

  final IconData icon;
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colors.primary, size: 23),
        ),
        const SizedBox(height: 8),
        Text(
          number,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _GroupsListView extends StatelessWidget {
  const _GroupsListView({
    required this.groups,
    required this.repository,
    required this.onCreateGroup,
    this.onOpenSettings,
    required this.onRefresh,
  });

  final List<Group> groups;
  final LocalGroupRepository? repository;
  final VoidCallback onCreateGroup;
  final VoidCallback? onOpenSettings;
  final VoidCallback onRefresh;

  MemberBalance? _getUserBalance(Group group) {
    if (group.members.isEmpty) return null;
    final balances = BalanceCalculator.calculateMemberBalances(group);
    if (balances.isEmpty) return null;

    // 1. Prioritize a member explicitly named "yo" or "vos"
    for (final b in balances) {
      final lower = b.name.trim().toLowerCase();
      if (lower == 'yo' || lower == 'vos') {
        return b;
      }
    }

    // 2. Otherwise match the first member of the group (creator)
    final creatorId = group.members.first.id;
    for (final b in balances) {
      if (b.id == creatorId) {
        return b;
      }
    }

    return balances.first;
  }

  void _showFinalizedGroupsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4DBDF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: Color(0xFF0D7E88),
              ),
              const SizedBox(height: 12),
              const Text(
                'Grupos finalizados',
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF11232D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Por el momento no tenés grupos archivados. Cuando salden todas las cuentas y no usen más un grupo, vas a poder archivarlo acá.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF586974),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7E88),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      fontWeight: FontWeight.w700,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // Top Header: Title, Subtitle, Circular (+) button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Mis grupos',
                              style: TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                color: Color(0xFF11232D),
                                height: 1.15,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Tus grupos y gastos compartidos.',
                              style: TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF586974),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: const Color(0xFF0D7E88),
                        shape: const CircleBorder(),
                        elevation: 0,
                        child: Tooltip(
                          message: 'Configuración',
                          child: InkWell(
                            key: const Key('settings-header-button'),
                            customBorder: const CircleBorder(),
                            onTap: onOpenSettings ?? () {},
                            child: const SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.settings_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Cards List + Divider + "Ver grupos finalizados"
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    children: [
                      for (final group in groups) ...[
                        _buildGroupCard(context, group),
                        const SizedBox(height: 14),
                      ],
                      const SizedBox(height: 10),
                      const Divider(
                        color: Color(0xFFE2EBEB),
                        thickness: 1,
                        height: 1,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          key: const Key('view-finalized-groups-button'),
                          onPressed: () => _showFinalizedGroupsSheet(context),
                          icon: const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF0D7E88),
                            size: 20,
                          ),
                          label: const Text(
                            'Ver grupos finalizados',
                            style: TextStyle(
                              fontFamily: 'Figtree',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF0D7E88),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // Bottom Fixed Button: "+ Crear un nuevo grupo"
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      key: const Key('create-group-bottom-button'),
                      onPressed: onCreateGroup,
                      icon: const Icon(Icons.add_rounded, size: 22),
                      label: const Text(
                        'Crear un nuevo grupo',
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D7E88),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
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

  void _confirmDeleteGroup(BuildContext context, Group group) {
    final expensesCount = group.expenses.length;
    final membersCount = group.members.length;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
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
                  Text(
                    '¿Eliminar ${group.name}?',
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF11232D),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Se eliminarán permanentemente $expensesCount ${expensesCount == 1 ? "gasto" : "gastos"}, $membersCount ${membersCount == 1 ? "persona" : "personas"} y los balances registrados.',
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                      color: Color(0xFF586974),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      key: const Key('confirm-delete-group-button'),
                      onPressed: () async {
                        Navigator.of(bottomSheetContext).pop();
                        if (repository != null) {
                          await GroupOperations(repository!).deleteGroup(group);
                          onRefresh();
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
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton(
                      onPressed: () => Navigator.of(bottomSheetContext).pop(),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF586974),
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

  Widget _buildGroupCard(BuildContext context, Group group) {
    final color = groupColorFromHex(group.colorHex);
    final icon = groupIconFromName(group.iconName);
    final activeMembersCount = group.members.where((m) => !m.isArchived).length;
    final expensesCount = group.expenses.length;
    final userBalance = _getUserBalance(group);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Slidable(
        key: ValueKey('slidable-group-${group.id}'),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.48,
          children: [
            SlidableAction(
              key: Key('slidable-edit-group-${group.id}'),
              onPressed: (_) async {
                if (repository == null) return;
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => EditGroupScreen(
                      group: group,
                      repository: repository!,
                    ),
                  ),
                );
                if (changed == true) onRefresh();
              },
              backgroundColor: const Color(0xFF0D7E88),
              foregroundColor: Colors.white,
              icon: Icons.edit_outlined,
              label: 'Editar',
            ),
            SlidableAction(
              key: Key('slidable-delete-group-${group.id}'),
              onPressed: (_) => _confirmDeleteGroup(context, group),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('group-card-${group.id}'),
              borderRadius: BorderRadius.circular(22),
              onTap: repository == null
                  ? null
                  : () async {
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => GroupDetailScreen(
                            group: group,
                            repository: repository!,
                          ),
                        ),
                      );
                      if (changed == true) onRefresh();
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Row(
                  children: [
                    // Circular Group Icon Badge
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Group name & count info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(
                              fontFamily: 'Figtree',
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: -0.3,
                              color: Color(0xFF11232D),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$activeMembersCount ${activeMembersCount == 1 ? "persona" : "personas"} · $expensesCount ${expensesCount == 1 ? "gasto" : "gastos"}',
                            style: const TextStyle(
                              fontFamily: 'Figtree',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Color(0xFF586974),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Status badge (Te deben / Debés / Todo al día)
                    _buildBalanceStatus(userBalance, group.referenceCurrency),

                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF8E9CA3),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceStatus(MemberBalance? userBalance, Currency currency) {
    final balance = userBalance?.balance ?? 0.0;
    if (balance > 0.01) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Te deben',
            style: TextStyle(
              fontFamily: 'Figtree',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF0D7E88),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${currency.symbol} ${CurrencyFormatter.formatAmount(balance)}',
            style: const TextStyle(
              fontFamily: 'Figtree',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.4,
              color: Color(0xFF0D7E88),
            ),
          ),
        ],
      );
    } else if (balance < -0.01) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Debés',
            style: TextStyle(
              fontFamily: 'Figtree',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFFC6500A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${currency.symbol} ${CurrencyFormatter.formatAmount(balance.abs())}',
            style: const TextStyle(
              fontFamily: 'Figtree',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.4,
              color: Color(0xFFC6500A),
            ),
          ),
        ],
      );
    } else {
      return const Text(
        'Todo al día',
        style: TextStyle(
          fontFamily: 'Figtree',
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: Color(0xFF586974),
        ),
      );
    }
  }
}
