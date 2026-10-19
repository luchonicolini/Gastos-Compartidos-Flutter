import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'backup_file_port.dart';

/// Implementación real del puerto de archivos usando el share sheet del
/// sistema para exportar y el selector de archivos para importar.
///
/// No usa `dart:io` para que el build web siga funcionando.
class PluginBackupFilePort implements BackupFilePort {
  const PluginBackupFilePort();

  @override
  Future<bool> saveBackup({
    required String contents,
    required String fileName,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(contents));
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, mimeType: 'application/json', name: fileName),
        ],
        fileNameOverrides: [fileName],
        subject: 'Respaldo de Gastos Compartidos',
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }

  @override
  Future<String?> pickBackup() async {
    // Se acepta cualquier archivo y se valida el contenido, porque algunos
    // gestores de archivos de Android no reportan los .json como JSON.
    final file = await FilePicker.pickFile(
      dialogTitle: 'Elegí el archivo de respaldo',
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return utf8.decode(bytes, allowMalformed: true);
  }
}
