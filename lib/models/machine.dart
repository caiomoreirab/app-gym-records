import 'dart:ui';

import 'muscle_group.dart';
import 'workout_record.dart';

enum EquipmentType {
  machine,
  barbell,
  dumbbell,
  cable,
  smith,
  bodyweight,
  kettlebell,
  band,
  other;

  String label(Locale locale) {
    final lang = locale.languageCode;
    return switch (this) {
      EquipmentType.machine => lang == 'en' ? 'Machine' : lang == 'es' ? 'Máquina' : 'Máquina',
      EquipmentType.barbell => lang == 'en' ? 'Barbell' : lang == 'es' ? 'Barra' : 'Barra',
      EquipmentType.dumbbell => lang == 'en' ? 'Dumbbells' : lang == 'es' ? 'Mancuernas' : 'Halteres',
      EquipmentType.cable => lang == 'en' ? 'Cable' : lang == 'es' ? 'Cable / Polea' : 'Cabo / Polia',
      EquipmentType.smith => 'Smith',
      EquipmentType.bodyweight => lang == 'en' ? 'Bodyweight' : lang == 'es' ? 'Peso corporal' : 'Peso corporal',
      EquipmentType.kettlebell => 'Kettlebell',
      EquipmentType.band => lang == 'en' ? 'Resistance band' : lang == 'es' ? 'Banda elástica' : 'Elástico',
      EquipmentType.other => lang == 'en' ? 'Other' : lang == 'es' ? 'Otro' : 'Outro',
    };
  }
}

class Machine {
  Machine({
    required this.id,
    required this.name,
    required this.group,
    required this.imageAsset,
    this.nameEn,
    this.visualAssetId,
    this.equipment = EquipmentType.machine,
    this.subgroup = '',
    this.subgroupEn = '',
    this.aliases = const <String>[],
    this.note = '',
    List<WorkoutRecord>? records,
    this.isCustom = false,
  }) : records = records ?? <WorkoutRecord>[];

  final String id;
  String name;
  String? nameEn;
  final MuscleGroup group;
  final String imageAsset;
  final String? visualAssetId;
  final EquipmentType equipment;
  final String subgroup;
  final String subgroupEn;
  final List<String> aliases;
  String note;
  final List<WorkoutRecord> records;
  final bool isCustom;

  String localizedName(Locale locale) {
    if (locale.languageCode == 'en' && (nameEn?.trim().isNotEmpty ?? false)) {
      return nameEn!;
    }
    return name;
  }

  String localizedSubgroup(Locale locale) {
    if (locale.languageCode == 'en' && subgroupEn.isNotEmpty) return subgroupEn;
    return subgroup;
  }

  bool get isFreeWeight => switch (equipment) {
        EquipmentType.barbell ||
        EquipmentType.dumbbell ||
        EquipmentType.bodyweight ||
        EquipmentType.kettlebell ||
        EquipmentType.band => true,
        _ => false,
      };

  bool get prefersBodyMetrics => switch (id) {
        'crunch' ||
        'reverse_crunch' ||
        'hanging_leg_raise' ||
        'captain_chair_raise' ||
        'plank' ||
        'side_plank' ||
        'ab_wheel' ||
        'russian_twist' ||
        'hanging_knee_raise' ||
        'dead_bug' ||
        'push_up' ||
        'bench_dip' ||
        'diamond_push_up' ||
        'pull_up' ||
        'chin_up' ||
        'chest_dip' ||
        'walking_lunge' ||
        'step_up' ||
        'bulgarian_split_squat' ||
        'sissy_squat' => true,
        _ => equipment == EquipmentType.bodyweight,
      };

  bool get supportsWeight => !prefersBodyMetrics || records.any((record) => record.hasWeight);
  bool get supportsRepetitions => true;
  bool get supportsDuration => prefersBodyMetrics;


  double get recordWeight {
    final values = records.where((record) => record.hasWeight && !record.isWarmup).map((record) => record.weight).toList();
    if (values.isEmpty) return 0;
    return values.reduce((current, next) => next > current ? next : current);
  }

  int get bestRepetitions {
    final values = records.where((record) => record.hasRepetitions && !record.isWarmup).map((record) => record.repetitions!).toList();
    if (values.isEmpty) return 0;
    values.sort();
    return values.last;
  }

  int get bestDurationSeconds {
    final values = records.where((record) => record.hasDuration).map((record) => record.durationSeconds!).toList();
    if (values.isEmpty) return 0;
    values.sort();
    return values.last;
  }

  WorkoutRecord? get latestRecord {
    if (records.isEmpty) return null;
    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first;
  }
}
