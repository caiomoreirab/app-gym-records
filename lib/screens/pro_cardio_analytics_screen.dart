import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../services/analytics_service.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/page_body.dart';
import '../widgets/pro_widgets.dart';
import '../widgets/section_card.dart';
import 'cardio_activity_screen.dart';
import 'pro_overview_screen.dart';

enum _CardioChartMetric { distance, duration, sessions }

class ProCardioAnalyticsScreen extends StatefulWidget {
  const ProCardioAnalyticsScreen({super.key});
  @override
  State<ProCardioAnalyticsScreen> createState() => _ProCardioAnalyticsScreenState();
}

class _ProCardioAnalyticsScreenState extends State<ProCardioAnalyticsScreen> {
  AnalyticsPeriod _period = AnalyticsPeriod.month;
  String? _activityId;
  _CardioChartMetric _metric = _CardioChartMetric.distance;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.isPro) return const ProOverviewScreen();
    final locale = Localizations.localeOf(context);
    final now = DateTime.now();
    final activities = app.cardioActivities.where((a) => _activityId == null || a.id == _activityId).toList(growable: false);
    final allRecords = [for (final a in activities) ...a.records];
    final earliest = allRecords.isEmpty ? now.subtract(const Duration(days: 30)) : allRecords.map((r) => r.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final lower = switch (_period) {
      AnalyticsPeriod.week => now.subtract(const Duration(days: 7)),
      AnalyticsPeriod.month => now.subtract(const Duration(days: 30)),
      AnalyticsPeriod.quarter => now.subtract(const Duration(days: 90)),
      AnalyticsPeriod.all => earliest,
    };
    final relevant = allRecords.where((r) => !r.date.isBefore(lower) && !r.date.isAfter(now)).toList();
    final totalDistance = relevant.fold<double>(0, (sum, record) => sum + (record.distanceKm ?? 0));
    final totalMinutes = relevant.fold<double>(0, (sum, record) => sum + record.duration.inSeconds / 60);
    final distances = relevant.where((r) => (r.distanceKm ?? 0) > 0).toList();
    final bestPace = distances.isEmpty ? null : distances.map((r) => r.duration.inSeconds / 60 / r.distanceKm!).reduce(math.min);

    const bars = 8;
    final values = List<double>.filled(bars, 0);
    final seconds = math.max(1, now.difference(lower).inSeconds);
    for (final item in relevant) {
      final index = (item.date.difference(lower).inSeconds / seconds * bars).floor().clamp(0, bars - 1).toInt();
      values[index] += switch (_metric) {
        _CardioChartMetric.distance => item.distanceKm ?? 0,
        _CardioChartMetric.duration => item.duration.inSeconds / 60,
        _CardioChartMetric.sessions => 1,
      };
    }
    final maxValue = values.fold<double>(0, math.max);

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: Row(mainAxisSize: MainAxisSize.min, children: [Text(context.strings.t('Cardio • Relatórios', 'Cardio • Reports', 'Cardio • Informes')), const SizedBox(width: 8), const ProPill()])),
      body: PageBody(child: ListView(padding: const EdgeInsets.only(bottom: 30), children: [
        const SizedBox(height: 12),
        Text(context.strings.t('Relatório cardiovascular', 'Cardio report', 'Informe cardiovascular'), style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          value: _activityId,
          decoration: InputDecoration(labelText: context.strings.t('Atividade', 'Activity', 'Actividad')),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(context.strings.t('Todas as atividades', 'All activities', 'Todas las actividades'))),
            for (final activity in app.cardioActivities)
              DropdownMenuItem<String?>(value: activity.id, child: Text(activity.localizedName(locale))),
          ],
          onChanged: (value) => setState(() => _activityId = value),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          for (final period in AnalyticsPeriod.values) ...[
            ChoiceChip(label: Text(period.label(locale)), selected: _period == period, onSelected: (_) => setState(() => _period = period)),
            const SizedBox(width: 7),
          ],
        ])),
        const SizedBox(height: 16),
        ProFeatureCard(child: Wrap(spacing: 24, runSpacing: 14, children: [
          _CardioMetric(label: context.strings.t('Sessões', 'Sessions', 'Sesiones'), value: '${relevant.length}'),
          _CardioMetric(label: context.strings.t('Distância', 'Distance', 'Distancia'), value: '${(app.distanceUnit == 'mi' ? totalDistance / 1.609344 : totalDistance).toStringAsFixed(1)} ${app.distanceUnit}'),
          _CardioMetric(label: context.strings.t('Duração', 'Duration', 'Duración'), value: '${totalMinutes.toStringAsFixed(0)} min'),
          _CardioMetric(label: context.strings.t('Melhor pace', 'Best pace', 'Mejor ritmo'), value: bestPace == null ? '—' : '${bestPace.floor()}:${(((bestPace - bestPace.floor()) * 60).round()).toString().padLeft(2, '0')} /km'),
        ])),
        const SizedBox(height: 20),
        Text(context.strings.t('Evolução do cardio', 'Cardio trend', 'Evolución del cardio'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          for (final metric in _CardioChartMetric.values) ...[
            ChoiceChip(
              label: Text(switch (metric) {
                _CardioChartMetric.distance => context.strings.t('Distância', 'Distance', 'Distancia'),
                _CardioChartMetric.duration => context.strings.t('Tempo', 'Duration', 'Tiempo'),
                _CardioChartMetric.sessions => context.strings.t('Sessões', 'Sessions', 'Sesiones'),
              }),
              selected: _metric == metric,
              onSelected: (_) => setState(() => _metric = metric),
            ),
            const SizedBox(width: 7),
          ],
        ])),
        const SizedBox(height: 12),
        SectionCard(child: SizedBox(
          height: 182,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < bars; i++)
              Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(values[i] == 0 ? '' : values[i].toStringAsFixed(1), style: const TextStyle(fontSize: 10, color: AppTheme.iceBlue)),
                  const SizedBox(height: 4),
                  Container(height: maxValue == 0 ? 3 : math.max(3, values[i] / maxValue * 130), decoration: BoxDecoration(color: values[i] > 0 ? AppTheme.electricLime : AppTheme.deepBlue, borderRadius: const BorderRadius.vertical(top: Radius.circular(5)))),
                  const SizedBox(height: 8),
                  Text('${i + 1}', style: const TextStyle(color: AppTheme.iceBlue, fontSize: 10)),
                ]),
              )),
          ]),
        )),
        const SizedBox(height: 22),
        Text(context.strings.t('Abrir atividade', 'Open activity', 'Abrir actividad'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        for (final activity in activities) ...[
          SectionCard(child: InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CardioActivityScreen(activityId: activity.id))),
            child: Row(children: [
              const Icon(Icons.directions_run_rounded, color: AppTheme.electricLime),
              const SizedBox(width: 10),
              Expanded(child: Text(activity.localizedName(locale), style: Theme.of(context).textTheme.titleMedium)),
              Text('${activity.records.length}', style: const TextStyle(color: AppTheme.iceBlue)),
              const Icon(Icons.chevron_right_rounded),
            ]),
          )),
          const SizedBox(height: 8),
        ],
        Text(context.strings.t('O pace é calculado somente em atividades com distância e tempo registrados.', 'Pace is calculated only from sessions with recorded distance and duration.', 'El ritmo se calcula solo con distancia y tiempo registrados.'), style: Theme.of(context).textTheme.bodySmall),
      ])),
    );
  }
}

class _CardioMetric extends StatelessWidget {
  const _CardioMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 130,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(color: AppTheme.electricLime, fontSize: 23, fontWeight: FontWeight.w600)),
      Text(label, style: const TextStyle(color: AppTheme.iceBlue, fontSize: 11)),
    ]),
  );
}
