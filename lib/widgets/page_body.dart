import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppTheme.deepNavy),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(AppTheme.pagePadding),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
