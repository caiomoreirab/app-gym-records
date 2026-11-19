import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/machine.dart';
import '../models/workout_record.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'blue_confetti_overlay.dart';
import 'section_card.dart';

enum StrengthAchievementMetric { weight, repetitions, duration }

Future<void> showRecordAchievementSheet({
  required BuildContext context,
  required Machine machine,
  required double previousWeight,
  required int previousRepetitions,
  required int previousDurationSeconds,
  required StrengthAchievementMetric metric,
}) async {
  final app = AppScope.of(context);
  final latest = machine.latestRecord!;
  final locale = Localizations.localeOf(context);
  final name = app.displayName.isEmpty ? context.strings.user : app.displayName;
  final highlight = _highlightValue(metric, latest, app.unit, locale);
  final previous = _previousValue(metric, previousWeight, previousRepetitions, previousDurationSeconds, app.unit, locale);
  final shareText = context.strings.t(
    '$name bateu um novo recorde em ${machine.localizedName(locale)}: $highlight com o GymRecords.',
    '$name hit a new record on ${machine.localizedName(locale)}: $highlight with GymRecords.',
    '$name logró un nuevo récord en ${machine.localizedName(locale)}: $highlight con GymRecords.',
  );
  final mockLink = 'https://gymrecords.app/conquista/${machine.id}';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.deepNavy,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              child: Container(width: 46, height: 4, decoration: BoxDecoration(color: AppTheme.deepBlue, borderRadius: BorderRadius.circular(99))),
            ),
            const SizedBox(height: 18),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(color: AppTheme.electricLime, borderRadius: BorderRadius.circular(AppTheme.radius)),
                  child: Row(
                    children: [
                      Image.asset('assets/branding/icon_blue.png', width: 92, height: 92),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(context.strings.t('Novo recorde', 'New record', 'Nuevo récord'), style: const TextStyle(color: AppTheme.deepNavy, fontSize: 21, fontWeight: FontWeight.w600)),
                          Text(highlight, style: const TextStyle(color: AppTheme.deepNavy, fontSize: 42, fontWeight: FontWeight.w600, height: 1)),
                          const SizedBox(height: 7),
                          Text(context.strings.t('Anterior: $previous', 'Previous: $previous', 'Anterior: $previous'), style: const TextStyle(color: AppTheme.deepNavy, fontSize: 14)),
                        ]),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: -6,
                  right: -6,
                  top: -18,
                  child: IgnorePointer(child: BlueConfettiOverlay(height: 120)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(context.strings.t('Compartilhe sua conquista', 'Share your achievement', 'Comparte tu logro'), style: Theme.of(sheetContext).textTheme.headlineSmall),
                const SizedBox(height: 16),
                SectionCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    SizedBox(
                      width: 118,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Image.asset('assets/branding/icon_blue.png', width: 58, height: 58),
                        const SizedBox(height: 4),
                        const Text.rich(
                          TextSpan(children: [TextSpan(text: 'Gym', style: TextStyle(color: AppTheme.polarWhite)), TextSpan(text: 'Records', style: TextStyle(color: AppTheme.electricLime))]),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, fontSize: 15),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(shareText, style: Theme.of(sheetContext).textTheme.bodyMedium)),
                  ]),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: shareText));
                    if (!sheetContext.mounted) return;
                    ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(context.strings.t('Texto da conquista copiado. A integração com o WhatsApp entra na próxima etapa funcional.', 'Achievement text copied. WhatsApp integration will be connected in the next functional phase.', 'Texto del logro copiado. La integración con WhatsApp se conectará en la próxima etapa funcional.'))));
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: Text(context.strings.t('Compartilhar no WhatsApp', 'Share on WhatsApp', 'Compartir en WhatsApp')),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: mockLink));
                    if (!sheetContext.mounted) return;
                    ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(context.strings.t('Link de demonstração copiado.', 'Demo link copied.', 'Enlace de demostración copiado.'))));
                  },
                  icon: const Icon(Icons.link_rounded),
                  label: Text(context.strings.t('Copiar link', 'Copy link', 'Copiar enlace')),
                ),
                TextButton(onPressed: () => Navigator.of(sheetContext).pop(), child: Text(context.strings.t('Agora não', 'Not now', 'Ahora no'), style: const TextStyle(color: AppTheme.iceBlue))),
              ]),
            ),
          ],
        ),
      ),
    ),
  );
}

String _highlightValue(StrengthAchievementMetric metric, WorkoutRecord latest, String unit, Locale locale) {
  switch (metric) {
    case StrengthAchievementMetric.weight:
      return '${formatWeight(latest.weight, locale)} $unit';
    case StrengthAchievementMetric.repetitions:
      return '${latest.repetitions ?? 0} reps';
    case StrengthAchievementMetric.duration:
      return _durationShort(latest.durationSeconds ?? 0);
  }
}

String _previousValue(StrengthAchievementMetric metric, double weight, int reps, int duration, String unit, Locale locale) {
  switch (metric) {
    case StrengthAchievementMetric.weight:
      return weight > 0 ? '${formatWeight(weight, locale)} $unit' : '—';
    case StrengthAchievementMetric.repetitions:
      return reps > 0 ? '$reps reps' : '—';
    case StrengthAchievementMetric.duration:
      return duration > 0 ? _durationShort(duration) : '—';
  }
}

String _durationShort(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  if (minutes <= 0) return '${remainder}s';
  return '${minutes}m ${remainder.toString().padLeft(2, '0')}s';
}
