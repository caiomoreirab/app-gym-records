import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/muscle_group.dart';
import '../services/analytics_service.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/analytics_widgets.dart';
import '../widgets/page_body.dart';
import '../widgets/pro_widgets.dart';
import '../widgets/section_card.dart';
import 'machine_screen.dart';
import 'pro_cardio_analytics_screen.dart';
import 'pro_overview_screen.dart';

/// Data-driven dashboard. The previous hard-coded +27%, "5 workouts" and
/// chart points have been removed; filters recalculate the displayed data.
class EvolutionScreen extends StatefulWidget {
  const EvolutionScreen({super.key, this.initialGroup});
  final MuscleGroup? initialGroup;

  @override
  State<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends State<EvolutionScreen> {
  late MuscleGroup? _group;
  AnalyticsPeriod _period = AnalyticsPeriod.month;
  AnalyticsMetric _metric = AnalyticsMetric.volume;

  @override
  void initState() {
    super.initState();
    _group = widget.initialGroup;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.isPro) return const ProOverviewScreen();
    final locale = Localizations.localeOf(context);
    final now = DateTime.now();
    final summary = AnalyticsService.summary(app.machines, period: _period, now: now, group: _group);
    final comparison = AnalyticsService.groupSummaries(app.machines, _period, now);
    final trend = AnalyticsService.trend(app.machines, period: _period, metric: _metric, now: now, group: _group);
    final ready = AnalyticsService.rankedMachines(app.machines, group: _group, period: _period, now: now).take(5).toList();
    final progress = summary.progressPercent;
    final groupLabel = _group == null
        ? context.strings.t('Visão geral', 'Overview', 'Visión general')
        : _group!.localizedLabel(locale);

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        leading: const BackButton(),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(context.strings.t('Relatórios', 'Reports', 'Informes')),
          const SizedBox(width: 9),
          const ProPill(),
        ]),
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const SizedBox(height: 12),
            Text(groupLabel, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 5),
            Text(
              context.strings.t('Dados do histórico registrado; selecione grupo, período e métrica.', 'Calculated from recorded sessions; select group, period and metric.', 'Datos registrados; selecciona grupo, periodo y métrica.'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            AnalyticsFilters(
              group: _group,
              period: _period,
              metric: _metric,
              onGroupChanged: (value) => setState(() => _group = value),
              onPeriodChanged: (value) => setState(() => _period = value),
              onMetricChanged: (value) => setState(() => _metric = value),
            ),
            const SizedBox(height: 16),
            ProFeatureCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.strings.t('Resumo do período', 'Period summary', 'Resumen del período'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(spacing: 18, runSpacing: 14, children: [
                  _SummaryValue(title: context.strings.t('Registros', 'Logs', 'Registros'), value: '${summary.logs}'),
                  _SummaryValue(title: context.strings.t('Dias ativos', 'Active days', 'Días activos'), value: '${summary.trainingDays}'),
                  _SummaryValue(title: context.strings.t('Exercícios ativos', 'Active exercises', 'Ejercicios activos'), value: '${summary.activeExercises}'),
                  _SummaryValue(title: context.strings.t('Volume (kg)', 'Volume (kg)', 'Volumen (kg)'), value: formatWeight(summary.volumeKg, locale)),
                  _SummaryValue(title: context.strings.t('Repetições', 'Repetitions', 'Repeticiones'), value: '${summary.repetitions}'),
                  _SummaryValue(title: context.strings.t('Tempo (min)', 'Time (min)', 'Tiempo (min)'), value: summary.durationMinutes.toStringAsFixed(1)),
                ]),
                const SizedBox(height: 14),
                Text(
                  progress == null
                      ? context.strings.t('Evolução de carga: são necessárias pelo menos duas sessões com carga no mesmo exercício.', 'Load progress requires at least two weighted sessions on one exercise.', 'La evolución de carga requiere dos sesiones con carga en un ejercicio.')
                      : context.strings.t('Variação média da carga por exercício: ${progress >= 0 ? '+' : ''}${progress.toStringAsFixed(1)}%', 'Average change in load per exercise: ${progress >= 0 ? '+' : ''}${progress.toStringAsFixed(1)}%', 'Variación media de carga: ${progress >= 0 ? '+' : ''}${progress.toStringAsFixed(1)}%'),
                  style: const TextStyle(color: AppTheme.iceBlue, fontSize: 12),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            Text(context.strings.t('Evolução por período', 'Period trend', 'Evolución por período'), style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            summary.trainingDays < 3
                ? const SectionCard(child: Text(
                    'Registre treinos em pelo menos 3 dias para ver seu primeiro gráfico.',
                    style: TextStyle(color: AppTheme.iceBlue)))
                : TrendBarChart(values: trend, metric: _metric),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProCardioAnalyticsScreen())),
              icon: const Icon(Icons.directions_run_rounded),
              label: Text(context.strings.t('Ver relatório de cardio', 'Open cardio report', 'Ver informe de cardio')),
            ),
            const SizedBox(height: 22),
            Text(context.strings.t('Comparativo por grupo', 'Compare muscle groups', 'Comparar grupos musculares'), style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            SectionCard(
              child: Column(children: [
                for (final group in comparison) ...[
                  InkWell(
                    onTap: () => setState(() => _group = group.group),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        Expanded(child: Text(group.group!.localizedLabel(locale), style: Theme.of(context).textTheme.titleMedium)),
                        Text('${group.logs} ${context.strings.t('registros', 'logs', 'registros')}', style: const TextStyle(color: AppTheme.iceBlue)),
                        const SizedBox(width: 12),
                        Text(group.progressPercent == null ? '—' : '${group.progressPercent! >= 0 ? '+' : ''}${group.progressPercent!.toStringAsFixed(1)}%', style: const TextStyle(color: AppTheme.electricLime, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.iceBlue),
                      ]),
                    ),
                  ),
                  if (group != comparison.last) const Divider(height: 1),
                ],
              ]),
            ),
            const SizedBox(height: 22),
            Text(context.strings.t('Exercícios registrados', 'Logged exercises', 'Ejercicios registrados'), style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            if (ready.isEmpty)
              SectionCard(child: Text(context.strings.t('Nenhum exercício registrado neste filtro.', 'No recorded exercises in this filter.', 'No hay ejercicios registrados en este filtro.')))
            else
              SectionCard(
                child: Column(children: [
                  for (final machine in ready) ...[
                    InkWell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MachineScreen(machineId: machine.id))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Row(children: [
                          const Icon(Icons.fitness_center_rounded, color: AppTheme.electricLime, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(machine.localizedName(locale), style: Theme.of(context).textTheme.titleMedium)),
                          Text(machine.recordWeight > 0 ? '${formatWeight(machine.recordWeight, locale)} ${app.unit}' : machine.bestRepetitions > 0 ? '${machine.bestRepetitions} reps' : '—', style: const TextStyle(color: AppTheme.electricLime)),
                          const Icon(Icons.chevron_right_rounded, color: AppTheme.iceBlue),
                        ]),
                      ),
                    ),
                  ],
                ]),
              ),
            const SizedBox(height: 14),
            Text(context.strings.t('Os indicadores são descritivos e consideram somente os registros disponíveis nesta prévia.', 'Indicators are descriptive and use only available logs in this preview.', 'Los indicadores son descriptivos y usan los registros disponibles.'), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.title, required this.value});
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 92,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.electricLime, fontSize: 23, fontWeight: FontWeight.w600)),
          Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.iceBlue)),
        ]),
      );
}
