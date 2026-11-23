import '../models/machine.dart';
import '../models/muscle_group.dart';
import '../models/user_profile.dart';

abstract final class IllustrationAssets {
  static const String fallbackMachine = 'assets/illustrations/generic_machine.webp';

  static String onboarding(IllustrationStyle style) =>
      'assets/images/onboarding/illustration_${style.assetFolder}.webp';

  static String group(MuscleGroup group, IllustrationStyle style) =>
      'assets/images/groups/${style.assetFolder}/${group.assetKey}.webp';

  static String onboardingLogo() => 'assets/branding/icon_blue.png';

  /// Only explicitly curated catalog illustrations are safe to show as
  /// a depiction of the actual execution. The generic per-group fallbacks
  /// were machines reused for free weights (and are therefore misleading).
  static bool hasVerifiedExecution(Machine machine) =>
      !machine.isCustom &&
      machine.visualAssetId != null &&
      machine.visualAssetId!.isNotEmpty;

  /// Main exercise thumbnail. It must always represent execution.
  static String exercise(Machine machine, IllustrationStyle style) {
    final explicit = machine.visualAssetId;
    if (explicit != null && explicit.isNotEmpty) {
      return 'assets/images/exercises/${style.assetFolder}/$explicit.webp';
    }
    return executionFallback(machine, style);
  }

  /// Independent anatomical slide generated from the GymRecords front/rear
  /// anatomy source. NEVER derived by filtering an execution photo.
  /// Coverage for exact exercise-specific anatomy remains under review.
  static String muscle(Machine machine, IllustrationStyle style) {
    final assetId = _assetStem(machine);
    return 'assets/images/muscles/${style.assetFolder}/$assetId.webp';
  }

  static String _assetStem(Machine machine) {
    final explicit = machine.visualAssetId;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return switch (machine.group) {
      MuscleGroup.chest => _chestFallback(machine),
      MuscleGroup.back => _backFallback(machine),
      MuscleGroup.shoulders => _shoulderFallback(machine),
      MuscleGroup.biceps => _bicepsFallback(machine),
      MuscleGroup.triceps => _tricepsFallback(machine),
      MuscleGroup.legs => _legFallback(machine),
      MuscleGroup.abs => _absFallback(machine),
    };
  }

  /// Fallback visuals are diversified by exercise id/equipment so different
  /// exercises do not collapse into the exact same illustration.
  static String executionFallback(Machine machine, IllustrationStyle style) {
    final folder = style.assetFolder;
    final override = _executionOverride(machine);
    if (override != null) {
      return 'assets/images/exercises/$folder/$override.webp';
    }
    return 'assets/images/exercises/$folder/${_assetStem(machine)}.webp';
  }

  static String? _executionOverride(Machine machine) {
    switch (machine.id) {
      case 'dumbbell_bench_press':
      case 'decline_barbell_press':
      case 'decline_dumbbell_press':
        return 'chest_0';
      case 'incline_barbell_press':
      case 'incline_dumbbell_press':
      case 'incline_dumbbell_fly':
        return 'chest_2';
      case 'dumbbell_fly':
      case 'chest_dip':
      case 'push_up':
        return 'chest_1';
      case 'low_to_high_cable_fly':
      case 'high_to_low_cable_fly':
        return 'chest_3';

      case 'pull_up':
      case 'chin_up':
      case 'single_arm_cable_row':
        return 'back_0';
      case 'barbell_row':
      case 'one_arm_dumbbell_row':
      case 'chest_supported_dumbbell_row':
        return 'back_1';
      case 't_bar_row':
      case 'high_row_machine':
        return 'back_3';
      case 'straight_arm_pulldown':
      case 'barbell_shrug':
      case 'dumbbell_shrug':
      case 'back_extension':
      case 'deadlift':
        return 'back_4';

      case 'barbell_overhead_press':
      case 'dumbbell_shoulder_press':
      case 'smith_shoulder_press':
      case 'landmine_press':
        return 'shoulders_0';
      case 'dumbbell_lateral_raise':
      case 'cable_lateral_raise':
      case 'front_raise':
      case 'cable_front_raise':
        return 'shoulders_1';
      case 'face_pull':
      case 'upright_row':
      case 'cable_reverse_fly':
        return 'shoulders_2';

      case 'barbell_curl':
      case 'ez_bar_curl':
      case 'dumbbell_curl':
      case 'incline_dumbbell_curl':
      case 'preacher_curl_free':
      case 'concentration_curl':
      case 'spider_curl':
      case 'hammer_curl':
      case 'reverse_curl':
      case 'zottman_curl':
        return 'biceps_0';
      case 'bayesian_curl':
        return 'biceps_1';

      case 'rope_pushdown':
      case 'overhead_cable_extension':
      case 'cable_kickback_triceps':
        return 'triceps_0';
      case 'skull_crusher':
      case 'dumbbell_french_press':
      case 'close_grip_bench':
      case 'jm_press':
        return 'triceps_1';
      case 'bench_dip':
      case 'diamond_push_up':
      case 'dumbbell_kickback':
        return 'triceps_2';

      case 'horizontal_leg_press':
      case 'single_leg_press':
      case 'leg_press_calf':
        return 'leg_press_45';
      case 'pendulum_squat':
      case 'barbell_squat':
      case 'front_squat':
      case 'smith_squat':
      case 'goblet_squat':
      case 'bulgarian_split_squat':
      case 'walking_lunge':
      case 'sissy_squat':
      case 'step_up':
      case 'sumo_squat':
        return 'hack_squat';
      case 'romanian_deadlift':
      case 'stiff_leg_deadlift':
      case 'good_morning':
      case 'nordic_curl':
      case 'single_leg_curl':
        return 'lying_leg_curl';
      case 'hip_thrust':
      case 'glute_bridge':
      case 'smith_hip_thrust':
      case 'cable_kickback':
      case 'cable_hip_abduction':
        return 'hip_abductor';
      case 'cable_hip_adduction':
        return 'hip_adductor';
      case 'standing_calf':
      case 'smith_standing_calf':
        return 'seated_calf';

      case 'cable_crunch':
      case 'pallof_press':
      case 'cable_woodchop':
        return 'abs_cable';
      case 'crunch':
      case 'dead_bug':
      case 'russian_twist':
        return 'abs_crunch';
      case 'reverse_crunch':
      case 'hanging_knee_raise':
        return 'abs_reverse';
      case 'hanging_leg_raise':
      case 'captain_chair_raise':
        return 'abs_hanging';
      case 'plank':
      case 'side_plank':
      case 'ab_wheel':
        return 'abs_plank';
    }
    return null;
  }

  static String _chestFallback(Machine machine) =>
      machine.equipment == EquipmentType.cable ? 'chest_3' : 'chest_0';

  static String _backFallback(Machine machine) {
    if (machine.equipment == EquipmentType.cable) return 'back_0';
    if (machine.equipment == EquipmentType.machine) return 'back_1';
    return 'back_3';
  }

  static String _shoulderFallback(Machine machine) {
    if (machine.equipment == EquipmentType.cable) return 'shoulders_2';
    if (machine.equipment == EquipmentType.machine) return 'shoulders_0';
    return 'shoulders_1';
  }

  static String _bicepsFallback(Machine machine) =>
      machine.equipment == EquipmentType.cable ? 'biceps_1' : 'biceps_0';

  static String _tricepsFallback(Machine machine) {
    if (machine.equipment == EquipmentType.cable) return 'triceps_0';
    if (machine.equipment == EquipmentType.machine) return 'triceps_1';
    return 'triceps_2';
  }

  static String _absFallback(Machine machine) {
    if (machine.equipment == EquipmentType.machine) return 'abs_machine';
    if (machine.equipment == EquipmentType.cable) return 'abs_cable';
    if (machine.id.contains('hanging') || machine.id.contains('captain')) return 'abs_hanging';
    if (machine.id.contains('plank') || machine.id.contains('wheel')) return 'abs_plank';
    if (machine.id.contains('reverse')) return 'abs_reverse';
    return 'abs_crunch';
  }

  static String _legFallback(Machine machine) {
    final subgroup = machine.subgroup.toLowerCase();
    if (subgroup.contains('posterior') || subgroup.contains('isqui')) return 'lying_leg_curl';
    if (subgroup.contains('panturr')) return 'seated_calf';
    if (subgroup.contains('abdutor') || subgroup.contains('glúteos')) return 'hip_abductor';
    if (subgroup.contains('adutor')) return 'hip_adductor';
    if (machine.equipment == EquipmentType.machine && subgroup.contains('quadr')) return 'leg_extension';
    if (machine.equipment == EquipmentType.barbell ||
        machine.equipment == EquipmentType.dumbbell ||
        machine.equipment == EquipmentType.smith ||
        machine.equipment == EquipmentType.bodyweight) {
      return 'hack_squat';
    }
    return 'leg_press_45';
  }
}
