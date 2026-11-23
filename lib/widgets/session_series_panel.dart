import 'package:material_ui/material_ui.dart';

import '../models/machine.dart';
import '../models/workout_record.dart';
import '../state/app_controller.dart';
import '../services/weight_units.dart';
import '../services/strength_set_validation.dart';
import '../theme/app_theme.dart';
import 'section_card.dart';

/// Readable, non-destructive set history inside the existing exercise screen.
class SessionSeriesPanel extends StatelessWidget {
  const SessionSeriesPanel({super.key, required this.machine});
  final Machine machine;

  Future<void> _edit(BuildContext context, WorkoutRecord record) async {
    final app = AppScope.of(context);
    final unit = app.unit;
    final weight = TextEditingController(
      text: WeightUnits.toDisplay(record.weight, unit).toStringAsFixed(1));
    final reps = TextEditingController(text: record.repetitions?.toString() ?? '');
    final rpe = TextEditingController(text: record.rpe?.toStringAsFixed(0) ?? '');
    final rest = TextEditingController(text: record.restSeconds?.toString() ?? '');
    final note = TextEditingController(text: record.note);
    var warmup = record.isWarmup;
    String? weightError, repsError, effortError, restError, formError;
    try {
      final updated = await showDialog<WorkoutRecord>(context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Editar série'),
            scrollable: true,
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: weight,
                key: const Key('edit_set_weight'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Carga ($unit)', errorText: weightError)),
              TextField(controller: reps,
                key: const Key('edit_set_reps'),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Repetições', errorText: repsError)),
              TextField(controller: rpe, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Esforço RPE (1–10, opcional)', errorText: effortError)),
              TextField(controller: rest, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Descanso (segundos, opcional)', errorText: restError)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aquecimento (não conta como PR)'),
                value: warmup,
                onChanged: (v) => setDialogState(() => warmup = v)),
              TextField(controller: note, maxLength: 300,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Observação opcional')),
              if (formError != null) Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(formError!,
                  style: const TextStyle(color: AppTheme.warning))),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar')),
              FilledButton(
                onPressed: () {
                  final displayedKg = double.tryParse(
                    weight.text.trim().replaceAll(',', '.'));
                  final kg = displayedKg == null
                    ? null : WeightUnits.toKilograms(displayedKg, unit);
                  final count = reps.text.trim().isEmpty
                      ? null : int.tryParse(reps.text.trim());
                  final effort = rpe.text.trim().isEmpty
                      ? null : double.tryParse(rpe.text.replaceAll(',', '.'));
                  final seconds = rest.text.trim().isEmpty
                      ? null : int.tryParse(rest.text.trim());
                  final issue = StrengthSetValidation.error(
                    machine: machine, weight: kg ?? 0,
                    repetitions: count,
                    durationSeconds: record.durationSeconds);
                  setDialogState(() {
                    weightError = kg == null || !kg.isFinite ||
                      kg < 0 || kg > 10000
                      ? 'Informe uma carga válida.' : null;
                    repsError = (count != null && (count <= 0 || count > 1000)) ||
                      (reps.text.trim().isNotEmpty && count == null)
                      ? 'Informe repetições válidas.' : null;
                    effortError = (effort != null && (effort < 1 || effort > 10)) ||
                      (rpe.text.trim().isNotEmpty && effort == null)
                      ? 'O RPE deve estar entre 1 e 10.' : null;
                    restError = (seconds != null && (seconds < 0 || seconds > 36000)) ||
                      (rest.text.trim().isNotEmpty && seconds == null)
                      ? 'Informe descanso entre 0 e 36000 segundos.' : null;
                    formError = issue;
                  });
                  if (weightError != null || repsError != null ||
                      effortError != null || restError != null ||
                      formError != null) return;
                  Navigator.pop(dialogContext, WorkoutRecord(
                    id: record.id,
                    sessionId: record.sessionId,
                    date: record.date,
                    weight: kg!,
                    repetitions: count,
                    durationSeconds: record.durationSeconds,
                    rpe: effort,
                    rir: record.rir,
                    restSeconds: seconds,
                    note: note.text.trim(),
                    isWarmup: warmup,
                    extra: record.extra,
                  ));
                },
                child: const Text('Salvar alterações')),
            ],
          ),
        ));
      if (updated == null || !context.mounted) return;
      app.replaceRecord(machine, updated);
      await app.flushPendingWrites();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(app.persistenceError == null
            ? 'Série atualizada.' : 'Atenção: falha ao gravar edição.')));
      }
    } finally {
      weight.dispose();
      reps.dispose();
      rpe.dispose();
      rest.dispose();
      note.dispose();
    }
  }

  Future<void> _remove(BuildContext context, WorkoutRecord record) async {
    final app = AppScope.of(context);
    final yes = await showDialog<bool>(context: context,
      builder: (d) => AlertDialog(
        title: const Text('Excluir série?'),
        content: const Text('A série será removida do histórico. Você poderá desfazer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(d, true),
            child: const Text('Excluir')),
        ],
      ));
    if (yes != true || !context.mounted) return;
    final removed = app.removeRecord(machine, record.id);
    await app.flushPendingWrites();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(app.persistenceError == null
        ? 'Série excluída.' : 'Falha ao salvar exclusão no dispositivo.'),
      action: SnackBarAction(label: 'Desfazer',
        onPressed: () => app.restoreRecord(machine, removed)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final sorted = [...machine.records]
      ..sort((a,b) => b.date.compareTo(a.date));
    final bySession = <String, List<WorkoutRecord>>{};
    for (final record in sorted) {
      (bySession[record.effectiveSessionId] ??= []).add(record);
    }
    final active = app.activeSessionId;
    final sessions = bySession.entries.toList()
      ..sort((a,b) => b.value.first.date.compareTo(a.value.first.date));

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Séries e histórico por sessão',
        style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      if (sessions.isEmpty)
        const SectionCard(child: Text(
          'Nenhuma série registrada. Salve sua primeira série para começar.',
          style: TextStyle(color: AppTheme.iceBlue))),
      for (final entry in sessions) ...[
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              entry.key == active ? 'Treino em andamento' :
                app.sessions.where((s) => s.id == entry.key).isNotEmpty
                  ? app.sessions.firstWhere((s) => s.id == entry.key).name
                  : 'Treino registrado',
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${entry.value.first.date.day}/${entry.value.first.date.month}/'
              '${entry.value.first.date.year} · ${entry.value.length} série(s)',
              style: const TextStyle(color: AppTheme.iceBlue)),
            const SizedBox(height: 8),
            for (var i = 0; i < entry.value.length; i++) ...[
              if (i > 0) const Divider(height: 12),
              _SetRow(
                setNumber: entry.value.length - i,
                record: entry.value[i],
                onEdit: () => _edit(context, entry.value[i]),
                onDelete: () => _remove(context, entry.value[i])),
            ],
          ]),
        ),
        const SizedBox(height: 12),
      ],
    ]);
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.record,
    required this.setNumber,
    required this.onEdit,
    required this.onDelete,
  });
  final WorkoutRecord record;
  final int setNumber;
  final VoidCallback onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final unit = AppScope.of(context).unit;
    final parts = [
      if (record.hasWeight) '${WeightUnits.format(record.weight, unit)} $unit',
      if (record.hasRepetitions) '× ${record.repetitions} rep',
      if (record.hasDuration) '${record.durationSeconds}s',
      if (record.isWarmup) '· Aquecimento',
      if (record.rpe != null) '· RPE ${record.rpe!.toStringAsFixed(0)}',
    ];
    return Row(children: [
      SizedBox(width: 62, child: Text('Série $setNumber',
        style: const TextStyle(color: AppTheme.iceBlue, fontSize: 12))),
      Expanded(child: Text(parts.join(' '),
        maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600))),
      IconButton(
        tooltip: 'Editar série $setNumber',
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined, size: 21)),
      IconButton(
        tooltip: 'Excluir série $setNumber',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded, size: 21)),
    ]);
  }
}
