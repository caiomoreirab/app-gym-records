class CardioRecord {
  const CardioRecord({
    required this.date,
    required this.duration,
    this.distanceKm,
    this.heartRateBpm,
    this.calories,
    this.inclinePercent,
    this.resistanceLevel,
    this.notes = '',
    this.sessionId,
  });

  final DateTime date;
  final Duration duration;
  final double? distanceKm;
  final int? heartRateBpm;
  final int? calories;
  final double? inclinePercent;
  final double? resistanceLevel;
  final String notes;
  /// Optional workout linkage; legacy cardio records remain independent.
  final String? sessionId;

  double? get paceMinutesPerKm {
    final distance = distanceKm;
    if (distance == null || distance <= 0) return null;
    return duration.inSeconds / 60 / distance;
  }

  double? get averageSpeedKmh {
    final distance = distanceKm;
    if (distance == null || distance <= 0 || duration.inSeconds <= 0) return null;
    return distance / (duration.inSeconds / 3600);
  }
}
