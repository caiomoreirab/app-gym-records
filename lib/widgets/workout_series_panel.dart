import 'package:material_ui/material_ui.dart';

import '../models/workout_record.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

/// Each calendar day is represented as a workout session in this iteration.
class WorkoutSeriesPanel extends StatelessWidget {
  const WorkoutSeriesPanel({
    super.key,
    required this.records,
    required this.unit,
    required this.onRepeat,
    required this.onEdit,
    required this.onDelete,
    this.sessionId,
    this.sessionNames = const {},
    this.showCurrent = true,
    this.showHistory = true,
  });

  final List<WorkoutRecord> records;
  final String unit;
  final VoidCallback? onRepeat;
  final ValueChanged<WorkoutRecord> onEdit;
  final ValueChanged<WorkoutRecord> onDelete;
  final String? sessionId;
  final Map<String, String> sessionNames;
  final bool showCurrent;
  final bool showHistory;

  @override
  Widget build(BuildContext context) {
    final today = WorkoutRecord.dayKey(DateTime.now());
    final current = records.where(
      (r) => sessionId == null
          ? WorkoutRecord.dayKey(r.date) == today
          : r.sessionId == sessionId,
    ).toList(growable: false);
    final ordered = [...current]..sort((a, b) => a.date.compareTo(b.date));
    final previous = records.where((r) => !current.contains(r)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final grouped = <String, List<WorkoutRecord>>{};
    for (final item in previous) {
      final key = item.sessionId.isEmpty ? WorkoutRecord.dayKey(item.date) : item.sessionId;
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showCurrent) Text(sessionId == null ? 'Séries de hoje' : 'Séries desta sessão',
          style: Theme.of(context).textTheme.headlineMedium),
        if (showCurrent) const SizedBox(height: 8),
        if (showCurrent && ordered.isEmpty)
          SectionCard(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nenhuma série registrada hoje.'),
              const SizedBox(height: 6),
              Text('Defina a carga e as repetições e toque em Salvar série.',
                style: Theme.of(context).textTheme.bodySmall),
            ],
          ))
        else if (showCurrent)
          SectionCard(child: Column(
            children: [
              for (var i = 0; i < ordered.length; i++)
                _SeriesRow(
                  number: i + 1,
                  record: ordered[i],
                  unit: unit,
                  onEdit: () => onEdit(ordered[i]),
                  onDelete: () => onDelete(ordered[i]),
                ),
            ],
          )),
        if (showCurrent && ordered.isNotEmpty) ...[
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onRepeat,
            icon: const Icon(Icons.repeat_rounded),
            label: const Text('Repetir última série'),
          ),
        ],
        if (showHistory) const SizedBox(height: 22),
        if (showHistory) Text('Histórico por sessão', style: Theme.of(context).textTheme.headlineMedium),
        if (showHistory) const SizedBox(height: 10),
        if (showHistory && grouped.isEmpty)
          SectionCard(child: Text('Seu histórico de outros dias aparecerá aqui.',
              style: Theme.of(context).textTheme.bodySmall))
        else if (showHistory)
          for (final entry in grouped.entries) ...[
            SectionCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: AppTheme.electricLime, size: 17),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    sessionNames[entry.key] ??
                      (entry.value.isEmpty ? entry.key
                        : WorkoutRecord.dayKey(entry.value.first.date)),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )),
                  Text('${entry.value.length} séries',
                      style: const TextStyle(color: AppTheme.iceBlue)),
                ]),
                const SizedBox(height: 8),
                for (var i = 0; i < entry.value.length; i++)
                  _SeriesRow(
                    number: entry.value.length - i,
                    record: entry.value[i],
                    unit: unit,
                    onEdit: () => onEdit(entry.value[i]),
                    onDelete: () => onDelete(entry.value[i]),
                  ),
              ],
            )),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _SeriesRow extends StatelessWidget {
  const _SeriesRow({
    required this.number,
    required this.record,
    required this.unit,
    required this.onEdit,
    required this.onDelete,
  });

  final int number;
  final WorkoutRecord record;
  final String unit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final r = record;
    final details = [
      if (r.weight > 0)
        '${r.weight.toStringAsFixed(r.weight == r.weight.roundToDouble() ? 0 : 1)} $unit',
      if (r.repetitions != null) '× ${r.repetitions} reps',
      if (r.durationSeconds != null) '${r.durationSeconds}s',
    ].join(' ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.deepBlue,
          child: Text('$number',
              style: const TextStyle(color: AppTheme.polarWhite, fontSize: 13)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(details.isEmpty ? 'Série registrada' : details,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (r.isWarmup || r.rpe != null || r.note.isNotEmpty)
              Text([
                if (r.isWarmup) 'Aquecimento',
                if (r.rpe != null) 'RPE ${r.rpe!.toStringAsFixed(1)}',
                if (r.note.isNotEmpty) r.note,
              ].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.iceBlue, fontSize: 12)),
          ],
        )),
        IconButton(
          tooltip: 'Editar série',
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: onEdit,
        ),
        IconButton(
          tooltip: 'Excluir série',
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          onPressed: onDelete,
        ),
      ]),
    );
  }
}
