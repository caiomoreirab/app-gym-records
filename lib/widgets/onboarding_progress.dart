import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({super.key, required this.step, this.total = 2});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.strings.t('Etapa $step de $total', 'Step $step of $total'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 1; index <= total; index++) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: index == step ? 64 : 38,
              height: 8,
              decoration: BoxDecoration(
                color: index == step ? AppTheme.electricLime : AppTheme.deepBlue,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            if (index != total) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}
