import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/muscle_group.dart';
import '../services/analytics_service.dart';
import '../services/pro_insights.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
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
    items.sort((a, b) => ProInsights.forMachine(b, app.increment).prProbability.compareTo(ProInsights.forMachine(a, app.increment).prProbability));

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: const Text('Próximo objetivo')),
      body: PageBody(
        child: ListView(padding: const EdgeInsets.only(bottom: 30), children: [
          const SizedBox(height: 10),
          Text(context.strings.t('Próximos alvos', 'Next targets', 'Próximos objetivos'), style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(context.strings.t('Índice exploratório de proximidade, não uma probabilidade estatística validada.', 'Exploratory proximity score, not a validated statistical probability.', 'Índice exploratorio de proximidad, no una probabilidad validada.'), style: Theme.of(context).textTheme.bodySmall),
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
                final insight = ProInsights.forMachine(machine, app.increment);
                return SectionCard(child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ExerciseInsightsScreen(machineId: machine.id))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(machine.localizedName(locale), style: Theme.of(context).textTheme.titleMedium)),
                      Text('${(insight.prProbability * 100).round()}/100', style: const TextStyle(color: AppTheme.electricLime, fontWeight: FontWeight.w600)),
                      const Icon(Icons.chevron_right_rounded),
                    ]),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: insight.prProbability, minHeight: 6, backgroundColor: AppTheme.deepBlue, valueColor: const AlwaysStoppedAnimation(AppTheme.electricLime)),
                    const SizedBox(height: 9),
                    Text(
                      machine.recordWeight > 0
                          ? '${context.strings.t('Alvo sugerido', 'Suggested target', 'Objetivo sugerido')}: ${formatWeight(insight.nextTarget, locale)} ${app.unit} × ${insight.targetRepetitions}'
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
