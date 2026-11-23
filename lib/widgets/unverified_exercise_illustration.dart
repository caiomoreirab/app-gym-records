import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../models/machine.dart';
import '../theme/app_theme.dart';

/// An intentionally equipment-correct vector placeholder, NOT a depiction
/// of the exercise's biomechanics. Never suggest a machine for a free weight.
class UnverifiedExerciseIllustration extends StatelessWidget {
  const UnverifiedExerciseIllustration({
    super.key, required this.machine, this.compact = false,
  });
  final Machine machine;
  final bool compact;

  /// Exercise-specific vector art for flat bench presses. The two
  /// implements are visibly different; machine press photos are never reused.
  /// Simplified schematic, not a medical or personal coaching instruction.
  static bool hasMovementSchematic(String id) =>
      id == 'barbell_bench_press' || id == 'dumbbell_bench_press';

  static String benchPressSchematic(String id) {
    final common =
      // Head, back, bent knees, floor and bench in side profile.
      '<path d="M9 82h82" stroke="#2E5772" stroke-width="2"/>'
      '<path d="M26 67H73M34 67v14M66 67v14" stroke="#32B9E6"/>'
      '<circle cx="25" cy="54" r="7"/>'
      '<path d="M32 55 67 55 77 64 83 78 93 78" stroke-width="4"/>'
      '<path d="M35 56 33 64 26 64" stroke-width="4"/>';
    if (id == 'barbell_bench_press') {
      return common +
        // A long bar with collars and two arms extending upward.
        '<path d="M16 18h72M21 11v14M26 11v14M78 11v14M83 11v14" stroke-width="4"/>'
        '<path d="M43 55 45 37 45 19M62 55 65 37 65 19" stroke-width="4"/>';
    }
    return common +
      // Two separate dumbbells at the top and independent arms.
      '<path d="M35 17v13M28 19v10M42 19v10M61 17v13M54 19v10M68 19v10" stroke-width="4"/>'
      '<path d="M40 55 35 32 35 24M62 55 61 32 61 24" stroke-width="4"/>';
  }

  String _symbol() => switch (machine.equipment) {
    EquipmentType.barbell =>
      '<path d="M10 48h80M20 37v22M28 32v32M72 32v32M80 37v22"/>',
    EquipmentType.dumbbell =>
      '<path d="M10 48h80M18 34v28M29 38v20M71 38v20M82 34v28"/>',
    EquipmentType.cable =>
      '<path d="M18 79V18h64v61M32 24h36M50 25v16M42 41h16M50 41v20M39 61h22"/>',
    EquipmentType.smith =>
      '<path d="M20 80V12M80 80V12M14 24h72M30 20v9M70 20v9M30 16v16M70 16v16"/>',
    EquipmentType.machine =>
      '<path d="M17 82V17h66v65M30 75V41h40v34M24 34h52"/>',
    EquipmentType.bodyweight =>
      '<circle cx="50" cy="21" r="9"/><path d="M50 33v31M28 48h44M50 64 33 83M50 64l17 19"/>',
    EquipmentType.kettlebell =>
      '<path d="M36 35v-9a14 14 0 0 1 28 0v9M25 61a25 25 0 0 1 50 0v9a25 25 0 0 1-50 0Z"/>',
    EquipmentType.band =>
      '<path d="M25 70c-29-27-3-50 25-21 28-29 54-6 25 21-15 13-35 13-50 0Z"/>',
    EquipmentType.other =>
      '<circle cx="50" cy="50" r="29"/><path d="M50 33v22m0 10h.1"/>',
  };

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final movementArt = hasMovementSchematic(machine.id);
    final title = movementArt
      ? (language == 'en' ? 'Movement illustration'
          : language == 'es' ? 'Ilustración del movimiento'
          : 'Ilustração do movimento')
      : (language == 'en' ? 'Equipment illustration'
          : language == 'es' ? 'Ilustración del equipo'
          : 'Ilustração do equipamento');
    final equipmentLabel = machine.equipment.label(
      Localizations.localeOf(context));
    return LayoutBuilder(builder: (context, constraints) {
      final tiny = compact || constraints.maxHeight < 100;
      return ColoredBox(
        color: AppTheme.surfaceNavy,
        child: Center(child: Padding(
          padding: EdgeInsets.all(tiny ? 6 : 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" '
              'viewBox="0 0 100 100" fill="none" stroke="#10B7F4" '
              'stroke-width="4" stroke-linecap="round" '
              'stroke-linejoin="round">${movementArt ? benchPressSchematic(machine.id) : _symbol()}</svg>',
              width: tiny ? 62 : 180,
              height: tiny ? 62 : 165,
              semanticsLabel: equipmentLabel,
            ),
            if (!tiny) ...[
              const SizedBox(height: 8),
              Text(movementArt ? machine.localizedName(Localizations.localeOf(context)) : equipmentLabel,
                maxLines: 2, textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.polarWhite,
                  fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.iceBlue,
                  fontSize: 11)),
            ],
          ]),
        )),
      );
    });
  }
}
