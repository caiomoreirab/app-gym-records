import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/muscle_group.dart';
import '../theme/app_theme.dart';
import 'adaptive_illustration.dart';

class MuscleGroupCard extends StatelessWidget {
  const MuscleGroupCard({
    super.key,
    required this.group,
    required this.onTap,
    this.wide = false,
  });

  final MuscleGroup group;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Material(
        color: AppTheme.surfaceNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: const BorderSide(color: AppTheme.deepBlue),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 142,
            child: Row(
              children: [
                const SizedBox(width: 0),
                Expanded(
                  flex: 6,
                  child: AdaptiveGroupImage(
                    group: group,
                    fit: BoxFit.cover,
                    height: double.infinity,
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _Labels(group: group),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: AppTheme.surfaceNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: const BorderSide(color: AppTheme.deepBlue),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: AdaptiveGroupImage(group: group, fit: BoxFit.cover)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: _Labels(group: group),
            ),
          ],
        ),
      ),
    );
  }
}

class _Labels extends StatelessWidget {
  const _Labels({required this.group});

  final MuscleGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(group.localizedLabel(Localizations.localeOf(context)), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '${group.catalogCount} ${context.strings.t(group.catalogCount == 1 ? 'exercício' : 'exercícios', group.catalogCount == 1 ? 'exercise' : 'exercises')}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.iceBlue,
              ),
        ),
      ],
    );
  }
}
