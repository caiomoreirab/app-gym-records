import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../services/pro_insights.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../services/weight_units.dart';
import '../widgets/page_body.dart';
import '../widgets/pro_widgets.dart';
import 'pro_overview_screen.dart';

class ExerciseInsightsScreen extends StatelessWidget {
  const ExerciseInsightsScreen({super.key, required this.machineId});

  final String machineId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final machine = app.machineById(machineId);
    final insights = ProInsights.forMachine(machine, WeightUnits.toKilograms(app.increment, app.unit));
    final latest = machine.latestRecord;
    final mostReps = insights.mostRepsRecord;

    if (!app.isPro) {
      return const ProOverviewScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(machine.localizedName(Localizations.localeOf(context))),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: ProPill(label: 'IQ PRO')),
          ),
        ],
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 34),
          children: [
            const SizedBox(height: 8),
            ProFeatureCard(
              child: Row(
                children: [
                  Image.asset(
                    'assets/branding/pro_mascot.webp',
                    width: 104,
                    height: 96,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.radar_rounded, color: AppTheme.electricLime),
                            const SizedBox(width: 7),
                            Text('PR Radar', style: Theme.of(context).textTheme.titleLarge),
                            const Spacer(),
                            ProPill(label: insights.probabilityLabelFor(Localizations.localeOf(context))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          insights.prProbability >= .82
                              ? context.strings.t('Você está próximo de um novo recorde neste exercício.', 'You are close to a new record on this exercise.')
                              : context.strings.t('Continue acumulando sessões para aumentar a confiança da análise.', 'Keep logging sessions to improve the analysis confidence.'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.iceBlue),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: insights.prProbability,
                            minHeight: 7,
                            backgroundColor: AppTheme.deepBlue,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.electricLime),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.strings.t('Índice exploratório ${(insights.prProbability * 100).round()}/100 (não é probabilidade validada)', 'Exploratory score ${(insights.prProbability * 100).round()}/100 (not a validated probability)', 'Índice exploratorio ${(insights.prProbability * 100).round()}/100 (no es una probabilidad validada)'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ProFeatureCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlueSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.track_changes_rounded, color: AppTheme.electricLime),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.strings.t('Próximo alvo sugerido', 'Suggested next target'), style: const TextStyle(color: AppTheme.iceBlue)),
                        const SizedBox(height: 4),
                        Text(
                          machine.recordWeight > 0 ? '${WeightUnits.format(insights.nextTarget, app.unit, Localizations.localeOf(context))} ${app.unit} × ${insights.targetRepetitions}' : '${machine.bestRepetitions + 1} reps',
                          style: const TextStyle(
                            color: AppTheme.electricLime,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.strings.t('Com base no seu histórico recente.', 'Based on your recent history.'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    icon: Icons.emoji_events_outlined,
                    label: context.strings.t('Recorde atual', 'Current record'),
                    value: machine.recordWeight > 0 ? '${WeightUnits.format(machine.recordWeight, app.unit, Localizations.localeOf(context))} ${app.unit}' : machine.bestRepetitions > 0 ? '${machine.bestRepetitions} reps' : machine.bestDurationSeconds > 0 ? '${machine.bestDurationSeconds}s' : '—',
                    accent: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    icon: Icons.history_rounded,
                    label: context.strings.t('Última sessão', 'Latest session'),
                    value: latest == null ? '—' : latest.weight > 0 ? '${WeightUnits.format(latest.weight, app.unit, Localizations.localeOf(context))} ${app.unit}${latest.repetitions == null ? '' : ' × ${latest.repetitions}'}' : latest.repetitions != null ? '${latest.repetitions} reps' : latest.durationSeconds != null ? '${latest.durationSeconds}s' : '—',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            MetricTile(
              icon: Icons.trending_up_rounded,
              label: context.strings.t('Evolução desde o primeiro registro', 'Progress since first log'),
              value: machine.recordWeight > 0 && machine.records.length > 1 ? '${insights.progressPercent >= 0 ? '+' : ''}${insights.progressPercent.toStringAsFixed(1).replaceAll('.', ',')}%' : '—',
            ),
            if (insights.hasPossiblePlateau) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: .7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.strings.t('Possível platô', 'Possible plateau'), style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            context.strings.t('As últimas sessões evoluíram pouco. Tente +${formatWeight(app.increment, Localizations.localeOf(context))} ${app.unit} ou +1 repetição.', 'Recent sessions changed very little. Try +${formatWeight(app.increment, Localizations.localeOf(context))} ${app.unit} or +1 repetition.'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: Text(context.strings.t('Hall de recordes', 'Record hall'), style: Theme.of(context).textTheme.headlineSmall)),
                const ProPill(label: 'PRO'),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.42,
              children: [
                MetricTile(
                  icon: Icons.emoji_events_outlined,
                  label: context.strings.t('Maior carga', 'Max load'),
                  value: machine.recordWeight > 0 ? '${WeightUnits.format(machine.recordWeight, app.unit, Localizations.localeOf(context))} ${app.unit}' : machine.bestRepetitions > 0 ? '${machine.bestRepetitions} reps' : machine.bestDurationSeconds > 0 ? '${machine.bestDurationSeconds}s' : '—',
                  accent: true,
                ),
                MetricTile(
                  icon: Icons.repeat_rounded,
                  label: context.strings.t('Mais repetições', 'Most repetitions'),
                  value: mostReps == null
                      ? '—'
                      : '${WeightUnits.format(mostReps.weight, app.unit, Localizations.localeOf(context))} ${app.unit} × ${mostReps.repetitions ?? 0}',
                ),
                MetricTile(
                  icon: Icons.bolt_rounded,
                  label: context.strings.t('1RM estimado', 'Estimated 1RM'),
                  value: machine.recordWeight > 0 ? '${WeightUnits.format(insights.estimatedOneRepMax, app.unit, Localizations.localeOf(context))} ${app.unit}' : '—',
                ),
                MetricTile(
                  icon: Icons.layers_outlined,
                  label: context.strings.t('Maior volume', 'Highest volume'),
                  value: machine.recordWeight > 0 && insights.maxVolume > 0 ? '${WeightUnits.format(insights.maxVolume, app.unit, Localizations.localeOf(context))} ${app.unit}' : '—',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
