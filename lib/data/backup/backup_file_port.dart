/// Acceso a archivos para exportar e importar respaldos.
///
/// Se define como interfaz para poder inyectar una implementación falsa en los
/// tests y no depender de los plugins del sistema.
abstract class BackupFilePort {
  /// Comparte o guarda el respaldo. Devuelve `false` si el usuario canceló.
  Future<bool> saveBackup({
    required String contents,
    required String fileName,
  });

  /// Devuelve el contenido del respaldo elegido o `null` si se canceló.
  Future<String?> pickBackup();
}
