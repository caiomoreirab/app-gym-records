import '../data/mock_data.dart';
import '../models/cardio_activity.dart';
import '../models/cardio_record.dart';
import '../models/machine.dart';
import '../models/muscle_group.dart';
import '../models/workout_record.dart';

/// Versioned, portable backup format. The database and backup use the same
/// serialization; only recorded user state is stored (no sample workout data).
class WorkoutSnapshotCodec {
  const WorkoutSnapshotCodec._();

  static const schemaVersion = 1;

  static Map<String, dynamic> encode({
    required List<Machine> machines,
    required List<CardioActivity> cardioActivities,
    Map<String, List<CardioRecord>> preservedCardio = const {},
  }) =>
      {
        'schemaVersion': schemaVersion,
        'machines': [
          for (final machine in machines)
            {
              'id': machine.id,
              'custom': machine.isCustom,
              'name': machine.name,
              'note': machine.note,
              'group': machine.group.name,
              'equipment': machine.equipment.name,
              'records': [
                for (final r in machine.records)
                  {
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
                },
            ],
        },
      };

  /// Parses into new objects before touching live state. A malformed backup
  /// therefore cannot partially erase the data currently in memory.
  static WorkoutRestoredState decode(Map<String, dynamic> input) {
    if (input['schemaVersion'] != schemaVersion) {
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
        );
      }
      machine.name = name.trim();
      machine.nameEn = custom ? name.trim() : machine.nameEn;
      machine.note = note;
      machine.records.addAll(entries.map((value) {
        if (value is! Map) throw const FormatException('Registro de treino inválido.');
        final r = Map<String, dynamic>.from(value);
        return WorkoutRecord(
          date: _date(r['date']),
          weight: _nonNegativeNumber(r['weight']) ?? 0,
          repetitions: _nonNegativeInteger(r['repetitions']),
          durationSeconds: _nonNegativeInteger(r['durationSeconds']),
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
        ));
      }
      newCardio[entry.key as String] = records;
    }
    return WorkoutRestoredState(newMachines, newCardio);
  }

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
  WorkoutRestoredState(this.machines, this.cardio);
  final List<Machine> machines;
  final Map<String, List<CardioRecord>> cardio;

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
