import '../domain/models/person.dart';
import '../domain/models/split_type.dart';

class ExpenseValidator {
  static String? validate({
    required String description,
    required double amount,
    required Person? payer,
    required List<Person> participants,
    required SplitType splitType,
    Map<String, double>? splitDetails,
  }) {
    if (description.trim().isEmpty) return 'La descripción es obligatoria.';
    if (amount <= 0) return 'El monto debe ser mayor a cero.';
    if (payer == null) return 'Seleccioná quién pagó.';
    if (participants.isEmpty) return 'Seleccioná al menos un participante.';

    final details = splitDetails ?? const <String, double>{};
    switch (splitType) {
      case SplitType.equally:
        return null;
      case SplitType.byAmount:
        if (_hasNegativeDetail(participants, details)) return 'Los montos no pueden ser negativos.';
        final total = _sumParticipants(participants, details);
        if ((total - amount).abs() > 0.01) {
          return 'Los montos asignados deben sumar ${amount.toStringAsFixed(2)}.';
        }
      case SplitType.byPercentage:
        if (_hasNegativeDetail(participants, details)) return 'Los porcentajes no pueden ser negativos.';
        final total = _sumParticipants(participants, details);
        if ((total - 100).abs() > 0.01) {
          return 'Los porcentajes deben sumar 100%.';
        }
      case SplitType.byShares:
        if (_hasNegativeDetail(participants, details)) return 'Las partes no pueden ser negativas.';
        final total = _sumParticipants(participants, details);
        if (total <= 0) return 'La suma de partes debe ser mayor a cero.';
    }

    return null;
  }

  static double _sumParticipants(List<Person> participants, Map<String, double> details) {
    return participants.fold<double>(0, (sum, person) => sum + (details[person.id] ?? 0));
  }

  static bool _hasNegativeDetail(List<Person> participants, Map<String, double> details) {
    return participants.any((person) => (details[person.id] ?? 0) < 0);
  }
}
