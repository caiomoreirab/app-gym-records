/// A single set in a training session. Existing v1 records can omit new fields.
class WorkoutRecord {
  const WorkoutRecord({
    required this.date,
    this.weight = 0,
    this.repetitions,
    this.durationSeconds,
    this.id,
    this.sessionId,
    this.isWarmup = false,
    this.rpe,
    this.note = '',
  });

  final DateTime date;
  final double weight;
  final int? repetitions;
  final int? durationSeconds;
  final String? id;
  final String? sessionId;
  final bool isWarmup;
  final int? rpe;
  final String note;

  bool get hasWeight => weight > 0;
  bool get hasRepetitions => (repetitions ?? 0) > 0;
  bool get hasDuration => (durationSeconds ?? 0) > 0;
  Duration? get duration => hasDuration ? Duration(seconds: durationSeconds!) : null;

  /// A single implicit session per local calendar day in the first iteration.
  /// A later multi-session feature may supply explicit session identifiers.
  String get effectiveSessionId => sessionId ?? sessionForDay(date);

  static String sessionForDay(DateTime date) {
    final d = date.toLocal();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return 'day-${d.year}-$m-$day';
  }

  WorkoutRecord copyWith({
    DateTime? date,
    double? weight,
    int? repetitions,
    int? durationSeconds,
    bool? isWarmup,
    int? rpe,
    String? note,
  }) => WorkoutRecord(
        date: date ?? this.date,
        weight: weight ?? this.weight,
        repetitions: repetitions ?? this.repetitions,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        id: id,
        sessionId: sessionId,
        isWarmup: isWarmup ?? this.isWarmup,
        rpe: rpe ?? this.rpe,
        note: note ?? this.note,
      );
}
