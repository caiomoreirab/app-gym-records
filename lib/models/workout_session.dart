/// A workout is a time-bounded session. Records hold the session ID.
///
/// [completedExerciseIds] tracks deliberate user validation independently
/// from saved sets. Checking an exercise never creates a fake strength set.
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.startedAt,
    this.name = 'Treino',
    this.completedAt,
    this.exerciseIds = const [],
    this.completedExerciseIds = const [],
    this.selectedGroupIds = const [],
    this.plannedCardioIds = const [],
  });

  final String id;
  final DateTime startedAt;
  final String name;
  final DateTime? completedAt;
  final List<String> exerciseIds;
  final List<String> completedExerciseIds;
  /// Optional filters for this session only. Empty means all groups.
  /// 'cardio' is a filter/shortcut; strength sets remain exercise records.
  final List<String> selectedGroupIds;
  /// Cardio activities intentionally added to this workout. Does not
  /// fabricate an activity record or count towards strength-set progress.
  final List<String> plannedCardioIds;

  bool get isCompleted => completedAt != null;
  bool isExerciseCompleted(String machineId) =>
      completedExerciseIds.contains(machineId);

  int get completedCount => completedExerciseIds
      .where(exerciseIds.contains).length;
  int get pendingCount => exerciseIds.length - completedCount;
  double get progress => exerciseIds.isEmpty
      ? 0 : completedCount / exerciseIds.length;

  WorkoutSession copyWith({
    String? name,
    DateTime? completedAt,
    List<String>? exerciseIds,
    List<String>? completedExerciseIds,
    List<String>? selectedGroupIds,
    List<String>? plannedCardioIds,
  }) => WorkoutSession(
        id: id,
        startedAt: startedAt,
        name: name ?? this.name,
        completedAt: completedAt ?? this.completedAt,
        exerciseIds: exerciseIds ?? this.exerciseIds,
        completedExerciseIds: completedExerciseIds ?? this.completedExerciseIds,
        selectedGroupIds: selectedGroupIds ?? this.selectedGroupIds,
        plannedCardioIds: plannedCardioIds ?? this.plannedCardioIds,
      );

  static String legacyId(DateTime day) =>
      'legacy_${day.year.toString().padLeft(4, '0')}'
      '${day.month.toString().padLeft(2, '0')}'
      '${day.day.toString().padLeft(2, '0')}';
}
