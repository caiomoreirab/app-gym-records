/// A workout is a time-bounded session. Records hold the session ID.
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.startedAt,
    this.name = 'Treino',
    this.completedAt,
  });

  final String id;
  final DateTime startedAt;
  final String name;
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;

  WorkoutSession copyWith({String? name, DateTime? completedAt}) =>
      WorkoutSession(
        id: id,
        startedAt: startedAt,
        name: name ?? this.name,
        completedAt: completedAt ?? this.completedAt,
      );

  static String legacyId(DateTime day) =>
      'legacy_${day.year.toString().padLeft(4, '0')}'
      '${day.month.toString().padLeft(2, '0')}'
      '${day.day.toString().padLeft(2, '0')}';
}
