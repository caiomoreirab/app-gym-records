import '../data/mock_data.dart';
import '../models/cardio_activity.dart';
import '../models/cardio_record.dart';
import '../models/machine.dart';
import '../models/muscle_group.dart';
import '../models/workout_record.dart';
import '../models/workout_session.dart';

/// Versioned, portable backup format. The database and backup use the same
/// serialization; only recorded user state is stored (no sample workout data).
class WorkoutSnapshotCodec {
  const WorkoutSnapshotCodec._();

  static const schemaVersion = 2;

  static Map<String, dynamic> encode({
    required List<Machine> machines,
    required List<CardioActivity> cardioActivities,
    Map<String, List<CardioRecord>> preservedCardio = const {},
    List<WorkoutSession> sessions = const [],
    Set<String> favorites = const {},
    String? activeSessionId,
    Map<String, dynamic> rootExtras = const {},
  }) =>
      {
        ...rootExtras,
        'schemaVersion': schemaVersion,
        'activeSessionId': activeSessionId,
        'favorites': favorites.toList()..sort(),
        'sessions': [
          for (final item in sessions)
            {
              'id': item.id,
              'name': item.name,
              'startedAt': item.startedAt.toUtc().toIso8601String(),
              'completedAt': item.completedAt?.toUtc().toIso8601String(),
              'exerciseIds': item.exerciseIds,
              'completedExerciseIds': item.completedExerciseIds,
              'selectedGroupIds': item.selectedGroupIds,
              'plannedCardioIds': item.plannedCardioIds,
            },
        ],
        'machines': [
          for (final machine in machines)
            {
              ...machine.extra,
              'id': machine.id,
              'custom': machine.isCustom,
              'name': machine.name,
              'note': machine.note,
              'group': machine.group.name,
              'equipment': machine.equipment.name,
              'records': [
                for (final r in machine.records)
                  {
                    ...r.extra,
                    'id': r.id,
                    'sessionId': r.effectiveSessionId,
                    'warmup': r.isWarmup,
                    'rpe': r.rpe,
                    'rir': r.rir,
                    'restSeconds': r.restSeconds,
                    'note': r.note,
                    'date': r.date.toUtc().toIso8601String(),
                    'weight': r.weight,
                    'repetitions': r.repetitions,
                    'durationSeconds': r.durationSeconds,
                  },
              ],
            },
        ],
        'cardio': {
          // Keep historical activity IDs that are no longer in the current
          // catalog. A future version may restore their UI without losing data.
          for (final entry in preservedCardio.entries)
            entry.key: [
              for (final r in entry.value)
                {
                  'date': r.date.toUtc().toIso8601String(),
                  'seconds': r.duration.inSeconds,
                  'distanceKm': r.distanceKm,
                  'heartRateBpm': r.heartRateBpm,
                  'calories': r.calories,
                  'inclinePercent': r.inclinePercent,
                  'resistanceLevel': r.resistanceLevel,
                  'notes': r.notes,
                  'sessionId': r.sessionId,
                },
            ],
          for (final activity in cardioActivities)
            activity.id: [
              for (final r in activity.records)
                {
                  'date': r.date.toUtc().toIso8601String(),
                  'seconds': r.duration.inSeconds,
                  'distanceKm': r.distanceKm,
                  'heartRateBpm': r.heartRateBpm,
                  'calories': r.calories,
                  'inclinePercent': r.inclinePercent,
                  'resistanceLevel': r.resistanceLevel,
                  'notes': r.notes,
                  'sessionId': r.sessionId,
                },
            ],
        },
      };

  /// Parses into new objects before touching live state. A malformed backup
  /// therefore cannot partially erase the data currently in memory.
  static WorkoutRestoredState decode(Map<String, dynamic> input) {
    if (input['schemaVersion'] != 1 && input['schemaVersion'] != schemaVersion) {
      throw const FormatException('Versão de backup incompatível.');
    }
    final savedMachines = input['machines'];
    final savedCardio = input['cardio'];
    if (savedMachines is! List || savedCardio is! Map) {
      throw const FormatException('Estrutura de backup inválida.');
    }
    if (savedMachines.length > 2000) throw const FormatException('Backup muito grande.');

    final catalog = {for (final machine in buildExerciseCatalog()) machine.id: machine};
    final newMachines = <Machine>[];
    final ids = <String>{};
    var totalRecords = 0;
    for (final raw in savedMachines) {
      if (raw is! Map) throw const FormatException('Exercício inválido.');
      final m = Map<String, dynamic>.from(raw);
      final id = m['id'];
      if (id is! String || id.isEmpty || !ids.add(id)) {
        throw const FormatException('ID de exercício inválido ou repetido.');
      }
      final custom = m['custom'] == true;
      final name = m['name'];
      final note = m['note'];
      final entries = m['records'];
      if (name is! String || name.trim().isEmpty || name.length > 120 ||
          note is! String || note.length > 3000 || entries is! List) {
        throw const FormatException('Dados de exercício inválidos.');
      }
      totalRecords += entries.length;
      if (totalRecords > 100000) throw const FormatException('Histórico muito grande.');
      Machine? machine = catalog[id];
      if (custom || machine == null) {
        // Preserve historical exercises even if a later version removes or
        // renames an ID in its built-in catalog. They remain visible as custom
        // entries with their original IDs and full workout history.
        final group = _byName(MuscleGroup.values, m['group']);
        final equipment = _byName(EquipmentType.values, m['equipment']);
        machine = Machine(
          id: id,
          name: name.trim(),
          group: group,
          equipment: equipment,
          imageAsset: 'assets/illustrations/generic_machine.webp',
          isCustom: true,
          extra: _extras(m, const {'id', 'custom', 'name', 'note', 'group', 'equipment', 'records'}),
        );
      }
      // The built-in catalog can be reused but its experimental settings must survive.
      if (machine.extra.isEmpty && !custom && catalog.containsKey(id)) {
        machine = Machine(
          id: machine.id, name: machine.name, nameEn: machine.nameEn,
          group: machine.group, imageAsset: machine.imageAsset,
          visualAssetId: machine.visualAssetId, equipment: machine.equipment,
          subgroup: machine.subgroup, subgroupEn: machine.subgroupEn,
          aliases: machine.aliases, isCustom: machine.isCustom,
          extra: _extras(m, const {'id', 'custom', 'name', 'note', 'group', 'equipment', 'records'}),
        );
      }
      machine.name = name.trim();
      machine.nameEn = custom ? name.trim() : machine.nameEn;
      machine.note = note;
      machine.records.addAll(entries.asMap().entries.map((entry) {
        if (entry.value is! Map) {
          throw const FormatException('Registro de treino inválido.');
        }
        final r = Map<String, dynamic>.from(entry.value as Map);
        final date = _date(r['date']);
        final rawId = r['id'];
        final rawSessionId = r['sessionId'];
        if (rawId != null && (rawId is! String || rawId.length > 160)) {
          throw const FormatException('Identificador de série inválido.');
        }
        if (rawSessionId != null &&
            (rawSessionId is! String || rawSessionId.length > 160)) {
          throw const FormatException('Identificador de sessão inválido.');
        }
        final rawNote = r['note'] ?? '';
        if (rawNote is! String || rawNote.length > 3000) {
          throw const FormatException('Anotação de série inválida.');
        }
        final rawRpe = _number(r['rpe']);
        if (rawRpe != null && (rawRpe < 1 || rawRpe > 10)) {
          throw const FormatException('RPE inválido.');
        }
        final rir = _nonNegativeInteger(r['rir']);
        if (rir != null && rir > 10) throw const FormatException('RIR inválido.');
        final rest = _nonNegativeInteger(r['restSeconds']);
        if (rest != null && rest > 36000) {
          throw const FormatException('Descanso inválido.');
        }
        return WorkoutRecord(
          id: rawId is String && rawId.isNotEmpty
              ? rawId : 'migrated_${id}_${entry.key}_${date.microsecondsSinceEpoch}',
          sessionId: rawSessionId is String && rawSessionId.isNotEmpty
              ? rawSessionId : WorkoutSession.legacyId(date),
          date: date,
          weight: _nonNegativeNumber(r['weight']) ?? 0,
          repetitions: _nonNegativeInteger(r['repetitions']),
          durationSeconds: _nonNegativeInteger(r['durationSeconds']),
          rpe: rawRpe,
          rir: rir,
          restSeconds: rest,
          note: rawNote,
          isWarmup: r['warmup'] == true,
          extra: _extras(r, const {
            'id', 'sessionId', 'date', 'weight', 'repetitions',
            'durationSeconds', 'rpe', 'rir', 'restSeconds', 'note', 'warmup',
          }),
        );
      }));
      newMachines.add(machine);
    }

    final newCardio = <String, List<CardioRecord>>{};
    for (final entry in savedCardio.entries) {
      if (entry.key is! String ||
          (entry.key as String).isEmpty ||
          (entry.key as String).length > 120 ||
          entry.value is! List) {
        throw const FormatException('Atividade de cardio inválida.');
      }
      final records = <CardioRecord>[];
      final list = entry.value as List;
      totalRecords += list.length;
      if (totalRecords > 100000) throw const FormatException('Histórico muito grande.');
      for (final raw in list) {
        if (raw is! Map) throw const FormatException('Registro de cardio inválido.');
        final r = Map<String, dynamic>.from(raw);
        final seconds = _nonNegativeInteger(r['seconds']);
        if (seconds == null) throw const FormatException('Duração inválida.');
        final notes = r['notes'];
        if (notes is! String || notes.length > 3000) {
          throw const FormatException('Anotações de Cardio inválidas.');
        }
        records.add(CardioRecord(
          date: _date(r['date']),
          duration: Duration(seconds: seconds),
          distanceKm: _nonNegativeNumber(r['distanceKm']),
          heartRateBpm: _nonNegativeInteger(r['heartRateBpm']),
          calories: _nonNegativeInteger(r['calories']),
          inclinePercent: _number(r['inclinePercent']),
          resistanceLevel: _nonNegativeNumber(r['resistanceLevel']),
          notes: notes,
          sessionId: r['sessionId'] is String &&
                  (r['sessionId'] as String).isNotEmpty
              ? r['sessionId'] as String : null,
        ));
      }
      newCardio[entry.key as String] = records;
    }
    final sessions = <String, WorkoutSession>{};
    final rawSessions = input['sessions'];
    if (rawSessions != null) {
      if (rawSessions is! List || rawSessions.length > 20000) {
        throw const FormatException('Lista de sessões inválida.');
      }
      for (final raw in rawSessions) {
        if (raw is! Map) throw const FormatException('Sessão inválida.');
        final item = Map<String, dynamic>.from(raw);
        final id = item['id'];
        final name = item['name'] ?? 'Treino';
        if (id is! String || id.isEmpty || id.length > 160 ||
            name is! String || name.length > 160 ||
            sessions.containsKey(id)) {
          throw const FormatException('ID ou nome de sessão inválido.');
        }
        final rawExerciseIds = item['exerciseIds'];
        final rawDoneIds = item['completedExerciseIds'];
        final rawGroupIds = item['selectedGroupIds'];
        final rawCardioIds = item['plannedCardioIds'];
        if ((rawExerciseIds != null && rawExerciseIds is! List) ||
            (rawDoneIds != null && rawDoneIds is! List) ||
            (rawGroupIds != null && rawGroupIds is! List) ||
            (rawCardioIds != null && rawCardioIds is! List)) {
          throw const FormatException('Lista de exercícios da sessão inválida.');
        }
        final ids = rawExerciseIds is List
            ? rawExerciseIds.whereType<String>().toSet().toList() : <String>[];
        final done = rawDoneIds is List
            ? rawDoneIds.whereType<String>().toSet().toList() : <String>[];
        final groups = rawGroupIds is List
            ? rawGroupIds.whereType<String>().toList() : <String>[];
        final plannedCardio = rawCardioIds is List
            ? rawCardioIds.whereType<String>().toList() : <String>[];
        if (plannedCardio.length !=
              (rawCardioIds is List ? rawCardioIds.length : 0) ||
            plannedCardio.length > 100 ||
            plannedCardio.length != plannedCardio.toSet().length ||
            plannedCardio.any((id) => id.isEmpty || id.length > 160)) {
          throw const FormatException('Atividades de cardio planejadas inválidas.');
        }
        final validGroupIds = {
          for (final group in MuscleGroup.values) group.name, 'cardio',
        };
        if (groups.length != (rawGroupIds is List ? rawGroupIds.length : 0) ||
            groups.length != groups.toSet().length ||
            groups.any((id) => !validGroupIds.contains(id))) {
          throw const FormatException('Grupos do treino inválidos.');
        }
        if (ids.length > 500 || done.length > 500 ||
            ids.any((id) => id.isEmpty || id.length > 160) ||
            done.any((id) => !ids.contains(id)) ||
            (rawExerciseIds is List && ids.length != rawExerciseIds.length) ||
            (rawDoneIds is List && done.length != rawDoneIds.length)) {
          throw const FormatException('Exercícios da sessão inconsistentes.');
        }
        sessions[id] = WorkoutSession(
          id: id, name: name,
          startedAt: _date(item['startedAt']),
          completedAt: item['completedAt'] == null ? null
              : _date(item['completedAt']),
          exerciseIds: ids,
          completedExerciseIds: done,
          selectedGroupIds: groups,
          plannedCardioIds: plannedCardio,
        );
      }
    }
    // The experimental v0.10.0 also used schemaVersion 1, with metadata maps.
    final legacyNames = input['sessionNames'];
    for (final machine in newMachines) {
      for (final record in machine.records) {
        final id = record.effectiveSessionId;
        final existing = sessions[id];
        if (existing != null) {
          if (!existing.exerciseIds.contains(machine.id)) {
            sessions[id] = existing.copyWith(
              exerciseIds: [...existing.exerciseIds, machine.id]);
          }
          continue;
        }
        var name = 'Treino do dia';
        if (legacyNames is Map && legacyNames[id] is String) {
          name = legacyNames[id] as String;
        }
        sessions[id] = WorkoutSession(
          id: id, startedAt: record.date, name: name,
          completedAt: id.startsWith('legacy_') ? record.date : null,
          exerciseIds: [machine.id],
        );
      }
    }
    final rawFavorites = input['favorites'];
    final favorites = <String>{};
    if (rawFavorites != null) {
      if (rawFavorites is! List || rawFavorites.length > 2000) {
        throw const FormatException('Favoritos inválidos.');
      }
      for (final value in rawFavorites) {
        if (value is! String || value.length > 160) {
          throw const FormatException('Favorito inválido.');
        }
        favorites.add(value);
      }
    }
    final active = input['activeSessionId'];
    if (active != null && (active is! String || active.length > 160)) {
      throw const FormatException('Sessão ativa inválida.');
    }
    final requestedActive = active is String && sessions.containsKey(active) &&
        !sessions[active]!.isCompleted ? active : null;
    return WorkoutRestoredState(newMachines, newCardio,
      sessions: sessions.values.toList(), favorites: favorites,
      activeSessionId: requestedActive,
      rootExtras: _extras(input, const {
        'schemaVersion', 'machines', 'cardio', 'sessions',
        'favorites', 'activeSessionId',
      }),
    );
  }

  static Map<String, dynamic> _extras(Map<String, dynamic> source,
      Set<String> known) => {
    for (final entry in source.entries)
      if (!known.contains(entry.key)) entry.key: entry.value,
  };

  static T _byName<T extends Enum>(List<T> values, Object? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw const FormatException('Categoria desconhecida.');
  }

  static DateTime _date(Object? value) {
    if (value is! String) throw const FormatException('Data inválida.');
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw const FormatException('Data inválida.');
    return parsed.toLocal();
  }

  static double? _number(Object? value) {
    if (value == null) return null;
    if (value is! num || !value.isFinite) throw const FormatException('Número inválido.');
    return value.toDouble();
  }

  static double? _nonNegativeNumber(Object? value) {
    final parsed = _number(value);
    if (parsed != null && parsed < 0) {
      throw const FormatException('Valor negativo inválido.');
    }
    return parsed;
  }

  static int? _nonNegativeInteger(Object? value) {
    if (value == null) return null;
    if (value is! int || value < 0) {
      throw const FormatException('Número inteiro não negativo inválido.');
    }
    return value;
  }
}

class WorkoutRestoredState {
  WorkoutRestoredState(this.machines, this.cardio,
      {this.sessions = const [], this.favorites = const {},
       this.activeSessionId, this.rootExtras = const {}});
  final List<Machine> machines;
  final Map<String, List<CardioRecord>> cardio;
  final List<WorkoutSession> sessions;
  final Set<String> favorites;
  final String? activeSessionId;
  final Map<String, dynamic> rootExtras;

  /// Returns records for activities that no longer exist in this version.
  /// Callers must preserve these records in subsequent saves and backups.
  Map<String, List<CardioRecord>> applyTo(
      List<Machine> registered, List<CardioActivity> activities) {
    final knownIds = {for (final activity in activities) activity.id};
    final preserved = <String, List<CardioRecord>>{
      for (final entry in cardio.entries)
        if (!knownIds.contains(entry.key)) entry.key: List.of(entry.value),
    };
    registered
      ..clear()
      ..addAll(machines);
    for (final activity in activities) {
      activity.records
        ..clear()
        ..addAll(cardio[activity.id] ?? const <CardioRecord>[]);
    }
    return preserved;
  }
}
