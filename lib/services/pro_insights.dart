import 'dart:ui';

import '../models/machine.dart';
import '../models/muscle_group.dart';
import '../models/workout_record.dart';
import 'strength_records.dart';

class ProExerciseInsights {
  const ProExerciseInsights({
    required this.prProbability,
    required this.nextTarget,
    required this.targetRepetitions,
    required this.estimatedOneRepMax,
    required this.maxVolume,
    required this.progressPercent,
    required this.hasPossiblePlateau,
    required this.mostRepsRecord,
  });

  final double prProbability;
  final double nextTarget;
  final int targetRepetitions;
  final double estimatedOneRepMax;
  final double maxVolume;
  final double progressPercent;
  final bool hasPossiblePlateau;
  final WorkoutRecord? mostRepsRecord;

  String probabilityLabelFor(Locale locale) {
    final languageCode = locale.languageCode;
    if (prProbability >= .82) return languageCode == 'en' ? 'High' : 'Alta';
    if (prProbability >= .62) return languageCode == 'en' ? 'Moderate' : 'Moderada';
    return languageCode == 'en' ? 'Low' : languageCode == 'es' ? 'Baja' : 'Baixa';
  }

  String get probabilityLabel => probabilityLabelFor(const Locale('pt', 'BR'));
}

abstract final class ProInsights {
  static ProExerciseInsights forMachine(Machine machine, double increment) {
    final sets = StrengthRecords.workingSets(machine.records).toList();
    final sorted = [...sets]
      ..sort((a, b) => b.date.compareTo(a.date));
    final record = machine.recordWeight;
    final latest = sorted.isEmpty ? null : sorted.first;
    final target = record <= 0 ? (increment > 2.5 ? increment : 2.5) : record + increment;
    final latestReps = latest?.repetitions ?? 8;
    final targetReps = latestReps < 6 ? 6 : (latestReps > 12 ? 12 : latestReps);

    var oneRepMax = record;
    var maxVolume = 0.0;
    WorkoutRecord? mostReps;
    for (final item in sets) {
      final itemReps = item.repetitions ?? 0;
      final estimate = StrengthRecords.estimatedOneRepMax(item) ?? 0;
      if (estimate > oneRepMax) oneRepMax = estimate;
      final volume = item.weight * itemReps;
      if (volume > maxVolume) maxVolume = volume;
      if (mostReps == null ||
          itemReps > (mostReps.repetitions ?? 0) ||
          (itemReps == (mostReps.repetitions ?? 0) &&
              item.weight > mostReps.weight)) {
        mostReps = item;
      }
    }

    final chronological = [...sets]
      ..sort((a, b) => a.date.compareTo(b.date));
    final firstWeight = chronological.isEmpty ? 0.0 : chronological.first.weight;
    final progress = firstWeight <= 0
        ? 0.0
        : ((record - firstWeight) / firstWeight * 100).clamp(0.0, 999.0).toDouble();

    var plateau = false;
    if (sorted.length >= 3) {
      final lastThree = sorted.take(3).map((e) => e.weight).toList();
      var high = lastThree.first;
      var low = lastThree.first;
      for (final value in lastThree.skip(1)) {
        if (value > high) high = value;
        if (value < low) low = value;
      }
      plateau = high > 0 && ((high - low) / high) <= .10;
    }

    final latestRatio = record <= 0 || latest == null ? 0.5 : latest.weight / record;
    final historyCount = sets.length > 5 ? 5 : sets.length;
    final historyBonus = historyCount * .025;
    final probability = (0.64 + latestRatio * .20 + historyBonus)
        .clamp(.45, .94)
        .toDouble();

    return ProExerciseInsights(
      prProbability: probability,
      nextTarget: target,
      targetRepetitions: targetReps,
      estimatedOneRepMax: oneRepMax,
      maxVolume: maxVolume,
      progressPercent: progress,
      hasPossiblePlateau: plateau,
      mostRepsRecord: mostReps,
    );
  }

  static const Map<MuscleGroup, double> groupEvolution = {
    MuscleGroup.legs: 27,
    MuscleGroup.back: 18,
    MuscleGroup.chest: 12,
    MuscleGroup.biceps: 9,
    MuscleGroup.triceps: 8,
    MuscleGroup.shoulders: 6,
    MuscleGroup.abs: 4,
  };

  static const List<double> weeklyLoadTrend = [
    53.0,
    56.5,
    59.5,
    59.0,
    62.0,
    64.5,
    66.2,
    68.4,
  ];
}
