import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.surfaceNavy,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      side: const BorderSide(color: AppTheme.deepBlue),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: padding ?? const EdgeInsets.all(18),
      child: child,
    ),
  );
}
