import 'workout_session.dart';

/// One immutable set. Older records are assigned stable IDs when decoding.
class WorkoutRecord {
  const WorkoutRecord({
    required this.date,
    this.id = '',
    this.sessionId = '',
    this.weight = 0,
    this.repetitions,
    this.durationSeconds,
    this.rpe,
    this.rir,
    this.restSeconds,
    this.note = '',
    this.isWarmup = false,
    this.extra = const {},
  });

  final String id;
  final String sessionId;
  final DateTime date;
  final double weight;
  final int? repetitions;
  final int? durationSeconds;
  final double? rpe;
  final int? rir;
  final int? restSeconds;
  final String note;
  final bool isWarmup;
  /// Keeps future/experimental record fields intact when backing up again.
  final Map<String, dynamic> extra;

  bool get hasWeight => weight > 0;
  bool get hasRepetitions => (repetitions ?? 0) > 0;
  bool get hasDuration => (durationSeconds ?? 0) > 0;
  Duration? get duration =>
      hasDuration ? Duration(seconds: durationSeconds!) : null;

  String get effectiveSessionId => sessionId.isNotEmpty
      ? sessionId : WorkoutSession.legacyId(date);

  WorkoutRecord copyWith({
    String? id, String? sessionId, DateTime? date, double? weight,
    int? repetitions, int? durationSeconds, double? rpe, int? rir,
    int? restSeconds, String? note, bool? isWarmup,
  }) => WorkoutRecord(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    date: date ?? this.date,
    weight: weight ?? this.weight,
    repetitions: repetitions ?? this.repetitions,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    rpe: rpe ?? this.rpe,
    rir: rir ?? this.rir,
    restSeconds: restSeconds ?? this.restSeconds,
    note: note ?? this.note,
    isWarmup: isWarmup ?? this.isWarmup,
    extra: extra,
  );
}
