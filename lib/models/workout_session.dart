/// A workout is a time-bounded session. Records hold the session ID.
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.startedAt,
    this.name = 'Treino',
    this.completedAt,
    this.exerciseIds = const [],
  });

  final String id;
  final DateTime startedAt;
  final String name;
  final DateTime? completedAt;
  final List<String> exerciseIds;

  bool get isCompleted => completedAt != null;

  WorkoutSession copyWith({String? name, DateTime? completedAt,
      List<String>? exerciseIds}) =>
      WorkoutSession(
        id: id,
        startedAt: startedAt,
        name: name ?? this.name,
        completedAt: completedAt ?? this.completedAt,
        exerciseIds: exerciseIds ?? this.exerciseIds,
      );

  static String legacyId(DateTime day) =>
      'legacy_${day.year.toString().padLeft(4, '0')}'
      '${day.month.toString().padLeft(2, '0')}'
      '${day.day.toString().padLeft(2, '0')}';
}
