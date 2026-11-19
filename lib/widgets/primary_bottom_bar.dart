import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class PrimaryBottomBar extends StatelessWidget {
  const PrimaryBottomBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppTheme.deepNavy),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (secondary != null) ...[
                  secondary!,
                  const SizedBox(height: 10),
                ],
                FilledButton(onPressed: onPressed, child: Text(label)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
