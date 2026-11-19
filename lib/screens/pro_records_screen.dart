import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/muscle_group.dart';
import '../services/analytics_service.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/analytics_widgets.dart';
import '../widgets/page_body.dart';
import '../widgets/section_card.dart';
import 'exercise_insights_screen.dart';
import 'machine_screen.dart';
import 'pro_overview_screen.dart';

class ProRecordsScreen extends StatefulWidget {
  const ProRecordsScreen({super.key});
  @override
  State<ProRecordsScreen> createState() => _ProRecordsScreenState();
}

class _ProRecordsScreenState extends State<ProRecordsScreen> {
  MuscleGroup? _group;
  AnalyticsPeriod _period = AnalyticsPeriod.all;
  bool _sortByWeight = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.isPro) return const ProOverviewScreen();
    final now = DateTime.now();
    final locale = Localizations.localeOf(context);
    final items = AnalyticsService.rankedMachines(app.machines, group: _group, period: _period, now: now);
    if (_sortByWeight) items.sort((a, b) => b.recordWeight.compareTo(a.recordWeight));

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: Text(context.strings.t('Hall de recordes', 'Record hall', 'Salón de récords'))),
      body: PageBody(
        child: ListView(padding: const EdgeInsets.only(bottom: 28), children: [
          const SizedBox(height: 12),
          AnalyticsFilters(
            group: _group,
            period: _period,
            onGroupChanged: (g) => setState(() => _group = g),
            onPeriodChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _sortByWeight,
            onChanged: (value) => setState(() => _sortByWeight = value),
            title: Text(context.strings.t('Ordenar por carga máxima', 'Sort by maximum load', 'Ordenar por carga máxima')),
            subtitle: Text(context.strings.t('Desativado: exercícios mais registrados primeiro', 'Off: most logged exercises first', 'Desactivado: más registros primero')),
          ),
          const SizedBox(height: 8),
          Text('${items.length} ${context.strings.t('exercícios com histórico', 'exercises with history', 'ejercicios con historial')}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          if (items.isEmpty)
            SectionCard(child: Text(context.strings.t('Sem recordes neste filtro.', 'No records in this filter.', 'Sin récords en este filtro.')))
          else
            for (final machine in items) ...[
              SectionCard(child: InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MachineScreen(machineId: machine.id))),
                child: Row(children: [
                  const Icon(Icons.emoji_events_outlined, color: AppTheme.electricLime, size: 25),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(machine.localizedName(locale), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(machine.group.localizedLabel(locale), style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text('${AnalyticsService.recordsInRange([machine], _period, now).length} ${context.strings.t('registros', 'logs', 'registros')}', style: const TextStyle(fontSize: 12, color: AppTheme.iceBlue)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(machine.recordWeight > 0 ? '${formatWeight(machine.recordWeight, locale)} ${app.unit}' : machine.bestRepetitions > 0 ? '${machine.bestRepetitions} reps' : '${machine.bestDurationSeconds}s', style: const TextStyle(color: AppTheme.electricLime, fontWeight: FontWeight.w600, fontSize: 19)),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ExerciseInsightsScreen(machineId: machine.id))),
                      child: Text(context.strings.t('Analisar', 'Analyze', 'Analizar')),
                    ),
                  ]),
                ]),
              )),
              const SizedBox(height: 10),
            ],
        ]),
      ),
    );
  }
}
