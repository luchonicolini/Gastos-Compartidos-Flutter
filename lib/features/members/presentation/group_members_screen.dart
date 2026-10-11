import 'package:flutter/material.dart';

import '../../../data/repositories/local_group_repository.dart';
import '../../../domain/models/group.dart';
import '../../groups/presentation/group_detail_screen.dart';

/// Pantalla completa de Personas del grupo.
class GroupMembersScreen extends StatelessWidget {
  const GroupMembersScreen({
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
      initialTab: 1,
    );
  }
}
