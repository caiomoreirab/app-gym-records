import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/muscle_group.dart';
import '../services/analytics_service.dart';
import '../services/weight_units.dart';
import '../theme/app_theme.dart';
import 'section_card.dart';

class AnalyticsFilters extends StatelessWidget {
  const AnalyticsFilters({
    super.key,
    required this.group,
    required this.period,
    required this.onGroupChanged,
    required this.onPeriodChanged,
    this.metric,
    this.onMetricChanged,
    this.weightUnit = 'kg',
  });
  final MuscleGroup? group;
  final AnalyticsPeriod period;
  final AnalyticsMetric? metric;
  final String weightUnit;
  final ValueChanged<MuscleGroup?> onGroupChanged;
  final ValueChanged<AnalyticsPeriod> onPeriodChanged;
  final ValueChanged<AnalyticsMetric>? onMetricChanged;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final allLabel = locale.languageCode == 'en' ? 'All groups' : locale.languageCode == 'es' ? 'Todos los grupos' : 'Todos os grupos';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _Chip(label: allLabel, selected: group == null, onTap: () => onGroupChanged(null)),
          for (final muscle in MuscleGroup.values) ...[
            const SizedBox(width: 6),
            _Chip(label: muscle.localizedLabel(locale), selected: group == muscle, onTap: () => onGroupChanged(muscle)),
          ],
        ]),
      ),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final range in AnalyticsPeriod.values) ...[
            _Chip(label: range.label(locale), selected: period == range, onTap: () => onPeriodChanged(range)),
            const SizedBox(width: 6),
          ],
        ]),
      ),
      if (metric != null && onMetricChanged != null) ...[
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final candidate in AnalyticsMetric.values) ...[
              _Chip(label: candidate.label(locale, unit: weightUnit), selected: metric == candidate, onTap: () => onMetricChanged!(candidate)),
              const SizedBox(width: 6),
            ],
          ]),
        ),
      ],
    ]);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: ChoiceChip(
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppTheme.royalBlue,
          backgroundColor: AppTheme.surfaceNavy,
          side: BorderSide(color: selected ? AppTheme.electricLime : AppTheme.deepBlue),
        ),
      );
}

class TrendBarChart extends StatelessWidget {
  const TrendBarChart({super.key, required this.values, required this.metric,
      this.weightUnit = 'kg'});
  final List<AnalyticsBucket> values;
  final AnalyticsMetric metric;
  final String weightUnit;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final maxValue = values.fold<double>(0, (highest, item) => math.max(highest, item.value));
    final hasData = maxValue > 0;
    return SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(metric.label(Localizations.localeOf(context), unit: weightUnit), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 192,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final bucket in values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(bucket.value == 0 ? '' : _short(metric == AnalyticsMetric.volume
                        ? WeightUnits.volumeForDisplay(bucket.value, weightUnit)
                        : bucket.value), maxLines: 1, style: const TextStyle(fontSize: 10, color: AppTheme.iceBlue)),
                      const SizedBox(height: 5),
                      Container(
                        height: hasData ? math.max(3, 125 * bucket.value / maxValue) : 3,
                        decoration: BoxDecoration(
                          color: bucket.value == 0 ? AppTheme.deepBlue : AppTheme.electricLime,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(bucket.label, textAlign: TextAlign.center, maxLines: 1, style: const TextStyle(fontSize: 9, color: AppTheme.iceBlue)),
                    ]),
                  ),
                ),
            ],
          ),
        ),
        if (!hasData) ...[
          const SizedBox(height: 8),
          Text(
            Localizations.localeOf(context).languageCode == 'en' ? 'No records for this period and metric.' : 'Sem dados para este período e métrica.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ]),
    );
  }

  String _short(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    if (value >= 100) return value.round().toString();
    return value.toStringAsFixed(value < 10 && value != value.roundToDouble() ? 1 : 0);
  }
}
