import 'dart:ui';

import 'cardio_record.dart';

enum CardioKind {
  outdoorRun,
  treadmill,
  walk,
  cycling,
  stationaryBike,
  elliptical,
  stairClimber,
  rowing,
  jumpRope;
}

class CardioActivity {
  CardioActivity({
    required this.id,
    required this.name,
    required this.nameEn,
    this.nameEs,
    required this.kind,
    this.supportsDistance = true,
    this.supportsPace = true,
    this.paceDistanceKm = 1.0,
    this.supportsIncline = false,
    this.supportsResistance = false,
    List<CardioRecord>? records,
  }) : records = records ?? <CardioRecord>[];

  final String id;
  final String name;
  final String nameEn;
  final String? nameEs;
  final CardioKind kind;
  final bool supportsDistance;
  final bool supportsPace;
  final double paceDistanceKm;
  final bool supportsIncline;
  final bool supportsResistance;
  final List<CardioRecord> records;

  String localizedName(Locale locale) {
    return switch (locale.languageCode) {
      'en' => nameEn,
      'es' => nameEs ?? name,
      _ => name,
    };
  }

  CardioRecord? get latestRecord {
    if (records.isEmpty) return null;
    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first;
  }

  double get longestDistanceKm {
    if (records.isEmpty) return 0;
    return records.map((r) => r.distanceKm ?? 0).fold(0, (a, b) => b > a ? b : a);
  }

  Duration get longestDuration {
    if (records.isEmpty) return Duration.zero;
    return records.map((r) => r.duration).fold(Duration.zero, (a, b) => b > a ? b : a);
  }

  double? get bestPaceMinutes {
    if (!supportsPace) return null;
    final paces = records.map((r) {
      final distance = r.distanceKm;
      if (distance == null || distance <= 0) return null;
      return (r.duration.inSeconds / 60) / (distance / paceDistanceKm);
    }).whereType<double>().toList();
    if (paces.isEmpty) return null;
    paces.sort();
    return paces.first;
  }

  double? get fastestSpeedKmh {
    final values = records.map((r) => r.averageSpeedKmh).whereType<double>().toList();
    if (values.isEmpty) return null;
    values.sort((a, b) => b.compareTo(a));
    return values.first;
  }
}
