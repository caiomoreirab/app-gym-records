import '../models/machine.dart';
import '../models/workout_record.dart';
import '../models/workout_session.dart';

/// Immutable, reproducible summary of one completed workout.
/// Exercise counts and volume use saved sets, never placeholder plan items.
class CompletedWorkoutSummary {
  CompletedWorkoutSummary({
    required this.session,
    required Iterable<Machine> machines,
    required this.bodyWeightKg,
  }) {
    final byExercise = <String, List<WorkoutRecord>>{};
    var volume = 0.0;
    var sets = 0;
    var newRecords = 0;
    for (final machine in machines) {
      final current = machine.records
          .where((r) => r.effectiveSessionId == session.id).toList();
      if (current.isEmpty) continue;
      byExercise[machine.name] = current;
      sets += current.length;
      for (final r in current) {
        if (r.weight > 0 && (r.repetitions ?? 0) > 0) {
          volume += r.weight * r.repetitions!;
        }
      }
      // Compare the best non-warmup load in this session to older records.
      final currentWeights = current.where((r) => !r.isWarmup && r.weight > 0)
          .map((r) => r.weight).toList();
      final previousWeights = machine.records
          .where((r) => r.effectiveSessionId != session.id &&
              !r.isWarmup && r.weight > 0 && !r.date.isAfter(session.startedAt))
          .map((r) => r.weight).toList();
      if (currentWeights.isNotEmpty && previousWeights.isNotEmpty &&
          currentWeights.reduce((a, b) => a > b ? a : b) >
          previousWeights.reduce((a, b) => a > b ? a : b)) {
        newRecords++;
      }
    }
    exercises = Map<String, List<WorkoutRecord>>.unmodifiable(
      byExercise.map((key, value) => MapEntry(key,
        List<WorkoutRecord>.unmodifiable(value))));
    totalSets = sets;
    volumeKg = volume;
    weightPersonalRecords = newRecords;
  }

  final WorkoutSession session;
  final double? bodyWeightKg;

  late final Map<String, List<WorkoutRecord>> exercises;
  late final int totalSets;
  late final double volumeKg;
  late final int weightPersonalRecords;

  int get exerciseCount => exercises.length;

  Duration get duration {
    final end = session.completedAt;
    if (end == null || end.isBefore(session.startedAt)) return Duration.zero;
    return end.difference(session.startedAt);
  }

  /// Gross kcal estimate, including rest. Adult 2024 Compendium, 02054:
  /// resistance exercises (8–15 reps at varied resistance), 3.5 MET.
  /// 3.5 MET × 3.5 ml/kg/min × body kg / 200 × session minutes.
  /// An estimated energy number is *not* displayed for abandoned/invalid
  /// sessions or when no body weight has been explicitly supplied.
  static const double generalResistanceMet = 3.5;
  double? get estimatedKcal {
    final kg = bodyWeightKg;
    final minutes = duration.inSeconds / 60;
    if (kg == null || !kg.isFinite || kg < 20 || kg > 400 ||
        minutes < 5 || minutes > 240 || totalSets == 0) return null;
    return generalResistanceMet * 3.5 * kg / 200 * minutes;
  }
}
