class WorkoutRecord {
  const WorkoutRecord({
    required this.date,
    this.id = '',
    this.sessionId = '',
    this.gymId = 'default',
    this.weight = 0,
    this.repetitions,
    this.durationSeconds,
    this.isWarmup = false,
    this.rpe,
    this.note = '',
  });

  /// Stable ID lets editing/deletion target a single set, not every record
  /// with the same weight/date. Old backups receive deterministic IDs on load.
  final String id;

  /// A training session groups sets. Existing backups fall back to their day.
  final String sessionId;
  final String gymId;
  final DateTime date;
  final double weight;
  final int? repetitions;
  final int? durationSeconds;
  final bool isWarmup;
  final double? rpe;
  final String note;

  bool get hasWeight => weight > 0;
  bool get hasRepetitions => (repetitions ?? 0) > 0;
  bool get hasDuration => (durationSeconds ?? 0) > 0;
  Duration? get duration =>
      hasDuration ? Duration(seconds: durationSeconds!) : null;

  WorkoutRecord copyWith({
    String? id,
    String? sessionId,
    String? gymId,
    DateTime? date,
    double? weight,
    int? repetitions,
    int? durationSeconds,
    bool? isWarmup,
    double? rpe,
    String? note,
  }) => WorkoutRecord(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        gymId: gymId ?? this.gymId,
        date: date ?? this.date,
        weight: weight ?? this.weight,
        repetitions: repetitions ?? this.repetitions,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        isWarmup: isWarmup ?? this.isWarmup,
        rpe: rpe ?? this.rpe,
        note: note ?? this.note,
      );

  static String dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
