import 'dart:math' as math;
import 'dart:ui';

import '../models/machine.dart';
import '../models/muscle_group.dart';
import '../models/workout_record.dart';

/// All analytics are derived from logged data. No hard-coded performance claims.
enum AnalyticsPeriod {
  week,
  month,
  quarter,
  all;

  String label(Locale locale) {
    final pt = locale.languageCode == 'pt';
    final es = locale.languageCode == 'es';
    return switch (this) {
      AnalyticsPeriod.week => pt ? '7 dias' : es ? '7 días' : '7 days',
      AnalyticsPeriod.month => pt ? '30 dias' : es ? '30 días' : '30 days',
      AnalyticsPeriod.quarter => pt ? '90 dias' : es ? '90 días' : '90 days',
      AnalyticsPeriod.all => pt ? 'Tudo' : es ? 'Todo' : 'All',
    };
  }

  DateTime lowerBound(DateTime now, Iterable<WorkoutRecord> records) {
    switch (this) {
      case AnalyticsPeriod.week:
        return now.subtract(const Duration(days: 7));
      case AnalyticsPeriod.month:
        return now.subtract(const Duration(days: 30));
      case AnalyticsPeriod.quarter:
        return now.subtract(const Duration(days: 90));
      case AnalyticsPeriod.all:
        var earliest = now.subtract(const Duration(days: 30));
        for (final record in records) {
          if (record.date.isBefore(earliest)) earliest = record.date;
        }
        return earliest;
    }
  }
}

enum AnalyticsMetric {
  volume,
  records,
  repetitions,
  minutes;

  String label(Locale locale) {
    final pt = locale.languageCode == 'pt';
    final es = locale.languageCode == 'es';
    return switch (this) {
      AnalyticsMetric.volume => pt ? 'Volume (kg)' : es ? 'Volumen (kg)' : 'Volume (kg)',
      AnalyticsMetric.records => pt ? 'Registros' : es ? 'Registros' : 'Logs',
      AnalyticsMetric.repetitions => pt ? 'Repetições' : es ? 'Repeticiones' : 'Repetitions',
      AnalyticsMetric.minutes => pt ? 'Tempo (min)' : es ? 'Tiempo (min)' : 'Time (min)',
    };
  }
}

class AnalyticsBucket {
  const AnalyticsBucket(this.label, this.value);
  final String label;
  final double value;
}

class GroupAnalyticsSummary {
  const GroupAnalyticsSummary({
    required this.group,
    required this.logs,
    required this.activeExercises,
    required this.trainingDays,
    required this.volumeKg,
    required this.repetitions,
    required this.durationMinutes,
    required this.maxWeight,
    required this.progressPercent,
  });

  final MuscleGroup? group;
  final int logs;
  final int activeExercises;
  final int trainingDays;
  final double volumeKg;
  final int repetitions;
  final double durationMinutes;
  final double maxWeight;
  final double? progressPercent;
}

abstract final class AnalyticsService {
  static List<Machine> machinesForGroup(Iterable<Machine> machines, MuscleGroup? group) =>
      machines.where((machine) => group == null || machine.group == group).toList(growable: false);

  static List<WorkoutRecord> recordsInRange(Iterable<Machine> machines, AnalyticsPeriod period, DateTime now) {
    final all = [for (final machine in machines) ...machine.records];
    final lower = period.lowerBound(now, all);
    return all.where((record) => !record.date.isBefore(lower) && !record.date.isAfter(now)).toList(growable: false);
  }

  static GroupAnalyticsSummary summary(
    Iterable<Machine> machines, {
    required AnalyticsPeriod period,
    required DateTime now,
    MuscleGroup? group,
  }) {
    final selected = machinesForGroup(machines, group);
    final all = [for (final machine in selected) ...machine.records];
    final lower = period.lowerBound(now, all);
    final relevant = <WorkoutRecord>[];
    var active = 0;
    final gains = <double>[];

    for (final machine in selected) {
      final records = machine.records.where((r) => !r.date.isBefore(lower) && !r.date.isAfter(now)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (records.isEmpty) continue;
      active++;
      relevant.addAll(records);
      final weighted = records.where((r) => r.weight > 0).toList();
      if (weighted.length >= 2 && weighted.first.weight > 0) {
        final gain = ((weighted.last.weight - weighted.first.weight) / weighted.first.weight) * 100;
        gains.add(gain.clamp(-100, 999).toDouble());
      }
    }

    final days = <String>{};
    var volume = 0.0;
    var repetitions = 0;
    var seconds = 0;
    var maxWeight = 0.0;
    for (final record in relevant) {
      days.add('${record.date.year}-${record.date.month}-${record.date.day}');
      if (record.weight > maxWeight) maxWeight = record.weight;
      if (record.weight > 0 && (record.repetitions ?? 0) > 0) {
        volume += record.weight * record.repetitions!;
      }
      repetitions += record.repetitions ?? 0;
      seconds += record.durationSeconds ?? 0;
    }

    return GroupAnalyticsSummary(
      group: group,
      logs: relevant.length,
      activeExercises: active,
      trainingDays: days.length,
      volumeKg: volume,
      repetitions: repetitions,
      durationMinutes: seconds / 60,
      maxWeight: maxWeight,
      progressPercent: gains.isEmpty ? null : gains.reduce((a, b) => a + b) / gains.length,
    );
  }

  static List<AnalyticsBucket> trend(
    Iterable<Machine> machines, {
    required AnalyticsPeriod period,
    required AnalyticsMetric metric,
    required DateTime now,
    MuscleGroup? group,
  }) {
    final selected = machinesForGroup(machines, group);
    final all = [for (final machine in selected) ...machine.records];
    final lower = period.lowerBound(now, all);
    final span = math.max(1, now.difference(lower).inSeconds);
    const bucketCount = 8;
    final values = List<double>.filled(bucketCount, 0);

    for (final record in all) {
      if (record.date.isBefore(lower) || record.date.isAfter(now)) continue;
      final index = ((record.date.difference(lower).inSeconds / span) * bucketCount).floor().clamp(0, bucketCount - 1).toInt();
      values[index] += switch (metric) {
        AnalyticsMetric.volume => record.weight > 0 && (record.repetitions ?? 0) > 0 ? record.weight * record.repetitions! : 0.0,
        AnalyticsMetric.records => 1.0,
        AnalyticsMetric.repetitions => (record.repetitions ?? 0).toDouble(),
        AnalyticsMetric.minutes => (record.durationSeconds ?? 0) / 60.0,
      };
    }

    return List.generate(bucketCount, (index) {
      final d = lower.add(Duration(seconds: (index * span / bucketCount).round()));
      return AnalyticsBucket('${d.day}/${d.month}', values[index]);
    });
  }

  static List<GroupAnalyticsSummary> groupSummaries(Iterable<Machine> machines, AnalyticsPeriod period, DateTime now) {
    final results = [
      for (final group in MuscleGroup.values) summary(machines, period: period, now: now, group: group),
    ];
    results.sort((a, b) => b.logs.compareTo(a.logs));
    return results;
  }

  static List<Machine> rankedMachines(Iterable<Machine> machines, {MuscleGroup? group, AnalyticsPeriod period = AnalyticsPeriod.all, DateTime? now}) {
    final moment = now ?? DateTime.now();
    final selected = machinesForGroup(machines, group);
    selected.sort((a, b) {
      final aCount = recordsInRange([a], period, moment).length;
      final bCount = recordsInRange([b], period, moment).length;
      return bCount.compareTo(aCount);
    });
    return selected.where((machine) => recordsInRange([machine], period, moment).isNotEmpty).toList(growable: false);
  }
}
