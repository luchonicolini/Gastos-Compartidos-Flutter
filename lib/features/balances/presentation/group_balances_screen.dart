import 'package:flutter/material.dart';

import '../../../data/repositories/local_group_repository.dart';
import '../../../domain/models/group.dart';
import '../../groups/presentation/group_detail_screen.dart';

/// Pantalla completa de Cuentas del grupo.
class GroupBalancesScreen extends StatelessWidget {
  const GroupBalancesScreen({
    super.key,
    required this.group,
    required this.repository,
  });

  final Group group;
  final LocalGroupRepository repository;

  @override
  Widget build(BuildContext context) {
    return GroupDetailScreen(
      group: group,
      repository: repository,
      initialTab: 2,
    );
  }
}
