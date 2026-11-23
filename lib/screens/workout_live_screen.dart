import 'package:material_ui/material_ui.dart';
import '../l10n/app_strings.dart';
import '../models/machine.dart';
import '../models/workout_record.dart';
import '../models/workout_session.dart';
import '../services/strength_set_validation.dart';
import '../services/weight_units.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/adaptive_illustration.dart';
import '../widgets/page_body.dart';
import '../widgets/section_card.dart';
import 'exercise_catalog_screen.dart';
import 'machine_screen.dart';
import 'workout_completed_screen.dart';

/// Active workout command center. No fake sets, no server calls and
/// no changes to the existing record form or the classic visual identity.
class WorkoutLiveScreen extends StatefulWidget {
  const WorkoutLiveScreen({super.key});
  @override
  State<WorkoutLiveScreen> createState() => _WorkoutLiveScreenState();
}

class _WorkoutLiveScreenState extends State<WorkoutLiveScreen> {
  bool _finishing = false;

  Future<void> _addExercise() async {
    final app = AppScope.of(context);
    if (app.activeSession == null) return;
    final selected = await Navigator.of(context).push<Machine>(
      MaterialPageRoute(builder: (_) =>
          const ExerciseCatalogScreen(pickForWorkout: true)),
    );
    if (!mounted || selected == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.strings.t(
        'Exercício adicionado ao treino.',
        'Exercise added to your workout.',
        'Ejercicio añadido al entrenamiento.',
      )),
      action: SnackBarAction(
        label: context.strings.t('Registrar', 'Log set', 'Registrar'),
        onPressed: () => _openRecord(selected),
      ),
    ));
  }

  Future<void> _openRecord(Machine machine) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => MachineScreen(machineId: machine.id)),
    );
  }

  Future<void> _quickSet(Machine machine) async {
    final app = AppScope.of(context);
    final previous = machine.latestRecord;
    final weight = TextEditingController(
      text: previous == null ? '' :
        WeightUnits.toDisplay(previous.weight, app.unit).toStringAsFixed(1));
    final repetitions = TextEditingController(
      text: previous?.repetitions?.toString() ?? '');
    final duration = TextEditingController(
      text: previous?.durationSeconds?.toString() ?? '');
    var saving = false;
    String? error;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: AppTheme.surfaceNavy,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, update) => SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20, 8, 20,
                20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(context.strings.t('Registrar série',
                      'Log a set', 'Registrar serie'),
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 5),
                    Text(machine.localizedName(Localizations.localeOf(context)),
                      style: const TextStyle(color: AppTheme.iceBlue)),
                    const SizedBox(height: 8),
                    Text(previous == null
                      ? context.strings.t('Informe o que você fez.',
                        'Enter what you completed.', 'Registra lo que hiciste.')
                      : context.strings.t(
                        'Valores preenchidos a partir da última série. Confira antes de salvar.',
                        'Pre-filled from the last set. Review before saving.',
                        'Datos de la última serie. Revísalos antes de guardar.'),
                      style: const TextStyle(color: AppTheme.iceBlue,
                        fontSize: 13)),
                    const SizedBox(height: 15),
                    if (machine.supportsWeight || machine.equipment
                        != EquipmentType.bodyweight)
                      TextField(
                        key: const Key('live_quick_weight'),
                        controller: weight,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                        decoration: InputDecoration(
                          labelText: context.strings.t(
                            'Carga (${app.unit})', 'Weight (${app.unit})',
                            'Peso (${app.unit})'),
                          prefixIcon: const Icon(Icons.fitness_center_outlined),
                        ),
                      ),
                    if (machine.supportsRepetitions) ...[
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('live_quick_repetitions'),
                        controller: repetitions,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.strings.t(
                            'Repetições', 'Repetitions', 'Repeticiones'),
                          prefixIcon: const Icon(Icons.repeat_rounded),
                        ),
                      ),
                    ],
                    if (machine.supportsDuration) ...[
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('live_quick_duration'),
                        controller: duration,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.strings.t(
                            'Duração em segundos', 'Duration in seconds',
                            'Duración en segundos'),
                          prefixIcon: const Icon(Icons.timer_outlined),
                        ),
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(error!, style: const TextStyle(
                        color: AppTheme.warning, fontSize: 13)),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      key: const Key('live_save_quick_set'),
                      onPressed: saving ? null : () async {
                        final entered = double.tryParse(
                          weight.text.trim().replaceAll(',', '.'));
                        final kg = WeightUnits.toKilograms(entered ?? 0, app.unit);
                        final reps = repetitions.text.trim().isEmpty
                          ? null : int.tryParse(repetitions.text.trim());
                        final seconds = duration.text.trim().isEmpty
                          ? null : int.tryParse(duration.text.trim());
                        final problem =
                          (weight.text.trim().isNotEmpty && entered == null) ||
                          (repetitions.text.trim().isNotEmpty && reps == null) ||
                          (duration.text.trim().isNotEmpty && seconds == null)
                            ? context.strings.t('Use números válidos.',
                              'Enter valid numbers.', 'Usa números válidos.')
                            : StrengthSetValidation.error(
                              machine: machine, weight: kg,
                              repetitions: reps, durationSeconds: seconds);
                        if (problem != null) {
                          update(() => error = problem);
                          return;
                        }
                        update(() { saving = true; error = null; });
                        try {
                          app.addRecord(machine, weight: kg,
                            repetitions: reps, durationSeconds: seconds);
                          await app.flushPendingWrites();
                          if (!sheetContext.mounted) return;
                          if (app.persistenceError != null) {
                            Navigator.of(sheetContext).pop();
                            if (mounted) ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text(
                                'Série na memória, mas não foi possível salvá-la '
                                'no dispositivo. Faça backup dos dados.')));
                          } else {
                            Navigator.of(sheetContext).pop();
                            if (mounted) ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                                content: Text(context.strings.t(
                                  'Série salva.', 'Set saved.', 'Serie guardada.')),
                              ));
                          }
                        } catch (e) {
                          if (sheetContext.mounted) {
                            update(() => error = e.toString());
                          }
                        } finally {
                          if (sheetContext.mounted) {
                            update(() => saving = false);
                          }
                        }
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: Text(saving
                        ? context.strings.t('Salvando...', 'Saving...',
                            'Guardando...')
                        : context.strings.t('Salvar série', 'Save set',
                            'Guardar serie')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      weight.dispose();
      repetitions.dispose();
      duration.dispose();
    }
  }

  Future<void> _removeUnused(Machine machine) async {
    final app = AppScope.of(context);
    try {
      app.removeUnusedExerciseFromSession(machine.id);
      await app.flushPendingWrites();
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    final app = AppScope.of(context);
    final session = app.activeSession;
    if (session == null) return;
    final count = session.pendingCount;
    final totalSets = app.recordsForSession(session.id).length;
    final shouldConfirm = count > 0 || totalSets == 0;
    if (shouldConfirm) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(context.strings.t('Finalizar treino?',
            'Finish workout?', '¿Finalizar entrenamiento?')),
          content: Text(count > 0
            ? context.strings.t(
              '$count exercício(s) ainda não foram marcados como concluídos. '
              'Seu histórico de séries será mantido.',
              '$count exercise(s) are still unchecked. Saved sets stay intact.',
              'Quedan $count ejercicios sin completar. Las series se conservan.')
            : context.strings.t(
              'Nenhuma série foi registrada. Deseja finalizar mesmo assim?',
              'No sets were logged. Finish anyway?',
              'No se registraron series. ¿Finalizar de todos modos?')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog, false),
              child: Text(context.strings.t('Continuar treino',
                'Keep working out', 'Seguir entrenando'))),
            FilledButton(onPressed: () => Navigator.pop(dialog, true),
              child: Text(context.strings.t('Finalizar', 'Finish', 'Finalizar'))),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
    }
    setState(() => _finishing = true);
    final done = app.completeSession();
    if (done == null) {
      if (mounted) setState(() => _finishing = false);
      return;
    }
    await app.flushPendingWrites();
    if (!mounted) return;
    if (app.persistenceError != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Treino concluído, mas ocorreu uma falha ao salvar. '
          'Faça backup antes de sair do aplicativo.')));
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => WorkoutCompletedScreen(sessionId: done.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final session = app.activeSession;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treino')),
        body: const Center(child: Text('Nenhum treino em andamento.')),
      );
    }
    final machines = <Machine>[];
    for (final id in session.exerciseIds) {
      for (final machine in app.availableMachines) {
        if (machine.id == id) {
          machines.add(machine);
          break;
        }
      }
    }
    final total = session.exerciseIds.length;
    final completed = session.completedCount;
    final records = app.recordsForSession(session.id);
    final startedAt = session.startedAt.toLocal();
    final elapsed = DateTime.now().difference(session.startedAt);
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        title: Text(context.strings.t(
          'Treino em andamento', 'Workout in progress',
          'Entrenamiento en curso')),
        actions: [
          IconButton(
            tooltip: context.strings.t(
              'Adicionar exercício', 'Add exercise', 'Añadir ejercicio'),
            icon: const Icon(Icons.add_rounded),
            onPressed: _addExercise,
          ),
        ],
      ),
      body: PageBody(child: ListView(
        key: const Key('live_workout_list'),
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          SectionCard(child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Icon(Icons.timer_outlined,
                  color: AppTheme.electricLime),
                const SizedBox(width: 8),
                Expanded(child: Text(session.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge)),
                Text('${startedAt.hour.toString().padLeft(2, '0')}:'
                  '${startedAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: AppTheme.iceBlue)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                SizedBox(height: 50, width: 50,
                  child: Stack(alignment: Alignment.center, children: [
                    CircularProgressIndicator(value: session.progress,
                      strokeWidth: 5, backgroundColor: AppTheme.deepBlue,
                      color: AppTheme.electricLime),
                    Text('$completed/$total',
                      style: const TextStyle(fontWeight: FontWeight.w600,
                        fontSize: 12)),
                  ]),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.strings.t('Exercícios concluídos',
                      'Exercises finished', 'Ejercicios completados'),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${records.length} ${context.strings.t(
                      'séries registradas', 'sets logged', 'series registradas')}'
                      ' · ${elapsed.inMinutes < 0 ? 0 : elapsed.inMinutes} min',
                      style: const TextStyle(color: AppTheme.iceBlue,
                        fontSize: 12)),
                  ],
                )),
              ]),
            ],
          )),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: Text(context.strings.t(
              'Seus exercícios', 'Your exercises', 'Tus ejercicios'),
              style: Theme.of(context).textTheme.titleLarge)),
            Text('$completed/$total', style: const TextStyle(
              color: AppTheme.electricLime,
              fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          if (machines.isEmpty) ...[
            SectionCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.strings.t(
                  'Nenhum exercício adicionado',
                  'No exercises added',
                  'No hay ejercicios añadidos'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 7),
                Text(context.strings.t(
                  'Use Adicionar exercício para montar o treino. '
                  'Você pode registrar as séries conforme executa.',
                  'Use Add exercise and log each set as you go.',
                  'Añade ejercicios y registra las series al entrenar.'),
                  style: const TextStyle(color: AppTheme.iceBlue)),
              ],
            )),
          ],
          for (var i = 0; i < machines.length; i++) ...[
            _ActiveExerciseCard(
              key: ValueKey('live_exercise_${machines[i].id}'),
              machine: machines[i],
              session: session,
              app: app,
              index: i + 1,
              onToggle: (value) =>
                  app.setExerciseCompleted(machines[i].id, value),
              onLog: () => _openRecord(machines[i]),
              onQuick: () => _quickSet(machines[i]),
              onRemove: () => _removeUnused(machines[i]),
            ),
            const SizedBox(height: 10),
          ],
        ],
      )),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceNavy,
            border: Border(top: BorderSide(color: AppTheme.deepBlue)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FilledButton.icon(
              key: const Key('live_add_exercise'),
              onPressed: _addExercise,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: Text(context.strings.t('Adicionar exercício',
                'Add exercise', 'Añadir ejercicio')),
            ),
            const SizedBox(height: 7),
            OutlinedButton.icon(
              key: const Key('live_finish_workout'),
              onPressed: _finishing ? null : _finish,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(_finishing
                ? context.strings.t('Salvando...', 'Saving...', 'Guardando...')
                : context.strings.t('Finalizar treino',
                  'Finish workout', 'Finalizar entrenamiento')),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ActiveExerciseCard extends StatelessWidget {
  const _ActiveExerciseCard({
    super.key,
    required this.machine,
    required this.session,
    required this.app,
    required this.index,
    required this.onToggle,
    required this.onLog,
    required this.onQuick,
    required this.onRemove,
  });

  final Machine machine;
  final WorkoutSession session;
  final AppController app;
  final int index;
  final ValueChanged<bool> onToggle;
  final VoidCallback onLog, onQuick, onRemove;

  @override
  Widget build(BuildContext context) {
    final done = session.isExerciseCompleted(machine.id);
    final sets = machine.records
        .where((r) => r.effectiveSessionId == session.id)
        .toList()..sort((a,b) => a.date.compareTo(b.date));
    final WorkoutRecord? latest = sets.isNotEmpty
        ? sets.last : machine.latestRecord;
    final canRemove = sets.isEmpty;
    final status = done
      ? context.strings.t('Concluído', 'Completed', 'Completado')
      : sets.isNotEmpty
        ? context.strings.t('Em andamento', 'In progress', 'En curso')
        : context.strings.t('Não iniciado', 'Not started', 'Sin empezar');
    return SectionCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 67, height: 67,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: AdaptiveExerciseImage(machine: machine,
                  width: 67, height: 67, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$index. ${machine.localizedName(
                  Localizations.localeOf(context))}',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${sets.length} ${context.strings.t(
                  'séries', 'sets', 'series')} · $status',
                  style: TextStyle(color: done
                    ? AppTheme.success : AppTheme.iceBlue, fontSize: 12)),
                if (latest != null) ...[
                  const SizedBox(height: 5),
                  Text([
                    if (latest.weight > 0)
                      '${WeightUnits.format(latest.weight, app.unit)} ${app.unit}',
                    if (latest.repetitions != null)
                      '${latest.repetitions} rep',
                    if (latest.durationSeconds != null)
                      '${latest.durationSeconds}s',
                  ].join(' · '),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.iceBlue,
                      fontSize: 12)),
                ],
              ],
            )),
            Checkbox(
              key: Key('live_done_${machine.id}'),
              value: done,
              onChanged: (value) => onToggle(value ?? false),
              semanticLabel: done
                ? context.strings.t('Reabrir exercício',
                  'Reopen exercise', 'Reabrir ejercicio')
                : context.strings.t('Marcar exercício concluído',
                  'Mark exercise completed', 'Marcar ejercicio completado'),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            key: Key('live_log_${machine.id}'),
            onPressed: onLog,
            icon: const Icon(Icons.edit_note_rounded, size: 20),
            label: Text(context.strings.t('Registrar',
              'Log set', 'Registrar')),
          )),
          const SizedBox(width: 9),
          Expanded(child: FilledButton.icon(
            key: Key('live_repeat_${machine.id}'),
            onPressed: onQuick,
            icon: Icon(latest == null
              ? Icons.add_rounded : Icons.repeat_rounded, size: 20),
            label: Text(latest == null
              ? context.strings.t('Série rápida',
                'Quick set', 'Serie rápida')
              : context.strings.t('Repetir série',
                'Repeat set', 'Repetir serie')),
          )),
        ]),
        if (canRemove) Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
            label: Text(context.strings.t('Remover do treino',
              'Remove from workout', 'Quitar del entrenamiento')),
          ),
        ),
      ],
    ));
  }
}
