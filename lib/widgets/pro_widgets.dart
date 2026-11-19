import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class ProPill extends StatelessWidget {
  const ProPill({super.key, this.label = 'PRO'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentBlueSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.electricLime),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.electricLime,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class ProFeatureCard extends StatelessWidget {
  const ProFeatureCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.electricLime.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricLime.withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: content,
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent ? AppTheme.accentBlueSoft : AppTheme.surfaceNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent ? AppTheme.electricLime : AppTheme.deepBlue,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.electricLime),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: AppTheme.iceBlue, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.polarWhite,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
