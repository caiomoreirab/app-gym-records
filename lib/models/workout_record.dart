class WorkoutRecord {
  const WorkoutRecord({
    required this.date,
    this.weight = 0,
    this.repetitions,
    this.durationSeconds,
  });

  final DateTime date;
  final double weight;
  final int? repetitions;
  final int? durationSeconds;

  bool get hasWeight => weight > 0;
  bool get hasRepetitions => (repetitions ?? 0) > 0;
  bool get hasDuration => (durationSeconds ?? 0) > 0;

  Duration? get duration => hasDuration ? Duration(seconds: durationSeconds!) : null;
}
