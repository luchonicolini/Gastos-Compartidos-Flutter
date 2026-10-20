import '../../domain/models/group.dart';
import '../preferences/self_member_store.dart';
import '../repositories/local_group_repository.dart';
import 'backup_codec.dart';
import 'backup_file_port.dart';

/// Resultado de una exportación exitosa.
class BackupExportResult {
  const BackupExportResult({
    required this.groupCount,
    required this.expenseCount,
    required this.fileName,
  });

  final int groupCount;
  final int expenseCount;
  final String fileName;
}

/// Resultado de una importación exitosa.
class BackupImportResult {
  const BackupImportResult({
    required this.groupCount,
    required this.expenseCount,
  });

  final int groupCount;
  final int expenseCount;
}

/// Coordina exportar e importar respaldos: lee y escribe los grupos a través
/// del repositorio y delega el intercambio de archivos en [BackupFilePort].
///
/// Ambas operaciones devuelven `null` cuando el usuario cancela.
class DataBackupService {
  DataBackupService({
    required this.repository,
    required this.filePort,
    this.codec = const BackupCodec(),
    this.selfMemberStore,
  });

  final LocalGroupRepository repository;
  final BackupFilePort filePort;
  final BackupCodec codec;
  final SelfMemberStore? selfMemberStore;

  SelfMemberStore get _selfStore => selfMemberStore ?? SelfMemberStore();

  static String backupFileName(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'gastos-compartidos-${date.year}-$month-$day.json';
  }

  Future<BackupExportResult?> exportBackup({DateTime? now}) async {
    final groups = await repository.getAll();
    final exportedAt = now ?? DateTime.now();
    final fileName = backupFileName(exportedAt);

    final selfMemberIds = <String, String>{};
    for (final group in groups) {
      final selfId = await _selfStore.getActiveSelfMemberId(group);
      if (selfId != null) selfMemberIds[group.id] = selfId;
    }

    final contents = codec.encode(
      groups,
      exportedAt: exportedAt,
      selfMemberIds: selfMemberIds,
    );

    final saved = await filePort.saveBackup(
      contents: contents,
      fileName: fileName,
    );
    if (!saved) return null;

    return BackupExportResult(
      groupCount: groups.length,
      expenseCount: _expenseCount(groups),
      fileName: fileName,
    );
  }

  Future<BackupImportResult?> importBackup() async {
    final raw = await filePort.pickBackup();
    if (raw == null) return null;

    final payload = codec.decode(raw);
    await repository.replaceAll(payload.groups);

    // Los respaldos v1 no guardaban el miembro "Vos": en ese caso se conserva
    // la selección que ya exista en el dispositivo.
    if (payload.version >= 2) {
      for (final group in payload.groups) {
        final selfId = payload.selfMemberIds[group.id];
        final isValid = selfId != null &&
            group.members.any((m) => m.id == selfId && !m.isArchived);
        if (isValid) {
          await _selfStore.setSelfMemberId(group.id, selfId);
        } else {
          await _selfStore.clearSelfMemberId(group.id);
        }
      }
    }

    return BackupImportResult(
      groupCount: payload.groups.length,
      expenseCount: _expenseCount(payload.groups),
    );
  }

  int _expenseCount(List<Group> groups) =>
      groups.fold(0, (total, group) => total + group.expenses.length);
}
