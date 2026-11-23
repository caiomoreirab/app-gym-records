import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../services/cardio_assets.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

class CardioGroupCard extends StatelessWidget {
  const CardioGroupCard({super.key, required this.onTap,
    this.selected = false});

  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final style = AppScope.of(context).effectiveIllustrationStyle;
    return Material(
      color: AppTheme.surfaceNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: BorderSide(color: selected
          ? AppTheme.electricLime : AppTheme.deepBlue,
          width: selected ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true, selected: selected,
        child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: const Color(0xFF07111F),
                    child: Image.asset(
                      CardioAssets.group(style),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.directions_run_rounded, size: 54, color: AppTheme.electricLime),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xD905080D),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.electricLime),
                      ),
                      child: Icon(selected ? Icons.check_rounded
                        : Icons.directions_run_rounded,
                        color: AppTheme.electricLime, size: 23),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(context.strings.cardio, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    context.strings.t('9 atividades', '9 activities', '9 actividades'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.iceBlue),
                  ),
                ],
              ),
            ),
          ],
        ),
        ), // Semantics
      ),
    );
  }
}
