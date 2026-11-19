import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    this.compact = false,
    this.trailing,
    this.showPro = false,
  });

  final bool compact;
  final Widget? trailing;
  final bool showPro;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/branding/icon_blue.png',
          width: compact ? 42 : 54,
          height: compact ? 42 : 54,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            const TextSpan(
              children: [
                TextSpan(text: 'Gym', style: TextStyle(color: AppTheme.polarWhite)),
                TextSpan(text: 'Records', style: TextStyle(color: AppTheme.electricLime)),
              ],
            ),
            style: TextStyle(
              fontFamily: 'Barlow',
              fontWeight: FontWeight.w600,
              fontSize: compact ? 21 : 25,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        if (showPro) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentBlueSoft,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.electricLime),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: AppTheme.electricLime,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (trailing != null) trailing!,
      ],
    );
  }
}
