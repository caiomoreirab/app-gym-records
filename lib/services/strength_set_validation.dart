import '../models/machine.dart';

/// Single source of truth for the current strength-set input.
abstract final class StrengthSetValidation {
  static bool get isCardio => false;

  /// Bodyweight and elastic bands have no meaningful external kilogram load.
  static bool allowsNoExternalWeight(Machine machine) =>
      machine.equipment == EquipmentType.bodyweight ||
      machine.equipment == EquipmentType.band;

  /// null means the form is valid. Existing v1 records are migrated unchanged
  /// and are not retroactively rejected by this new-entry policy.
  static String? error({
    required Machine machine,
    required double weight,
    required int? repetitions,
    required int? durationSeconds,
  }) {
    if (!weight.isFinite || weight < 0 || weight > 10000) {
      return 'Informe uma carga válida.';
    }
    if (repetitions != null && (repetitions < 1 || repetitions > 1000)) {
      return 'As repetições devem estar entre 1 e 1000.';
    }
    if (durationSeconds != null &&
        (durationSeconds < 0 || durationSeconds > 359999)) {
      return 'Informe uma duração válida.';
    }
    if (!allowsNoExternalWeight(machine) && weight <= 0) {
      return 'Informe uma carga maior que zero para este equipamento.';
    }
    if (machine.supportsRepetitions &&
        (repetitions == null || repetitions < 1) &&
        (durationSeconds == null || durationSeconds <= 0)) {
      return 'Informe pelo menos uma repetição.';
    }
    if (allowsNoExternalWeight(machine) && weight <= 0 &&
        (repetitions == null || repetitions < 1) &&
        (durationSeconds == null || durationSeconds <= 0)) {
      return 'Informe repetições ou duração do exercício.';
    }
    return null;
  }
}
