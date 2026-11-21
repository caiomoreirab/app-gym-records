import '../models/machine.dart';
import '../models/workout_record.dart';

/// A deterministic, offline weekly summary. Weeks start on Monday.
class WeeklyWorkoutSummary {
  const WeeklyWorkoutSummary({
    required this.trainingDays,
    required this.exerciseCount,
    required this.workingSets,
    required this.totalVolume,
  });

  final int trainingDays;
  final int exerciseCount;
  final int workingSets;
  final double totalVolume;

  static WeeklyWorkoutSummary calculate(
    Iterable<Machine> machines, {
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - DateTime.monday));
    final end = monday.add(const Duration(days: 7));
    final days = <String>{};
    final exercises = <String>{};
    var sets = 0;
    var volume = 0.0;
    for (final machine in machines) {
      for (final record in machine.records) {
        if (record.date.isBefore(monday) || !record.date.isBefore(end)) continue;
        days.add(WorkoutRecord.dayKey(record.date));
        exercises.add(machine.id);
        if (!record.isWarmup) {
          sets++;
          volume += record.weight * (record.repetitions ?? 0);
        }
      }
    }
    return WeeklyWorkoutSummary(
      trainingDays: days.length,
      exerciseCount: exercises.length,
      workingSets: sets,
      totalVolume: volume,
    );
  }
}
