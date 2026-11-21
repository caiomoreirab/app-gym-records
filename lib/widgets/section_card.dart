import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceNavy,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.deepBlue),
      ),
      // ListTile and InkWell require a Material surface above the decoration.
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}
