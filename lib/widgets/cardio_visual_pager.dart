import 'package:material_ui/material_ui.dart';

import '../models/cardio_activity.dart';
import '../services/cardio_assets.dart';
import '../models/user_profile.dart';
import '../state/app_controller.dart';
import 'two_view_image_pager.dart';

class CardioVisualPager extends StatelessWidget {
  const CardioVisualPager({super.key, required this.activity, required this.height, this.width, this.fit = BoxFit.cover, this.compact = false, this.showLabel = false});
  final CardioActivity activity;
  final double height;
  final double? width;
  final BoxFit fit;
  final bool compact;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final style = AppScope.of(context).effectiveIllustrationStyle;
    return TwoViewImagePager(
      key: ValueKey('cardio-pager:${activity.id}:${style.assetFolder}'),
      visualSetKey: '${activity.id}:${style.assetFolder}',
      executionPath: CardioAssets.execution(activity.kind, style),
      musclePath: CardioAssets.activation(activity.kind, style),
      executionFallback: CardioAssets.group(style),
      // Never fall back to execution/group photography for an anatomy slide.
      muscleFallback: null,
      height: height,
      width: width,
      fit: fit,
      compact: compact,
      showLabel: showLabel,
      executionIcon: Icons.directions_run_rounded,
    );
  }
}
