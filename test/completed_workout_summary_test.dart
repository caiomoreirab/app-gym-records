import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/models/workout_record.dart';
import 'package:gymrecords/models/workout_session.dart';
import 'package:gymrecords/services/completed_workout_summary.dart';

void main() {
  test('resumo usa inicio/fim, series, volume, PR e MET 3.5', () {
    final start = DateTime(2026, 11, 21, 10);
    final finish = DateTime(2026, 11, 21, 11);
    final exercise = buildExerciseCatalog().firstWhere(
        (m) => m.id == 'barbell_bench_press');
    exercise.records.addAll([
      WorkoutRecord(id: 'past', sessionId: 'yesterday',
        date: start.subtract(const Duration(days: 1)),
        weight: 80, repetitions: 10),
      WorkoutRecord(id: '1', sessionId: 'today', date: start,
        weight: 100, repetitions: 3),
      WorkoutRecord(id: '2', sessionId: 'today',
        date: start.add(const Duration(minutes: 20)),
        weight: 90, repetitions: 10),
      WorkoutRecord(id: 'warmup', sessionId: 'today',
        date: start.add(const Duration(minutes: 30)),
        weight: 120, repetitions: 5, isWarmup: true),
    ]);
    final summary = CompletedWorkoutSummary(
      session: WorkoutSession(id: 'today', startedAt: start,
        completedAt: finish, exerciseIds: [exercise.id]),
      machines: [exercise], bodyWeightKg: 80);
    expect(summary.duration, const Duration(hours: 1));
    expect(summary.exerciseCount, 1);
    expect(summary.totalSets, 3);
    expect(summary.volumeKg, 1800);
    expect(summary.weightPersonalRecords, 1);
    expect(summary.estimatedKcal, closeTo(294, 0.001));
  });

  test('sem peso ou sessão inválida não inventa calorias', () {
    final exercise = buildExerciseCatalog().first;
    final start = DateTime(2026, 11, 21, 10);
    exercise.records.add(WorkoutRecord(
      id: '1', sessionId: 's1', date: start,
      weight: 80, repetitions: 8));
    final session = WorkoutSession(id: 's1', startedAt: start,
      completedAt: start.add(const Duration(minutes: 4)));
    expect(CompletedWorkoutSummary(
      session: session, machines: [exercise], bodyWeightKg: 80
    ).estimatedKcal, isNull);
    expect(CompletedWorkoutSummary(
      session: session.copyWith(completedAt: start.add(
        const Duration(minutes: 40))),
      machines: [exercise], bodyWeightKg: null
    ).estimatedKcal, isNull);
    expect(CompletedWorkoutSummary(
      session: session.copyWith(completedAt: start.add(
        const Duration(hours: 6))),
      machines: [exercise], bodyWeightKg: 80
    ).estimatedKcal, isNull);
  });
}
