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
      if (custom) {
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
      } else if (machine == null) {
        // Unknown exercise from a newer catalog: do not silently discard it.
        throw FormatException('Exercício não encontrado: $id');
      }
      machine.name = name.trim();
      machine.nameEn = custom ? name.trim() : machine.nameEn;
      machine.note = note;
      machine.records.addAll(entries.map((value) {
        if (value is! Map) throw const FormatException('Registro de treino inválido.');
        final r = Map<String, dynamic>.from(value);
        return WorkoutRecord(
          date: _date(r['date']),
          weight: _number(r['weight']) ?? 0,
          repetitions: _integer(r['repetitions']),
          durationSeconds: _integer(r['durationSeconds']),
        );
      }));
      newMachines.add(machine);
    }

    final newCardio = <String, List<CardioRecord>>{};
    for (final entry in savedCardio.entries) {
      if (entry.key is! String || entry.value is! List) {
        throw const FormatException('Atividade de cardio inválida.');
      }
      final records = <CardioRecord>[];
      final list = entry.value as List;
      totalRecords += list.length;
      if (totalRecords > 100000) throw const FormatException('Histórico muito grande.');
      for (final raw in list) {
        if (raw is! Map) throw const FormatException('Registro de cardio inválido.');
        final r = Map<String, dynamic>.from(raw);
        final seconds = _integer(r['seconds']);
        if (seconds == null || seconds < 0) throw const FormatException('Duração inválida.');
        records.add(CardioRecord(
          date: _date(r['date']),
          duration: Duration(seconds: seconds),
          distanceKm: _number(r['distanceKm']),
          heartRateBpm: _integer(r['heartRateBpm']),
          calories: _integer(r['calories']),
          inclinePercent: _number(r['inclinePercent']),
          resistanceLevel: _number(r['resistanceLevel']),
          notes: r['notes'] is String ? r['notes'] as String : '',
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

  static int? _integer(Object? value) {
    if (value == null) return null;
    if (value is! int) throw const FormatException('Número inteiro inválido.');
    return value;
  }
}

class WorkoutRestoredState {
  WorkoutRestoredState(this.machines, this.cardio);
  final List<Machine> machines;
  final Map<String, List<CardioRecord>> cardio;

  void applyTo(List<Machine> registered, List<CardioActivity> activities) {
    registered
      ..clear()
      ..addAll(machines);
    for (final activity in activities) {
      activity.records
        ..clear()
        ..addAll(cardio[activity.id] ?? const <CardioRecord>[]);
    }
  }
}
