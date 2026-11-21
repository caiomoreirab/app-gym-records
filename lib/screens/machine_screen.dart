import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/machine.dart';
import '../models/workout_record.dart';
import '../services/pro_insights.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/adaptive_illustration.dart';
import '../widgets/page_body.dart';
import '../widgets/primary_bottom_bar.dart';
import '../widgets/record_achievement_sheet.dart';
import '../widgets/section_card.dart';
import '../widgets/workout_series_panel.dart';
import '../widgets/rest_timer_card.dart';
import 'exercise_insights_screen.dart';
import 'pro_overview_screen.dart';

class MachineScreen extends StatefulWidget {
  const MachineScreen({super.key, required this.machineId});

  final String machineId;

  @override
  State<MachineScreen> createState() => _MachineScreenState();
}

class _MachineScreenState extends State<MachineScreen> {
  bool _initialized = false;
  bool _saving = false;
  bool _isWarmup = false;
  double _weight = 0;
  int? _repetitions;
  bool _showAdditionalWeight = false;
  int _minutes = 0;
  int _seconds = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final machine = AppScope.of(context).machineById(widget.machineId);
    final latest = machine.latestRecord;
    _weight = latest?.weight ?? 0;
    _repetitions = latest?.repetitions ?? (machine.prefersBodyMetrics ? null : 10);
    _showAdditionalWeight = latest?.hasWeight ?? false;
    final duration = latest?.duration;
    _minutes = duration?.inMinutes ?? 0;
    _seconds = duration?.inSeconds.remainder(60) ?? 0;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final machine = app.machineById(widget.machineId);

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(machine.localizedName(Localizations.localeOf(context))),
        actions: [
          IconButton(
            tooltip: app.isFavorite(machine.id)
                ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
            icon: Icon(app.isFavorite(machine.id) ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppTheme.electricLime),
            onPressed: () => app.toggleFavorite(machine.id),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'rename') _renameMachine(machine);
              if (value == 'delete') _confirmDelete(machine);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Renomear aparelho')),
              PopupMenuItem(value: 'delete', child: Text('Apagar aparelho')),
            ],
          ),
        ],
      ),
      bottomNavigationBar: PrimaryBottomBar(
        label: 'Salvar série',
        onPressed: !_saving && _canSave(machine) ? () => _saveRecord(machine) : null,
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            ExerciseVisualPager(
              machine: machine,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              showLabel: true,
            ),
            const SizedBox(height: 16),
            _RecordCard(machine: machine, unit: app.unit),
            const SizedBox(height: 16),
            _NoteCard(note: machine.note, onEdit: () => _editNote(machine)),
            const SizedBox(height: 10),
            _AdjustmentsCard(machine: machine, onEdit: () => _editAdjustments(machine)),
            const SizedBox(height: 16),
            _WeightCard(
              machine: machine,
              showAdditionalWeight: _showAdditionalWeight,
              onToggleAdditionalWeight: () => setState(() { _showAdditionalWeight = !_showAdditionalWeight; if (!_showAdditionalWeight) _weight = 0; }),
              weight: _weight,
              unit: app.unit,
              increment: app.increment,
              repetitions: _repetitions,
              minutes: _minutes,
              seconds: _seconds,
              onWeightChanged: (value) => setState(() => _weight = value.clamp(0, 250).toDouble()),
              onTapWeight: _editWeight,
              onRepetitionsChanged: (value) => setState(() => _repetitions = value),
              onMinutesChanged: (value) => setState(() => _minutes = value.clamp(0, 999)),
              onSecondsChanged: (value) => setState(() => _seconds = value.clamp(0, 59)),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Série de aquecimento'),
              subtitle: const Text('Não entra no cálculo de recordes.'),
              value: _isWarmup,
              onChanged: (value) => setState(() => _isWarmup = value ?? false),
            ),
            const SizedBox(height: 14),
            WorkoutSeriesPanel(
              records: machine.records,
              unit: app.unit,
              onRepeat: _saving ? null : () => _repeatLastSet(machine),
              onEdit: (record) => _editSeries(machine, record),
              onDelete: (record) => _deleteSeries(machine, record),
            ),
            const SizedBox(height: 14),
            const RestTimerCard(),
            const SizedBox(height: 16),
            _StrengthRecordsSummary(machine: machine, unit: app.unit),
            const SizedBox(height: 18),
            _MachineProCard(
              machine: machine,
              unit: app.unit,
              increment: app.increment,
              enabled: app.isPro,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => app.isPro ? ExerciseInsightsScreen(machineId: machine.id) : const ProOverviewScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSave(Machine machine) {
    final durationSeconds = _minutes * 60 + _seconds;
    if (machine.prefersBodyMetrics) {
      return _weight > 0 || (_repetitions ?? 0) > 0 || durationSeconds > 0;
    }
    return _weight > 0 && (_repetitions ?? 0) > 0;
  }

  bool _isHighlightRecord(Machine machine, WorkoutRecord record) {
    if (record.hasWeight && record.weight == machine.recordWeight) return true;
    if (machine.recordWeight == 0 && record.hasRepetitions && record.repetitions == machine.bestRepetitions) return true;
    if (machine.recordWeight == 0 && machine.bestRepetitions == 0 && record.hasDuration && record.durationSeconds == machine.bestDurationSeconds) return true;
    return false;
  }

  Future<void> _saveRecord(Machine machine) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
    final app = AppScope.of(context);
    final previousWeight = machine.recordWeight;
    final previousRepetitions = machine.bestRepetitions;
    final previousDurationSeconds = machine.bestDurationSeconds;
    final durationSeconds = _minutes * 60 + _seconds;

    app.addRecord(
      machine,
      weight: _weight,
      repetitions: (_repetitions ?? 0) > 0 ? _repetitions : null,
      durationSeconds: durationSeconds > 0 ? durationSeconds : null,
      isWarmup: _isWarmup,
    );
    // Do not announce a successful save or PR until the local database
    // acknowledges the write. Retain the in-memory record for recovery.
    await app.flushPendingWrites();
    if (!mounted) return;
    if (app.persistenceError != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('O registro está na memória, mas não foi salvo no aparelho. '
            'Abra Configurações → Dados e privacidade para tentar novamente.'),
      ));
      return;
    }
    HapticFeedback.lightImpact();

    final isNewWeight = !_isWarmup && _weight > 0 && _weight > previousWeight;
    final isNewReps = !_isWarmup && (_repetitions ?? 0) > 0 &&
        _repetitions! > previousRepetitions;
    final isNewDuration = durationSeconds > 0 && durationSeconds > previousDurationSeconds;

    if (isNewWeight || isNewReps || isNewDuration) {
      await showRecordAchievementSheet(
        context: context,
        machine: machine,
        previousWeight: previousWeight,
        previousRepetitions: previousRepetitions,
        previousDurationSeconds: previousDurationSeconds,
        metric: isNewWeight ? StrengthAchievementMetric.weight : isNewReps ? StrengthAchievementMetric.repetitions : StrengthAchievementMetric.duration,
      );
      if (mounted) setState(() {});
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.strings.t('Registro salvo.', 'Record saved.', 'Registro guardado.'))),
    );
    setState(() {});
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


  Future<void> _repeatLastSet(Machine machine) async {
    if (_saving || machine.records.isEmpty) return;
    final now = DateTime.now();
    final todays = machine.records.where(
      (r) => WorkoutRecord.dayKey(r.date) == WorkoutRecord.dayKey(now),
    ).toList()..sort((a, b) => b.date.compareTo(a.date));
    final last = todays.isNotEmpty ? todays.first : machine.latestRecord!;
    setState(() => _saving = true);
    try {
      final app = AppScope.of(context);
      app.addRecord(machine,
        weight: last.weight,
        repetitions: last.repetitions,
        durationSeconds: last.durationSeconds,
        isWarmup: last.isWarmup,
        rpe: last.rpe,
        note: last.note,
      );
      await app.flushPendingWrites();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(app.persistenceError == null
            ? 'Série repetida e salva.' : 'Erro de armazenamento. Verifique seus dados.'),
      ));
      setState(() {
        _weight = last.weight;
        _repetitions = last.repetitions;
        _isWarmup = last.isWarmup;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editSeries(Machine machine, WorkoutRecord record) async {
    final weightController = TextEditingController(text: record.weight.toString());
    final repsController = TextEditingController(text: record.repetitions?.toString() ?? '');
    var warmup = record.isWarmup;
    final updated = await showDialog<WorkoutRecord>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceNavy,
          title: const Text('Editar série'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Carga (kg)'),
            ),
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Repetições'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aquecimento'),
              value: warmup,
              onChanged: (v) => setDialogState(() => warmup = v ?? false),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final weight = double.tryParse(
                  weightController.text.replaceAll(',', '.'));
                final reps = int.tryParse(repsController.text);
                if (weight == null || weight < 0 || weight > 250 ||
                    (reps != null && (reps <= 0 || reps > 500))) return;
                if (weight == 0 && reps == null) return;
                Navigator.pop(dialogContext, record.copyWith(
                  weight: weight,
                  repetitions: reps,
                  isWarmup: warmup,
                ));
              },
              child: const Text('Salvar alterações'),
            ),
          ],
        ),
      ),
    );
    weightController.dispose();
    repsController.dispose();
    if (updated == null || !mounted) return;
    final app = AppScope.of(context);
    app.updateRecord(machine, record, updated);
    await app.flushPendingWrites();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        app.persistenceError == null ? 'Série atualizada.' : 'Não foi possível salvar no dispositivo.',
      )));
    }
  }

  Future<void> _deleteSeries(Machine machine, WorkoutRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceNavy,
        title: const Text('Excluir esta série?'),
        content: const Text('Você poderá desfazer a exclusão logo em seguida.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final app = AppScope.of(context);
    app.removeRecord(machine, record);
    await app.flushPendingWrites();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(app.persistenceError == null
          ? 'Série excluída.' : 'Falha ao persistir exclusão.'),
      action: SnackBarAction(
        label: 'Desfazer',
        onPressed: () => app.restoreRecord(machine, record),
      ),
    ));
  }

  Future<void> _editWeight() async {
    final controller = TextEditingController(text: formatWeight(_weight, Localizations.localeOf(context)));
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceNavy,
        title: Text(context.strings.t('Definir peso', 'Set weight', 'Definir peso')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'kg'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.strings.t('Cancelar', 'Cancel', 'Cancelar'))),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.replaceAll(',', '.'));
              Navigator.of(dialogContext).pop(parsed);
            },
            child: Text(context.strings.t('Aplicar', 'Apply', 'Aplicar')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && mounted) setState(() => _weight = value.clamp(0, 250).toDouble());
  }

  Future<void> _editAdjustments(Machine machine) async {
    const labels = <String, String>{
      'seat': 'Altura do banco/assento',
      'backrest': 'Posição do encosto',
      'grip': 'Pegada',
      'other': 'Outra regulagem',
    };
    final controllers = {
      for (final entry in labels.entries)
        entry.key: TextEditingController(text: machine.adjustments[entry.key] ?? ''),
    };
    try {
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppTheme.surfaceNavy,
          title: const Text('Ficha de regulagem'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Guarde como você deixou o aparelho para repetir na próxima visita.'),
              const SizedBox(height: 12),
              for (final entry in labels.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: controllers[entry.key],
                    maxLength: 120,
                    decoration: InputDecoration(labelText: entry.value),
                  ),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop({
                for (final entry in controllers.entries) entry.key: entry.value.text.trim(),
              }),
              child: const Text('Salvar regulagens'),
            ),
          ],
        ),
      );
      if (result != null && mounted) {
        AppScope.of(context).updateMachineAdjustments(machine, result);
      }
    } finally {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
  }

  Future<void> _editNote(Machine machine) async {
    final controller = TextEditingController(text: machine.note);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceNavy,
        title: Text(context.strings.t('Ajustes do aparelho', 'Equipment settings', 'Ajustes del equipo')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          maxLength: 120,
          decoration: InputDecoration(hintText: context.strings.t('Ex.: Banco na posição 4', 'E.g. Seat at position 4', 'Ej.: Asiento en posición 4')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.strings.t('Cancelar', 'Cancel', 'Cancelar'))),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text), child: Text(context.strings.t('Salvar', 'Save', 'Guardar'))),
        ],
      ),
    );
    controller.dispose();
    if (result != null && mounted) AppScope.of(context).updateMachineNote(machine, result);
  }

  Future<void> _renameMachine(Machine machine) async {
    final controller = TextEditingController(text: machine.localizedName(Localizations.localeOf(context)));
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceNavy,
        title: Text(context.strings.t('Renomear exercício', 'Rename exercise', 'Renombrar ejercicio')),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.strings.t('Cancelar', 'Cancel', 'Cancelar'))),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()), child: Text(context.strings.t('Salvar', 'Save', 'Guardar'))),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty && mounted) AppScope.of(context).renameMachine(machine, result);
  }

  Future<void> _confirmDelete(Machine machine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceNavy,
        title: Text(context.strings.t('Apagar exercício?', 'Delete exercise?', '¿Eliminar ejercicio?')),
        content: Text(context.strings.t('Nesta prévia os dados são mockados, mas o fluxo de confirmação já está pronto.', 'In this preview the data is mocked, but the confirmation flow is ready.', 'En esta vista previa los datos son simulados, pero el flujo de confirmación ya está listo.')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(context.strings.t('Cancelar', 'Cancel', 'Cancelar'))),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(context.strings.t('Apagar', 'Delete', 'Eliminar'))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      AppScope.of(context).deleteMachine(machine);
      Navigator.of(context).pop();
    }
  }
}

class _AdjustmentsCard extends StatelessWidget {
  const _AdjustmentsCard({required this.machine, required this.onEdit});
  final Machine machine;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final values = machine.adjustments.values.where((v) => v.trim().isNotEmpty);
    return SectionCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.tune_rounded, color: AppTheme.electricLime),
        title: const Text('Minha regulagem do aparelho'),
        subtitle: Text(values.isEmpty
            ? 'Anote banco, encosto e pegada para a próxima vez.'
            : machine.adjustments.entries.where((e) => e.value.isNotEmpty)
                .map((e) => '${e.key}: ${e.value}').join(' · '),
            maxLines: 3, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.edit_outlined),
        onTap: onEdit,
      ),
    );
  }
}

class _StrengthRecordsSummary extends StatelessWidget {
  const _StrengthRecordsSummary({required this.machine, required this.unit});
  final Machine machine;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final working = machine.records.where((r) => !r.isWarmup && r.weight > 0).toList();
    if (working.isEmpty) {
      return SectionCard(child: const Text(
        'Registre uma série de trabalho para comparar seus recordes.',
      ));
    }
    var maxWeight = 0.0;
    var maxRange = 0.0;
    var estimatedOneRm = 0.0;
    for (final r in working) {
      if (r.weight > maxWeight) maxWeight = r.weight;
      final reps = r.repetitions ?? 0;
      if (reps >= 8 && reps <= 12 && r.weight > maxRange) maxRange = r.weight;
      if (reps >= 1 && reps <= 12) {
        final estimate = r.weight * (1 + reps / 30);
        if (estimate > estimatedOneRm) estimatedOneRm = estimate;
      }
    }
    return SectionCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seus recordes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Séries de aquecimento não entram nos cálculos.',
            style: TextStyle(color: AppTheme.iceBlue, fontSize: 12)),
        const SizedBox(height: 14),
        _recordLine('Maior carga', '${maxWeight.toStringAsFixed(1)} $unit'),
        _recordLine('Maior carga (8–12 reps)',
            maxRange > 0 ? '${maxRange.toStringAsFixed(1)} $unit' : 'Sem dados'),
        _recordLine('Carga máxima estimada (1RM)',
            estimatedOneRm > 0
                ? '${estimatedOneRm.toStringAsFixed(1)} $unit'
                : 'Sem dados'),
        const Text('1RM estimado pela fórmula de Epley, com séries de 1 a 12 repetições. '
                   'É uma estimativa, não uma recomendação de tentativa máxima.',
            style: TextStyle(color: AppTheme.iceBlue, fontSize: 11)),
      ],
    ));
  }

  Widget _recordLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Expanded(child: Text(label)),
      Text(value, style: const TextStyle(
        color: AppTheme.electricLime, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _MachineProCard extends StatelessWidget {
  const _MachineProCard({required this.machine, required this.unit, required this.increment, required this.enabled, required this.onTap});
  final Machine machine;
  final String unit;
  final double increment;
  final bool enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final insight = ProInsights.forMachine(machine, increment);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: AppTheme.cardElevated,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppTheme.electricLime.withValues(alpha: .65)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: AppTheme.accentBlueSoft, borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.radar_rounded, color: AppTheme.electricLime, size: 29),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('GymRecords IQ', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.accentBlueSoft, borderRadius: BorderRadius.circular(999)),
                          child: Text(enabled ? 'PRO' : 'BLOQUEADO', style: const TextStyle(color: AppTheme.electricLime, fontSize: 9, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      enabled
                          ? context.strings.t(
                              'PR Radar ${insight.probabilityLabelFor(Localizations.localeOf(context)).toLowerCase()} • próximo alvo ${formatWeight(insight.nextTarget, Localizations.localeOf(context))} $unit × ${insight.targetRepetitions}',
                              'PR Radar ${insight.probabilityLabelFor(Localizations.localeOf(context)).toLowerCase()} • next target ${formatWeight(insight.nextTarget, Localizations.localeOf(context))} $unit × ${insight.targetRepetitions}',
                              'PR Radar ${insight.probabilityLabelFor(Localizations.localeOf(context)).toLowerCase()} • próximo objetivo ${formatWeight(insight.nextTarget, Localizations.localeOf(context))} $unit × ${insight.targetRepetitions}',
                            )
                          : context.strings.t('PR Radar, próximo alvo e análise de recordes.', 'PR Radar, next target and record analysis.', 'PR Radar, próximo objetivo y análisis de récords.'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.25),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.electricLime),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.machine, required this.unit});
  final Machine machine;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final bestDate = machine.records.isEmpty
        ? null
        : machine.records.where((record) {
            if (machine.recordWeight > 0) return record.weight == machine.recordWeight;
            if (machine.bestRepetitions > 0) return record.repetitions == machine.bestRepetitions;
            return record.durationSeconds == machine.bestDurationSeconds;
          }).map((record) => record.date).reduce((a, b) => a.isAfter(b) ? a : b);

    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/branding/icon_blue.png', width: 92, height: 92),
          const SizedBox(width: 16),
          Container(width: 1, height: 92, color: AppTheme.deepBlue),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.strings.t('Recorde', 'Record', 'Récord'), style: const TextStyle(color: AppTheme.iceBlue, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  _machinePrimaryDisplay(machine, unit, Localizations.localeOf(context)),
                  style: const TextStyle(color: AppTheme.electricLime, fontSize: 40, fontWeight: FontWeight.w600, height: 1),
                ),
                if (bestDate != null) ...[
                  const SizedBox(height: 7),
                  Text(formatFullDate(bestDate, Localizations.localeOf(context)), style: const TextStyle(color: AppTheme.iceBlue)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onEdit});
  final String note;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.strings.t('Ajustes do aparelho', 'Equipment settings', 'Ajustes del equipo'), style: const TextStyle(color: AppTheme.iceBlue, fontSize: 14)),
              const SizedBox(height: 6),
              Text(note.isEmpty ? context.strings.t('Toque para adicionar uma observação fixa.', 'Tap to add a fixed note.', 'Toca para añadir una nota fija.') : note, style: Theme.of(context).textTheme.bodyLarge),
            ]),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({
    required this.machine,
    required this.showAdditionalWeight,
    required this.onToggleAdditionalWeight,
    required this.weight,
    required this.unit,
    required this.increment,
    required this.repetitions,
    required this.minutes,
    required this.seconds,
    required this.onWeightChanged,
    required this.onTapWeight,
    required this.onRepetitionsChanged,
    required this.onMinutesChanged,
    required this.onSecondsChanged,
  });

  final Machine machine;
  final bool showAdditionalWeight;
  final VoidCallback onToggleAdditionalWeight;
  final double weight;
  final String unit;
  final double increment;
  final int? repetitions;
  final int minutes;
  final int seconds;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onTapWeight;
  final ValueChanged<int?> onRepetitionsChanged;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<int> onSecondsChanged;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (machine.prefersBodyMetrics) ...[
            OutlinedButton.icon(
              onPressed: onToggleAdditionalWeight,
              icon: Icon(showAdditionalWeight ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded),
              label: Text(showAdditionalWeight ? context.strings.t('Remover carga adicional', 'Remove extra load', 'Quitar carga adicional') : context.strings.t('Adicionar carga extra (opcional)', 'Add extra load (optional)', 'Añadir carga extra (opcional)')),
            ),
            if (showAdditionalWeight) const SizedBox(height: 12),
          ],
          if (!machine.prefersBodyMetrics || showAdditionalWeight) ...[
            Text(machine.prefersBodyMetrics ? context.strings.t('Carga adicional', 'Additional load', 'Carga adicional') : context.strings.t('Peso', 'Weight', 'Peso'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                _RoundControl(icon: Icons.remove_rounded, onTap: () => onWeightChanged((weight - increment).clamp(0, 250).toDouble())),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onTapWeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: formatWeight(weight, Localizations.localeOf(context)), style: const TextStyle(color: AppTheme.polarWhite, fontSize: 66, fontWeight: FontWeight.w600, height: 1)),
                          TextSpan(text: ' $unit', style: const TextStyle(color: AppTheme.iceBlue, fontSize: 20)),
                        ]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                _RoundControl(icon: Icons.add_rounded, onTap: () => onWeightChanged((weight + increment).clamp(0, 250).toDouble())),
              ],
            ),
            Slider(value: weight.clamp(0, 250).toDouble(), min: 0, max: 250, divisions: 100, onChanged: onWeightChanged),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('0', style: TextStyle(color: AppTheme.iceBlue)), Text('250', style: TextStyle(color: AppTheme.iceBlue))]),
            ),
            if (!machine.prefersBodyMetrics) ...[
              const SizedBox(height: 12),
              Row(children: [Text(context.strings.t('Incremento', 'Increment', 'Incremento'), style: const TextStyle(color: AppTheme.iceBlue)), const Spacer(), _IncrementChip(label: '1', selected: increment == 1), const SizedBox(width: 8), _IncrementChip(label: '2,5', selected: increment == 2.5), const SizedBox(width: 8), _IncrementChip(label: '5', selected: increment == 5)]),
            ],
          ],
          if (machine.supportsRepetitions) ...[
            if (!machine.prefersBodyMetrics || showAdditionalWeight) const SizedBox(height: 18),
            if (!machine.prefersBodyMetrics || showAdditionalWeight) const Divider(),
            if (!machine.prefersBodyMetrics || showAdditionalWeight) const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [TextSpan(text: context.strings.t('Repetições ', 'Repetitions ', 'Repeticiones ')), TextSpan(text: '(${context.strings.optional})', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.iceBlue))]),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _RoundControl(icon: Icons.remove_rounded, onTap: () { final value = repetitions ?? 0; onRepetitionsChanged(value <= 1 ? null : value - 1); }),
                SizedBox(width: 62, child: Text(repetitions?.toString() ?? '—', textAlign: TextAlign.center, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w600))),
                _RoundControl(icon: Icons.add_rounded, onTap: () => onRepetitionsChanged((repetitions ?? 0) + 1)),
              ],
            ),
          ],
          if (machine.supportsDuration) ...[
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(children: [TextSpan(text: context.strings.t('Tempo ', 'Duration ', 'Tiempo ')), TextSpan(text: '(${context.strings.optional})', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.iceBlue))]),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _TimeStepper(label: context.strings.t('Minutos', 'Minutes', 'Minutos'), value: minutes, onDecrement: () => onMinutesChanged(minutes - 1), onIncrement: () => onMinutesChanged(minutes + 1))),
                const SizedBox(width: 12),
                Expanded(child: _TimeStepper(label: context.strings.t('Segundos', 'Seconds', 'Segundos'), value: seconds, onDecrement: () => onSecondsChanged(seconds - 1), onIncrement: () => onSecondsChanged(seconds + 1))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(color: AppTheme.deepNavy, shape: BoxShape.circle, border: Border.all(color: AppTheme.deepBlue, width: 1.5)),
          child: Icon(icon, color: AppTheme.polarWhite, size: 28),
        ),
      );
}

class _IncrementChip extends StatelessWidget {
  const _IncrementChip({required this.label, required this.selected});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
        height: 38,
        constraints: const BoxConstraints(minWidth: 58),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: selected ? AppTheme.royalBlue : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppTheme.royalBlue : AppTheme.deepBlue)),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}

class _TimeStepper extends StatelessWidget {
  const _TimeStepper({required this.label, required this.value, required this.onDecrement, required this.onIncrement});
  final String label;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.deepNavy, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.deepBlue)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppTheme.iceBlue)),
          const SizedBox(height: 10),
          Row(children: [
            _RoundControl(icon: Icons.remove_rounded, onTap: onDecrement),
            Expanded(child: Text(value.toString().padLeft(2, '0'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w600))),
            _RoundControl(icon: Icons.add_rounded, onTap: onIncrement),
          ]),
        ]),
      );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record, required this.unit, required this.isRecord});
  final WorkoutRecord record;
  final String unit;
  final bool isRecord;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (record.hasWeight) parts.add('${formatWeight(record.weight, Localizations.localeOf(context))} $unit');
    if (record.hasRepetitions) parts.add('${record.repetitions} ${context.strings.t('reps', 'reps', 'reps')}');
    if (record.hasDuration) parts.add(_formatDurationShort(record.durationSeconds!));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(children: [
        Text(formatFullDate(record.date, Localizations.localeOf(context)), style: Theme.of(context).textTheme.bodyLarge),
        if (isRecord) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: AppTheme.electricLime, borderRadius: BorderRadius.circular(9)),
            child: Text(context.strings.t('Recorde', 'Record', 'Récord'), style: const TextStyle(color: AppTheme.deepNavy, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
        const Spacer(),
        Text(parts.isEmpty ? '—' : parts.join(' • '), style: Theme.of(context).textTheme.titleMedium),
      ]),
    );
  }
}

String _machinePrimaryDisplay(Machine machine, String unit, Locale locale) {
  if (machine.recordWeight > 0) return '${formatWeight(machine.recordWeight, locale)} $unit';
  if (machine.bestRepetitions > 0) return '${machine.bestRepetitions} reps';
  if (machine.bestDurationSeconds > 0) return _formatDurationShort(machine.bestDurationSeconds);
  return '—';
}

String _formatDurationShort(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  if (minutes <= 0) return '${remainder}s';
  return '${minutes}m ${remainder.toString().padLeft(2, '0')}s';
}
