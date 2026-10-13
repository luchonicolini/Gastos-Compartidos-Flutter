class MemberNameDisambiguator {
  const MemberNameDisambiguator._();

  /// Comprueba si [name] ya existe en [existingNames] de forma insensible a mayúsculas y espacios.
  static bool isDuplicate(String name, Iterable<String> existingNames) {
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isEmpty) return false;
    return existingNames.any((n) => n.trim().toLowerCase() == trimmed);
  }

  /// Calcula la siguiente alternativa numerada para un nombre repetido.
  /// Ejemplos:
  /// - "Pedro" con existente ["Pedro"] -> "Pedro (2)"
  /// - "Pedro" con existentes ["Pedro", "Pedro (2)"] -> "Pedro (3)"
  /// - "Pedro (2)" con existentes ["Pedro", "Pedro (2)"] -> "Pedro (3)"
  static String nextNumberedName(String name, Iterable<String> existingNames) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return trimmed;

    // Detecta si el nombre ya termina con (N), por ejemplo "Pedro (2)"
    final regex = RegExp(r'^(.*?)\s*\((?<num>\d+)\)$');
    final match = regex.firstMatch(trimmed);

    String baseName;
    if (match != null) {
      baseName = match.group(1)?.trim() ?? trimmed;
    } else {
      baseName = trimmed;
    }

    final lowerExisting =
        existingNames.map((n) => n.trim().toLowerCase()).toSet();

    var counter = 2;
    while (true) {
      final candidate = '$baseName ($counter)';
      if (!lowerExisting.contains(candidate.toLowerCase())) {
        return candidate;
      }
      counter++;
    }
  }

  /// Devuelve sugerencias de nombres alternativos si [name] está duplicado.
  /// Si no está duplicado, devuelve una lista vacía.
  static List<String> getSuggestions(
    String name,
    Iterable<String> existingNames,
  ) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const [];
    if (!isDuplicate(trimmed, existingNames)) return const [];

    return [nextNumberedName(trimmed, existingNames)];
  }
}
