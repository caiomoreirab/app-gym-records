import 'package:material_ui/material_ui.dart';

import '../models/user_profile.dart';
import '../services/illustration_assets.dart';
import '../theme/app_theme.dart';

class IllustrationStyleCard extends StatelessWidget {
  const IllustrationStyleCard({
    super.key,
    required this.style,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final IllustrationStyle style;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 17.0 : 24.0;
    return Material(
      color: AppTheme.surfaceNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(
          color: selected ? AppTheme.electricLime : AppTheme.deepBlue,
          width: selected ? 2.2 : 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: compact ? 112 : 150,
          child: Row(
            children: [
              SizedBox(
                width: compact ? 112 : 142,
                height: double.infinity,
                child: Image.asset(
                  IllustrationAssets.onboarding(style),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: AppTheme.deepNavy,
                    child: Icon(Icons.fitness_center_rounded, size: 44),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: compact ? 74 : 102,
                color: AppTheme.deepBlue,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 14 : 18,
                    vertical: compact ? 12 : 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        style.labelFor(Localizations.localeOf(context)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: compact ? 16 : 19,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        style.descriptionFor(Localizations.localeOf(context)),
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.iceBlue,
                              height: 1.28,
                              fontSize: compact ? 12.5 : 14.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: compact ? 12 : 16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: compact ? 34 : 42,
                  height: compact ? 34 : 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppTheme.electricLime : Colors.transparent,
                    border: Border.all(
                      color: selected ? AppTheme.electricLime : AppTheme.iceBlue,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppTheme.deepNavy,
                          size: 26,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
