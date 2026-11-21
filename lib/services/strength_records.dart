import '../models/workout_record.dart';

/// Record rules used throughout the app. Warm-up sets never compete for PR.
abstract final class StrengthRecords {
  static Iterable<WorkoutRecord> workingSets(
      Iterable<WorkoutRecord> records) =>
      records.where((r) => !r.isWarmup);

  static double maxWeight(Iterable<WorkoutRecord> records) {
    var best = 0.0;
    for (final r in workingSets(records)) {
      if (r.weight > best) best = r.weight;
    }
    return best;
  }

  static double maxWeightForRepRange(
      Iterable<WorkoutRecord> records, {int min = 8, int max = 12}) {
    if (min <= 0 || max < min) throw ArgumentError('Faixa inválida.');
    var best = 0.0;
    for (final r in workingSets(records)) {
      final reps = r.repetitions;
      if (reps != null && reps >= min && reps <= max && r.weight > best) {
        best = r.weight;
      }
    }
    return best;
  }

  /// Epley: 1RM = weight × (1 + reps/30).
  /// Only 1–12 repetitions are evaluated; higher reps are too imprecise.
  static double? estimatedOneRepMax(WorkoutRecord record) {
    final reps = record.repetitions;
    if (record.isWarmup || record.weight <= 0 || reps == null ||
        reps < 1 || reps > 12) return null;
    if (reps == 1) return record.weight;
    return record.weight * (1 + reps / 30.0);
  }

  static double? maxEstimatedOneRepMax(
      Iterable<WorkoutRecord> records) {
    double? best;
    for (final r in workingSets(records)) {
      final estimate = estimatedOneRepMax(r);
      if (estimate != null && (best == null || estimate > best)) {
        best = estimate;
      }
    }
    return best;
  }
}
