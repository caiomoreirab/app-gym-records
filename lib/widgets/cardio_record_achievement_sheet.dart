import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/cardio_activity.dart';
import '../models/cardio_achievement.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'section_card.dart';
import 'blue_confetti_overlay.dart';

Future<void> showCardioRecordAchievementSheet({
  required BuildContext context,
  required CardioActivity activity,
  required CardioAchievement achievement,
}) async {
  final app = AppScope.of(context);
  final locale = Localizations.localeOf(context);
  final primary = achievement.primary;
  final activityName = activity.localizedName(locale);
  final metricName = _metricLabel(context, primary.type);
  final value = _formatMetric(primary, activity, app.distanceUnit, locale);
  final previous = _formatPrevious(primary, activity, app.distanceUnit, locale);
  final name = app.displayName.trim().isEmpty ? context.strings.user : app.displayName.trim();
  final shareText = context.strings.t(
    '$name bateu um novo recorde no $activityName: $metricName $value com o GymRecords.',
    '$name hit a new $activityName record: $metricName $value with GymRecords.',
    '$name logró un nuevo récord en $activityName: $metricName $value con GymRecords.',
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.deepNavy,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.deepBlue,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0C3653), Color(0xFF06121F)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.electricLime),
              ),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentBlueSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/branding/icon_blue.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events_rounded, size: 48, color: AppTheme.electricLime),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.strings.t('Novo recorde!', 'New record!', '¡Nuevo récord!'),
                    textAlign: TextAlign.center,
                    style: Theme.of(sheetContext).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    activityName,
                    textAlign: TextAlign.center,
                    style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(color: AppTheme.iceBlue),
                  ),
                  const SizedBox(height: 18),
                  SectionCard(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Column(
                      children: [
                        Text(metricName, style: Theme.of(sheetContext).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: Theme.of(sheetContext).textTheme.headlineLarge?.copyWith(
                                color: AppTheme.electricLime,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          primary.previousValue <= 0
                              ? context.strings.t('Primeira marca registrada', 'First mark recorded', 'Primera marca registrada')
                              : context.strings.t(
                                  'Anterior: $previous',
                                  'Previous: $previous',
                                  'Anterior: $previous',
                                ),
                          style: Theme.of(sheetContext).textTheme.bodySmall,
                        ),
                        if (achievement.count > 1) ...[
                          const SizedBox(height: 8),
                          Text(
                            context.strings.t(
                              '+ ${achievement.count - 1} outro recorde nesta sessão',
                              '+ ${achievement.count - 1} other record in this session',
                              '+ ${achievement.count - 1} récord adicional en esta sesión',
                            ),
                            style: const TextStyle(color: AppTheme.electricLime, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  top: -18,
                  child: BlueConfettiOverlay(height: 120),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: shareText));
                if (!sheetContext.mounted) return;
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(context.strings.t('Conquista copiada para compartilhar.', 'Achievement copied to share.', 'Logro copiado para compartir.'))),
                );
              },
              icon: const Icon(Icons.share_rounded),
              label: Text(context.strings.t('Compartilhar conquista', 'Share achievement', 'Compartir logro')),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(context.strings.t('Continuar', 'Continue', 'Continuar')),
            ),
          ],
        ),
      ),
    ),
  );
}

String _metricLabel(BuildContext context, CardioAchievementType type) => switch (type) {
      CardioAchievementType.distance => context.strings.t('Maior distância', 'Longest distance', 'Mayor distancia'),
      CardioAchievementType.pace => context.strings.t('Melhor pace', 'Best pace', 'Mejor ritmo'),
      CardioAchievementType.duration => context.strings.t('Maior duração', 'Longest duration', 'Mayor duración'),
      CardioAchievementType.speed => context.strings.t('Maior velocidade média', 'Fastest average speed', 'Mayor velocidad media'),
    };

String _formatMetric(
  CardioAchievementMetric metric,
  CardioActivity activity,
  String distanceUnit,
  Locale locale,
) {
  return _formatValue(metric.type, metric.newValue, activity, distanceUnit, locale);
}

String _formatPrevious(
  CardioAchievementMetric metric,
  CardioActivity activity,
  String distanceUnit,
  Locale locale,
) {
  return _formatValue(metric.type, metric.previousValue, activity, distanceUnit, locale);
}

String _formatValue(
  CardioAchievementType type,
  double value,
  CardioActivity activity,
  String distanceUnit,
  Locale locale,
) {
  switch (type) {
    case CardioAchievementType.distance:
      final display = distanceUnit == 'mi' ? value / 1.609344 : value;
      final number = display.toStringAsFixed(2);
      return '${locale.languageCode == 'en' ? number : number.replaceAll('.', ',')} $distanceUnit';
    case CardioAchievementType.pace:
      var pace = value;
      String suffix;
      if (activity.paceDistanceKm == 0.5) {
        suffix = '/500m';
      } else if (distanceUnit == 'mi') {
        pace = value * 1.609344;
        suffix = '/mi';
      } else {
        suffix = '/km';
      }
      final minutes = pace.floor();
      final seconds = ((pace - minutes) * 60).round().clamp(0, 59);
      return '$minutes:${seconds.toString().padLeft(2, '0')} $suffix';
    case CardioAchievementType.duration:
      final total = value.round();
      final hours = total ~/ 3600;
      final minutes = (total % 3600) ~/ 60;
      final seconds = total % 60;
      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    case CardioAchievementType.speed:
      final display = distanceUnit == 'mi' ? value / 1.609344 : value;
      return '${display.toStringAsFixed(1)} ${distanceUnit == 'mi' ? 'mph' : 'km/h'}';
  }
}
