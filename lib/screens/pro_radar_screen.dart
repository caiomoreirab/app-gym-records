import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/muscle_group.dart';
import '../services/analytics_service.dart';
import '../services/pro_insights.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../services/weight_units.dart';
import '../widgets/analytics_widgets.dart';
import '../widgets/page_body.dart';
import '../widgets/section_card.dart';
import 'exercise_insights_screen.dart';
import 'pro_overview_screen.dart';

class ProRadarScreen extends StatefulWidget {
  const ProRadarScreen({super.key});
  @override
  State<ProRadarScreen> createState() => _ProRadarScreenState();
}

class _ProRadarScreenState extends State<ProRadarScreen> {
  MuscleGroup? _group;
  AnalyticsPeriod _period = AnalyticsPeriod.month;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.isPro) return const ProOverviewScreen();
    final locale = Localizations.localeOf(context);
    final items = AnalyticsService.rankedMachines(app.machines, group: _group, period: _period);
    items.sort((a, b) => (b.latestRecord?.date ?? DateTime(1970))
        .compareTo(a.latestRecord?.date ?? DateTime(1970)));

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: const Text('Próximo objetivo')),
      body: PageBody(
        child: ListView(padding: const EdgeInsets.only(bottom: 30), children: [
          const SizedBox(height: 10),
          Text(context.strings.t('Próximos alvos', 'Next targets', 'Próximos objetivos'), style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(context.strings.t(
            'Metas exploratórias calculadas a partir dos seus registros, não previsões.',
            'Exploratory goals based on your records, not predictions.',
            'Objetivos exploratorios basados en tus registros, no predicciones.'),
            style: Theme.of(context).textTheme.bodySmall),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (d) => AlertDialog(
                  title: const Text('Como calculamos?'),
                  content: const Text(
                    'O próximo alvo parte do seu maior peso registrado '
                    'mais o incremento configurado. O índice de proximidade '
                    'combina a relação da última carga com o recorde e a '
                    'quantidade recente de registros (até cinco). É apenas '
                    'uma regra exploratória, não uma probabilidade estatística.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(d),
                      child: const Text('Entendi')),
                  ],
                ),
              ),
              icon: const Icon(Icons.help_outline_rounded),
              label: const Text('Como calculamos?'),
            ),
          ),
          const SizedBox(height: 16),
          AnalyticsFilters(
            group: _group,
            period: _period,
            onGroupChanged: (g) => setState(() => _group = g),
            onPeriodChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            SectionCard(child: Text(context.strings.t('Registre exercícios para ver sugestões de progressão.', 'Log exercises to see progression suggestions.', 'Registra ejercicios para ver sugerencias de progresión.')))
          else
            for (final machine in items) ...[
              Builder(builder: (context) {
                final insight = ProInsights.forMachine(machine, WeightUnits.toKilograms(app.increment, app.unit));
                final usable = machine.records.where((r) => !r.isWarmup).toList();
                final sessions = usable.map((r) => r.effectiveSessionId).toSet();
                final ready = usable.length >= 3 && sessions.length >= 2;
                return SectionCard(child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ExerciseInsightsScreen(machineId: machine.id))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(machine.localizedName(locale), style: Theme.of(context).textTheme.titleMedium)),
                      Text(ready
                        ? context.strings.t('Sugestão', 'Suggestion', 'Sugerencia')
                        : context.strings.t('Aguardando dados', 'More data needed', 'Faltan datos'),
                        style: const TextStyle(color: AppTheme.electricLime,
                          fontWeight: FontWeight.w600, fontSize: 12)),
                      const Icon(Icons.chevron_right_rounded),
                    ]),
                    const SizedBox(height: 8),
                    const Divider(color: AppTheme.deepBlue),
                    const SizedBox(height: 9),
                    Text(
                      !ready
                          ? context.strings.t(
                              'Registre este exercício em pelo menos 2 sessões e 3 séries válidas.',
                              'Log this exercise over 2 sessions and 3 valid sets.',
                              'Registra este ejercicio en 2 sesiones y 3 series válidas.')
                          : machine.recordWeight > 0
                              ? '${context.strings.t('Alvo sugerido', 'Suggested target', 'Objetivo sugerido')}: ${WeightUnits.format(insight.nextTarget, app.unit, locale)} ${app.unit} × ${insight.targetRepetitions}'
                              : '${context.strings.t('Repetições alvo', 'Target reps', 'Repeticiones objetivo')}: ${machine.bestRepetitions + 1}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ]),
                ));
              }),
              const SizedBox(height: 10),
            ],
        ]),
      ),
    );
  }
}
