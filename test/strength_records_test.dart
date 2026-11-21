import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/models/workout_record.dart';
import 'package:gymrecords/services/strength_records.dart';

void main() {
  test('recordes ignoram aquecimento, respeitam faixa e usam Epley', () {
    final sets = [
      WorkoutRecord(date: DateTime(2026), weight: 120, repetitions: 10,
        isWarmup: true),
      WorkoutRecord(date: DateTime(2026), weight: 100, repetitions: 3),
      WorkoutRecord(date: DateTime(2026), weight: 85, repetitions: 8),
      WorkoutRecord(date: DateTime(2026), weight: 80, repetitions: 12),
    ];
    expect(StrengthRecords.maxWeight(sets), 100);
    expect(StrengthRecords.maxWeightForRepRange(sets), 85);
    expect(StrengthRecords.maxEstimatedOneRepMax(sets), closeTo(112, 0.001));
    expect(StrengthRecords.estimatedOneRepMax(
      WorkoutRecord(date: DateTime(2026), weight: 50, repetitions: 30)), isNull);
    expect(StrengthRecords.estimatedOneRepMax(
      WorkoutRecord(date: DateTime(2026), weight: 50, repetitions: 1)), 50);
  });
}
