import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/machine.dart';
import '../models/muscle_group.dart';
import '../services/illustration_assets.dart';
import '../models/user_profile.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'two_view_image_pager.dart';
import 'unverified_exercise_illustration.dart';

class AdaptiveExerciseImage extends StatelessWidget {
  const AdaptiveExerciseImage({super.key, required this.machine, this.fit = BoxFit.contain, this.width, this.height});
  final Machine machine;
  final BoxFit fit;
  final double? width;
  final double? height;
  @override
  Widget build(BuildContext context) {
    final style = AppScope.of(context).effectiveIllustrationStyle;
    final curated = IllustrationAssets.curatedMovementSvg(machine, style);
    if (curated != null) {
      return SvgPicture.asset(curated, width: width, height: height,
        fit: BoxFit.contain);
    }
    if (!IllustrationAssets.hasVerifiedExecution(machine)) {
      return SizedBox(
        width: width, height: height,
        child: UnverifiedExerciseIllustration(machine: machine,
          compact: (height ?? 250) < 100),
      );
    }
    return Image.asset(
      IllustrationAssets.exercise(machine, style),
      width: width,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => const ColoredBox(color: AppTheme.surfaceNavy, child: Center(child: Icon(Icons.image_not_supported_outlined))),
    );
  }
}

class AdaptiveGroupImage extends StatelessWidget {
  const AdaptiveGroupImage({super.key, required this.group, this.fit = BoxFit.cover, this.width, this.height, this.alignment = Alignment.center});
  final MuscleGroup group;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final style = AppScope.of(context).effectiveIllustrationStyle;
    return Image.asset(
      IllustrationAssets.group(group, style),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, __, ___) => const ColoredBox(color: AppTheme.surfaceNavy, child: Center(child: Icon(Icons.accessibility_new_rounded, size: 42))),
    );
  }
}

class ExerciseVisualPager extends StatelessWidget {
  const ExerciseVisualPager({super.key, required this.machine, required this.height, this.width, this.fit = BoxFit.cover, this.compact = false, this.showLabel = false});
  final Machine machine;
  final double height;
  final double? width;
  final BoxFit fit;
  final bool compact;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final style = AppScope.of(context).effectiveIllustrationStyle;
    final verified = IllustrationAssets.hasVerifiedExecution(machine);
    final curated = IllustrationAssets.curatedMovementSvg(machine, style);
    return TwoViewImagePager(
      key: ValueKey('pager:${machine.id}:${style.assetFolder}'),
      visualSetKey: '${machine.id}:${style.assetFolder}',
      executionPath: IllustrationAssets.exercise(machine, style),
      musclePath: verified
          ? IllustrationAssets.muscle(machine, style)
          : IllustrationAssets.group(machine.group, style),
      executionPlaceholder: curated != null
          ? SvgPicture.asset(curated, fit: BoxFit.contain)
          : verified ? null :
          UnverifiedExerciseIllustration(machine: machine,
            compact: compact || height < 110),
      // Same-profile anatomical fallback, never a different person's assets.
      muscleFallback: IllustrationAssets.group(machine.group, style),
      height: height,
      width: width,
      // Always fit the complete execution image; never crop or stretch it.
      fit: BoxFit.contain,
      compact: compact,
      showLabel: showLabel,
    );
  }
}
