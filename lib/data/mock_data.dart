import '../models/cardio_activity.dart';
import '../models/cardio_record.dart';
import '../models/machine.dart';
import '../models/muscle_group.dart';
import '../models/workout_record.dart';

WorkoutRecord _record(int day, int month, double weight, [int? reps]) => WorkoutRecord(
      date: DateTime(2026, month, day, 18, 30),
      weight: weight,
      repetitions: reps,
    );

Machine _exercise(
  String id,
  String pt,
  String en,
  MuscleGroup group,
  EquipmentType equipment, {
  String subgroup = '',
  String subgroupEn = '',
  String? visualAssetId,
  List<String> aliases = const [],
}) =>
    Machine(
      id: id,
      name: pt,
      nameEn: en,
      group: group,
      equipment: equipment,
      subgroup: subgroup,
      subgroupEn: subgroupEn,
      visualAssetId: visualAssetId,
      aliases: aliases,
      imageAsset: 'assets/illustrations/generic_machine.webp',
    );

List<Machine> buildExerciseCatalog() => [
      // PEITO
      _exercise('chest_press_machine', 'Supino máquina', 'Machine chest press', MuscleGroup.chest, EquipmentType.machine, visualAssetId: 'chest_0'),
      _exercise('barbell_bench_press', 'Supino reto com barra', 'Barbell bench press', MuscleGroup.chest, EquipmentType.barbell, aliases: ['supino livre']),
      _exercise('dumbbell_bench_press', 'Supino reto com halteres', 'Dumbbell bench press', MuscleGroup.chest, EquipmentType.dumbbell),
      _exercise('incline_barbell_press', 'Supino inclinado com barra', 'Incline barbell press', MuscleGroup.chest, EquipmentType.barbell),
      _exercise('incline_dumbbell_press', 'Supino inclinado com halteres', 'Incline dumbbell press', MuscleGroup.chest, EquipmentType.dumbbell),
      _exercise('incline_chest_press_machine', 'Supino inclinado máquina', 'Incline chest press machine', MuscleGroup.chest, EquipmentType.machine, visualAssetId: 'chest_2'),
      _exercise('smith_bench_press', 'Supino reto no Smith', 'Smith machine bench press', MuscleGroup.chest, EquipmentType.smith),
      _exercise('pec_deck', 'Voador (peck deck)', 'Pec deck fly', MuscleGroup.chest, EquipmentType.machine, visualAssetId: 'chest_1'),
      _exercise('cable_crossover', 'Crossover na polia', 'Cable crossover', MuscleGroup.chest, EquipmentType.cable, visualAssetId: 'chest_3'),
      _exercise('push_up', 'Flexão de braços', 'Push-up', MuscleGroup.chest, EquipmentType.bodyweight),
      _exercise('chest_dip', 'Paralelas para peito', 'Chest dip', MuscleGroup.chest, EquipmentType.bodyweight),
      _exercise('decline_barbell_press', 'Supino declinado com barra', 'Decline barbell press', MuscleGroup.chest, EquipmentType.barbell),
      _exercise('decline_dumbbell_press', 'Supino declinado com halteres', 'Decline dumbbell press', MuscleGroup.chest, EquipmentType.dumbbell),
      _exercise('dumbbell_fly', 'Crucifixo com halteres', 'Dumbbell fly', MuscleGroup.chest, EquipmentType.dumbbell),
      _exercise('incline_dumbbell_fly', 'Crucifixo inclinado com halteres', 'Incline dumbbell fly', MuscleGroup.chest, EquipmentType.dumbbell),
      _exercise('low_to_high_cable_fly', 'Crossover baixo para cima', 'Low-to-high cable fly', MuscleGroup.chest, EquipmentType.cable),
      _exercise('high_to_low_cable_fly', 'Crossover alto para baixo', 'High-to-low cable fly', MuscleGroup.chest, EquipmentType.cable),

      // COSTAS
      _exercise('lat_pulldown', 'Puxada frontal', 'Lat pulldown', MuscleGroup.back, EquipmentType.cable, visualAssetId: 'back_0'),
      _exercise('pull_up', 'Barra fixa pronada', 'Pull-up', MuscleGroup.back, EquipmentType.bodyweight),
      _exercise('chin_up', 'Barra fixa supinada', 'Chin-up', MuscleGroup.back, EquipmentType.bodyweight),
      _exercise('seated_row_machine', 'Remada sentada máquina', 'Seated row machine', MuscleGroup.back, EquipmentType.machine, visualAssetId: 'back_1'),
      _exercise('low_cable_row', 'Remada baixa na polia', 'Low cable row', MuscleGroup.back, EquipmentType.cable, visualAssetId: 'back_2'),
      _exercise('barbell_row', 'Remada curvada com barra', 'Barbell bent-over row', MuscleGroup.back, EquipmentType.barbell),
      _exercise('one_arm_dumbbell_row', 'Remada unilateral com halter', 'One-arm dumbbell row', MuscleGroup.back, EquipmentType.dumbbell),
      _exercise('t_bar_row', 'Remada T-bar', 'T-bar row', MuscleGroup.back, EquipmentType.barbell),
      _exercise('plate_loaded_row', 'Remada articulada', 'Plate-loaded row', MuscleGroup.back, EquipmentType.machine, visualAssetId: 'back_3'),
      _exercise('pullover_machine', 'Pullover máquina', 'Pullover machine', MuscleGroup.back, EquipmentType.machine, visualAssetId: 'back_4'),
      _exercise('straight_arm_pulldown', 'Pulldown com braços estendidos', 'Straight-arm pulldown', MuscleGroup.back, EquipmentType.cable),
      _exercise('deadlift', 'Levantamento terra', 'Deadlift', MuscleGroup.back, EquipmentType.barbell, subgroup: 'Cadeia posterior', subgroupEn: 'Posterior chain'),
      _exercise('chest_supported_dumbbell_row', 'Remada apoiada com halteres', 'Chest-supported dumbbell row', MuscleGroup.back, EquipmentType.dumbbell),
      _exercise('high_row_machine', 'Remada alta articulada', 'High row machine', MuscleGroup.back, EquipmentType.machine),
      _exercise('single_arm_cable_row', 'Remada unilateral na polia', 'Single-arm cable row', MuscleGroup.back, EquipmentType.cable),
      _exercise('barbell_shrug', 'Encolhimento com barra', 'Barbell shrug', MuscleGroup.back, EquipmentType.barbell, subgroup: 'Trapézio', subgroupEn: 'Traps'),
      _exercise('dumbbell_shrug', 'Encolhimento com halteres', 'Dumbbell shrug', MuscleGroup.back, EquipmentType.dumbbell, subgroup: 'Trapézio', subgroupEn: 'Traps'),
      _exercise('back_extension', 'Extensão lombar', 'Back extension', MuscleGroup.back, EquipmentType.bodyweight, subgroup: 'Lombar', subgroupEn: 'Lower back'),

      // OMBROS
      _exercise('shoulder_press_machine', 'Desenvolvimento máquina', 'Machine shoulder press', MuscleGroup.shoulders, EquipmentType.machine, visualAssetId: 'shoulders_0'),
      _exercise('barbell_overhead_press', 'Desenvolvimento com barra', 'Barbell overhead press', MuscleGroup.shoulders, EquipmentType.barbell),
      _exercise('dumbbell_shoulder_press', 'Desenvolvimento com halteres', 'Dumbbell shoulder press', MuscleGroup.shoulders, EquipmentType.dumbbell),
      _exercise('arnold_press', 'Desenvolvimento Arnold', 'Arnold press', MuscleGroup.shoulders, EquipmentType.dumbbell),
      _exercise('lateral_raise_machine', 'Elevação lateral máquina', 'Machine lateral raise', MuscleGroup.shoulders, EquipmentType.machine, visualAssetId: 'shoulders_1'),
      _exercise('dumbbell_lateral_raise', 'Elevação lateral com halteres', 'Dumbbell lateral raise', MuscleGroup.shoulders, EquipmentType.dumbbell),
      _exercise('cable_lateral_raise', 'Elevação lateral na polia', 'Cable lateral raise', MuscleGroup.shoulders, EquipmentType.cable),
      _exercise('front_raise', 'Elevação frontal', 'Front raise', MuscleGroup.shoulders, EquipmentType.dumbbell),
      _exercise('reverse_fly_machine', 'Voador invertido', 'Reverse fly machine', MuscleGroup.shoulders, EquipmentType.machine, visualAssetId: 'shoulders_2'),
      _exercise('face_pull', 'Face pull', 'Face pull', MuscleGroup.shoulders, EquipmentType.cable),
      _exercise('upright_row', 'Remada alta', 'Upright row', MuscleGroup.shoulders, EquipmentType.barbell),
      _exercise('smith_shoulder_press', 'Desenvolvimento no Smith', 'Smith machine shoulder press', MuscleGroup.shoulders, EquipmentType.smith),
      _exercise('cable_front_raise', 'Elevação frontal na polia', 'Cable front raise', MuscleGroup.shoulders, EquipmentType.cable),
      _exercise('cable_reverse_fly', 'Crucifixo inverso na polia', 'Cable reverse fly', MuscleGroup.shoulders, EquipmentType.cable),
      _exercise('landmine_press', 'Landmine press', 'Landmine press', MuscleGroup.shoulders, EquipmentType.barbell),

      // BÍCEPS
      _exercise('preacher_curl_machine', 'Rosca Scott máquina', 'Machine preacher curl', MuscleGroup.biceps, EquipmentType.machine, visualAssetId: 'biceps_0'),
      _exercise('barbell_curl', 'Rosca direta com barra', 'Barbell curl', MuscleGroup.biceps, EquipmentType.barbell),
      _exercise('ez_bar_curl', 'Rosca direta com barra W', 'EZ-bar curl', MuscleGroup.biceps, EquipmentType.barbell),
      _exercise('dumbbell_curl', 'Rosca alternada com halteres', 'Dumbbell curl', MuscleGroup.biceps, EquipmentType.dumbbell),
      _exercise('incline_dumbbell_curl', 'Rosca inclinada com halteres', 'Incline dumbbell curl', MuscleGroup.biceps, EquipmentType.dumbbell),
      _exercise('hammer_curl', 'Rosca martelo', 'Hammer curl', MuscleGroup.biceps, EquipmentType.dumbbell),
      _exercise('cable_curl', 'Rosca na polia', 'Cable curl', MuscleGroup.biceps, EquipmentType.cable, visualAssetId: 'biceps_1'),
      _exercise('preacher_curl_free', 'Rosca Scott livre', 'Free-weight preacher curl', MuscleGroup.biceps, EquipmentType.barbell),
      _exercise('concentration_curl', 'Rosca concentrada', 'Concentration curl', MuscleGroup.biceps, EquipmentType.dumbbell),
      _exercise('spider_curl', 'Rosca spider', 'Spider curl', MuscleGroup.biceps, EquipmentType.dumbbell),
      _exercise('bayesian_curl', 'Rosca Bayesian na polia', 'Bayesian cable curl', MuscleGroup.biceps, EquipmentType.cable),
      _exercise('reverse_curl', 'Rosca inversa', 'Reverse curl', MuscleGroup.biceps, EquipmentType.barbell),
      _exercise('zottman_curl', 'Rosca Zottman', 'Zottman curl', MuscleGroup.biceps, EquipmentType.dumbbell),

      // TRÍCEPS
      _exercise('triceps_pushdown', 'Tríceps na polia', 'Triceps pushdown', MuscleGroup.triceps, EquipmentType.cable, visualAssetId: 'triceps_0'),
      _exercise('rope_pushdown', 'Tríceps corda', 'Rope pushdown', MuscleGroup.triceps, EquipmentType.cable),
      _exercise('overhead_cable_extension', 'Tríceps francês na polia', 'Overhead cable extension', MuscleGroup.triceps, EquipmentType.cable),
      _exercise('skull_crusher', 'Tríceps testa com barra', 'Skull crusher', MuscleGroup.triceps, EquipmentType.barbell),
      _exercise('dumbbell_french_press', 'Tríceps francês com halter', 'Dumbbell overhead triceps extension', MuscleGroup.triceps, EquipmentType.dumbbell),
      _exercise('close_grip_bench', 'Supino fechado', 'Close-grip bench press', MuscleGroup.triceps, EquipmentType.barbell),
      _exercise('seated_triceps_machine', 'Extensão de tríceps sentado', 'Seated triceps extension machine', MuscleGroup.triceps, EquipmentType.machine, visualAssetId: 'triceps_1'),
      _exercise('assisted_dip', 'Mergulho em máquina', 'Assisted dip machine', MuscleGroup.triceps, EquipmentType.machine, visualAssetId: 'triceps_2'),
      _exercise('bench_dip', 'Mergulho no banco', 'Bench dip', MuscleGroup.triceps, EquipmentType.bodyweight),
      _exercise('dumbbell_kickback', 'Coice de tríceps com halter', 'Dumbbell triceps kickback', MuscleGroup.triceps, EquipmentType.dumbbell),
      _exercise('cable_kickback_triceps', 'Coice de tríceps na polia', 'Cable triceps kickback', MuscleGroup.triceps, EquipmentType.cable),
      _exercise('jm_press', 'JM press', 'JM press', MuscleGroup.triceps, EquipmentType.barbell),
      _exercise('diamond_push_up', 'Flexão diamante', 'Diamond push-up', MuscleGroup.triceps, EquipmentType.bodyweight),

      // PERNAS — subgrupos mantêm a Home limpa, mas permitem filtro técnico.
      _exercise('leg_press_45', 'Leg press 45°', '45° leg press', MuscleGroup.legs, EquipmentType.machine, subgroup: 'Quadríceps', subgroupEn: 'Quadriceps', visualAssetId: 'leg_press_45'),
      _exercise('leg_extension', 'Cadeira extensora', 'Leg extension', MuscleGroup.legs, EquipmentType.machine, subgroup: 'Quadríceps', subgroupEn: 'Quadriceps', visualAssetId: 'leg_extension'),
      _exercise('hack_squat', 'Agachamento hack', 'Hack squat', MuscleGroup.legs, EquipmentType.machine, subgroup: 'Quadríceps', subgroupEn: 'Quadriceps', visualAssetId: 'hack_squat'),
      _exercise('barbell_squat', 'Agachamento livre', 'Barbell back squat', MuscleGroup.legs, EquipmentType.barbell, subgroup: 'Quadríceps', subgroupEn: 'Quadriceps'),
      _exercise('front_squat', 'Agachamento frontal', 'Front squat', MuscleGroup.legs, EquipmentType.barbell, subgroup: 'Quadríceps', subgroupEn: 'Quadriceps'),
      _exercise('smith_squat', 'Agachamento no Smith', 'Smith machine squat', MuscleGroup.legs, EquipmentType.smith, subgroup: 'Quadríceps', subgroupEn: 'Quadriceps'),
      _exercise('goblet_squat', 'Agachamento goblet', 'Goblet squat', MuscleGroup.legs, EquipmentType.dumbbell, subgroup: 'Quadríceps', subgroupEn: 'Quadriceps'),
      _exercise('bulgarian_split_squat', 'Agachamento búlgaro', 'Bulgarian split squat', MuscleGroup.legs, EquipmentType.dumbbell, subgroup: 'Quadríceps / Glúteos', subgroupEn: 'Quadriceps / Glutes'),
      _exercise('walking_lunge', 'Avanço / passada', 'Walking lunge', MuscleGroup.legs, EquipmentType.dumbbell, subgroup: 'Quadríceps / Glúteos', subgroupEn: 'Quadriceps / Glutes'),
      _exercise('lying_leg_curl', 'Mesa flexora', 'Lying leg curl', MuscleGroup.legs, EquipmentType.machine, subgroup: 'Posterior de coxa', subgroupEn: 'Hamstrings', visualAssetId: 'lying_leg_curl'),
      _exercise('seated_leg_curl', 'Cadeira flexora', 'Seated leg curl', MuscleGroup.legs, EquipmentType.machine, subgroup: 'Posterior de coxa', subgroupEn: 'Hamstrings', visualAssetId: 'seated_leg_curl'),
      _exercise('romanian_deadlift', 'Levantamento terra romeno', 'Romanian deadlift', MuscleGroup.legs, EquipmentType.barbell, subgroup: 'Posterior de coxa', subgroupEn: 'Hamstrings'),
      _exercise('stiff_leg_deadlift', 'Stiff', 'Stiff-leg deadlift', MuscleGroup.legs, EquipmentType.barbell, subgroup: 'Posterior de coxa', subgroupEn: 'Hamstrings'),
      _exercise('hip_thrust', 'Hip thrust', 'Hip thrust', MuscleGroup.legs, EquipmentType.barbell, subgroup: 'Glúteos', subgroupEn: 'Glutes'),
      _exercise('glute_bridge', 'Ponte de glúteos', 'Glute bridge', MuscleGroup.legs, EquipmentType.bodyweight, subgroup: 'Glúteos', subgroupEn: 'Glutes'),
      _exercise('hip_abductor', 'Cadeira abdutora', 'Hip abductor machine', MuscleGroup.legs, EquipmentType.machine, subgroup: 'Glúteos / Abdutores', subgroupEn: 'Glutes / Abductors', visualAssetId: 'hip_abductor'),
      _exercise('hip_adductor', 'Cadeira adutora', 'Hip adductor machine', MuscleGroup.legs, EquipmentType.machine, subgroup: 'Adutores', subgroupEn: 'Adductors', visualAssetId: 'hip_adductor'),
      _exercise('cable_kickback', 'Coice na polia', 'Cable glute kickback', MuscleGroup.legs, EquipmentType.cable, subgroup: 'Glúteos', subgroupEn: 'Glutes'),
      _exercise('seated_calf', 'Panturrilha sentado', 'Seated calf raise', MuscleGroup.legs, EquipmentType.machine, subgroup: 'Panturrilhas', subgroupEn: 'Calves', visualAssetId: 'seated_calf'),
      _exercise('standing_calf', 'Panturrilha em pé', 'Standing calf raise', MuscleGroup.legs, EquipmentType.machine, subgroup: 'Panturrilhas', subgroupEn: 'Calves'),
      _exercise('horizontal_leg_press', 'Leg press horizontal', 'Horizontal leg press', MuscleGroup.legs, EquipmentType.machine, subgroup: 'Quadríceps', subgroupEn: 'Quadriceps'),
      _exercise('pendulum_squat', 'Agachamento pêndulo', 'Pendulum squat', MuscleGroup.legs, EquipmentType.machine, subgroup: 'Quadríceps', subgroupEn: 'Quadriceps'),
      _exercise('single_leg_press', 'Leg press unilateral', 'Single-leg press', MuscleGroup.legs, EquipmentType.machine, subgroup: 'Quadríceps', subgroupEn: 'Quadriceps'),
      _exercise('sissy_squat', 'Sissy squat', 'Sissy squat', MuscleGroup.legs, EquipmentType.bodyweight, subgroup: 'Quadríceps', subgroupEn: 'Quadriceps'),
      _exercise('step_up', 'Step-up no banco', 'Step-up', MuscleGroup.legs, EquipmentType.dumbbell, subgroup: 'Quadríceps / Glúteos', subgroupEn: 'Quadriceps / Glutes'),
      _exercise('good_morning', 'Good morning', 'Good morning', MuscleGroup.legs, EquipmentType.barbell, subgroup: 'Posterior de coxa', subgroupEn: 'Hamstrings'),
      _exercise('single_leg_curl', 'Flexora unilateral', 'Single-leg curl', MuscleGroup.legs, EquipmentType.machine, subgroup: 'Posterior de coxa', subgroupEn: 'Hamstrings'),
      _exercise('nordic_curl', 'Nordic curl', 'Nordic hamstring curl', MuscleGroup.legs, EquipmentType.bodyweight, subgroup: 'Posterior de coxa', subgroupEn: 'Hamstrings'),
      _exercise('sumo_squat', 'Agachamento sumô', 'Sumo squat', MuscleGroup.legs, EquipmentType.dumbbell, subgroup: 'Glúteos / Adutores', subgroupEn: 'Glutes / Adductors'),
      _exercise('smith_hip_thrust', 'Hip thrust no Smith', 'Smith machine hip thrust', MuscleGroup.legs, EquipmentType.smith, subgroup: 'Glúteos', subgroupEn: 'Glutes'),
      _exercise('cable_hip_abduction', 'Abdução de quadril na polia', 'Cable hip abduction', MuscleGroup.legs, EquipmentType.cable, subgroup: 'Glúteos / Abdutores', subgroupEn: 'Glutes / Abductors'),
      _exercise('cable_hip_adduction', 'Adução de quadril na polia', 'Cable hip adduction', MuscleGroup.legs, EquipmentType.cable, subgroup: 'Adutores', subgroupEn: 'Adductors'),
      _exercise('smith_standing_calf', 'Panturrilha em pé no Smith', 'Smith standing calf raise', MuscleGroup.legs, EquipmentType.smith, subgroup: 'Panturrilhas', subgroupEn: 'Calves'),
      _exercise('leg_press_calf', 'Panturrilha no leg press', 'Leg press calf raise', MuscleGroup.legs, EquipmentType.machine, subgroup: 'Panturrilhas', subgroupEn: 'Calves'),

      // CORE / ABDÔMEN
      _exercise('ab_machine', 'Abdominal máquina', 'Abdominal crunch machine', MuscleGroup.abs, EquipmentType.machine, visualAssetId: 'abs_machine'),
      _exercise('cable_crunch', 'Abdominal na polia', 'Cable crunch', MuscleGroup.abs, EquipmentType.cable, visualAssetId: 'abs_cable'),
      _exercise('crunch', 'Abdominal crunch', 'Crunch', MuscleGroup.abs, EquipmentType.bodyweight, visualAssetId: 'abs_crunch'),
      _exercise('reverse_crunch', 'Abdominal reverso', 'Reverse crunch', MuscleGroup.abs, EquipmentType.bodyweight, visualAssetId: 'abs_reverse'),
      _exercise('hanging_leg_raise', 'Elevação de pernas suspenso', 'Hanging leg raise', MuscleGroup.abs, EquipmentType.bodyweight, visualAssetId: 'abs_hanging'),
      _exercise('captain_chair_raise', 'Elevação de pernas na paralela', 'Captain chair leg raise', MuscleGroup.abs, EquipmentType.bodyweight, visualAssetId: 'abs_hanging'),
      _exercise('plank', 'Prancha', 'Plank', MuscleGroup.abs, EquipmentType.bodyweight, visualAssetId: 'abs_plank'),
      _exercise('side_plank', 'Prancha lateral', 'Side plank', MuscleGroup.abs, EquipmentType.bodyweight, visualAssetId: 'abs_plank'),
      _exercise('ab_wheel', 'Roda abdominal', 'Ab wheel rollout', MuscleGroup.abs, EquipmentType.other, visualAssetId: 'abs_plank'),
      _exercise('russian_twist', 'Rotação russa', 'Russian twist', MuscleGroup.abs, EquipmentType.bodyweight, visualAssetId: 'abs_crunch'),
      _exercise('hanging_knee_raise', 'Elevação de joelhos suspenso', 'Hanging knee raise', MuscleGroup.abs, EquipmentType.bodyweight, visualAssetId: 'abs_reverse'),
      _exercise('dead_bug', 'Dead bug', 'Dead bug', MuscleGroup.abs, EquipmentType.bodyweight, visualAssetId: 'abs_crunch'),
      _exercise('pallof_press', 'Pallof press', 'Pallof press', MuscleGroup.abs, EquipmentType.cable, visualAssetId: 'abs_cable'),
      _exercise('cable_woodchop', 'Woodchop na polia', 'Cable woodchop', MuscleGroup.abs, EquipmentType.cable, visualAssetId: 'abs_cable'),
    ];

Machine _withRecords(Machine source, List<WorkoutRecord> records, {String note = ''}) => Machine(
      id: source.id,
      name: source.name,
      nameEn: source.nameEn,
      group: source.group,
      equipment: source.equipment,
      subgroup: source.subgroup,
      subgroupEn: source.subgroupEn,
      visualAssetId: source.visualAssetId,
      aliases: source.aliases,
      imageAsset: source.imageAsset,
      note: note,
      records: records,
    );

List<Machine> buildInitialMachines() {
  final catalog = {for (final e in buildExerciseCatalog()) e.id: e};
  return [
    _withRecords(catalog['leg_press_45']!, [
      _record(12, 11, 120, 10), _record(5, 11, 115, 10), _record(29, 10, 110, 12),
      _record(22, 10, 110, 10), _record(15, 10, 100),
    ], note: 'Banco na posição 4, pés no centro da plataforma'),
    _withRecords(catalog['leg_extension']!, [_record(10, 11, 65, 10)]),
    _withRecords(catalog['lying_leg_curl']!, [_record(10, 11, 50, 10)]),
    _withRecords(catalog['hack_squat']!, [_record(5, 11, 90, 8)]),
    _withRecords(catalog['hip_abductor']!, [_record(3, 11, 70, 12)]),
    _withRecords(catalog['hip_adductor']!, []),
    _withRecords(catalog['chest_press_machine']!, [_record(8, 11, 82.5, 10)]),
    _withRecords(catalog['pec_deck']!, [_record(7, 11, 55, 10)]),
    _withRecords(catalog['incline_chest_press_machine']!, [_record(6, 11, 70, 10)]),
    _withRecords(catalog['cable_crossover']!, [_record(5, 11, 32.5, 12)]),
    _withRecords(catalog['lat_pulldown']!, [_record(8, 11, 70, 10)]),
    _withRecords(catalog['seated_row_machine']!, [_record(7, 11, 75, 10)]),
    _withRecords(catalog['low_cable_row']!, [_record(6, 11, 62.5, 10)]),
    _withRecords(catalog['plate_loaded_row']!, [_record(5, 11, 80, 8)]),
    _withRecords(catalog['pullover_machine']!, [_record(4, 11, 55, 10)]),
    _withRecords(catalog['shoulder_press_machine']!, [_record(8, 11, 50, 10)]),
    _withRecords(catalog['lateral_raise_machine']!, [_record(7, 11, 30, 12)]),
    _withRecords(catalog['reverse_fly_machine']!, [_record(6, 11, 42.5, 10)]),
    _withRecords(catalog['preacher_curl_machine']!, [_record(8, 11, 35, 10)]),
    _withRecords(catalog['cable_curl']!, [_record(7, 11, 27.5, 12)]),
    _withRecords(catalog['triceps_pushdown']!, [_record(8, 11, 40, 10)]),
    _withRecords(catalog['seated_triceps_machine']!, [_record(7, 11, 45, 10)]),
    _withRecords(catalog['assisted_dip']!, [_record(6, 11, 60, 10)]),
    _withRecords(catalog['ab_machine']!, [_record(8, 11, 55, 12)]),
  ];
}

List<Machine> buildCatalogFor(MuscleGroup group) =>
    buildExerciseCatalog().where((exercise) => exercise.group == group).toList(growable: false);

List<CardioActivity> buildCardioActivities() => [
      CardioActivity(id: 'outdoor_run', name: 'Corrida ao ar livre', nameEn: 'Outdoor run', nameEs: 'Carrera al aire libre', kind: CardioKind.outdoorRun),
      CardioActivity(id: 'treadmill', name: 'Esteira', nameEn: 'Treadmill', nameEs: 'Cinta de correr', kind: CardioKind.treadmill, supportsIncline: true),
      CardioActivity(id: 'walk', name: 'Caminhada', nameEn: 'Walking', nameEs: 'Caminata', kind: CardioKind.walk),
      CardioActivity(id: 'cycling', name: 'Ciclismo', nameEn: 'Cycling', nameEs: 'Ciclismo', kind: CardioKind.cycling, supportsPace: false),
      CardioActivity(id: 'stationary_bike', name: 'Bicicleta ergométrica', nameEn: 'Stationary bike', nameEs: 'Bicicleta estática', kind: CardioKind.stationaryBike, supportsPace: false, supportsResistance: true),
      CardioActivity(id: 'elliptical', name: 'Elíptico', nameEn: 'Elliptical', nameEs: 'Elíptica', kind: CardioKind.elliptical, supportsDistance: true, supportsPace: false, supportsResistance: true),
      CardioActivity(id: 'stair_climber', name: 'Escada / simulador de escada', nameEn: 'Stair climber', nameEs: 'Escaladora', kind: CardioKind.stairClimber, supportsDistance: false, supportsPace: false, supportsResistance: true),
      CardioActivity(id: 'rowing', name: 'Remo ergométrico', nameEn: 'Indoor rowing', nameEs: 'Remo indoor', kind: CardioKind.rowing, supportsDistance: true, supportsPace: true, paceDistanceKm: 0.5, supportsResistance: true),
      CardioActivity(id: 'jump_rope', name: 'Corda', nameEn: 'Jump rope', nameEs: 'Saltar la cuerda', kind: CardioKind.jumpRope, supportsDistance: false, supportsPace: false),
    ];

List<CardioActivity> buildInitialCardioActivities() {
  final activities = buildCardioActivities();
  final run = activities.firstWhere((a) => a.id == 'outdoor_run');
  run.records.addAll([
    CardioRecord(date: DateTime(2026, 11, 10), duration: const Duration(minutes: 27, seconds: 34), distanceKm: 5.0, heartRateBpm: 154),
    CardioRecord(date: DateTime(2026, 11, 3), duration: const Duration(minutes: 29, seconds: 10), distanceKm: 5.0, heartRateBpm: 150),
  ]);
  return activities;
}
