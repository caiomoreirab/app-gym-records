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
import '../widgets/session_series_panel.dart';
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
  double _weight = 0;
  int? _repetitions;
  bool _showAdditionalWeight = false;
  int _minutes = 0;
  int _seconds = 0;
  bool _isWarmup = false;
  int? _rpe;
  int? _restSeconds;
  String _setNote = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final machine = AppScope.of(context).machineById(widget.machineId);
    final latest = machine.latestRecord;
    _weight = latest?.weight ?? 0;
    _repetitions = latest?.repetitions ?? (machine.prefersBodyMetrics ? null : machine.supportsRepetitions ? 10 : null);
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
        label: context.strings.saveRecord,
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
            const SizedBox(height: 16),
            _SetExtras(
              isWarmup: _isWarmup,
              onWarmupChanged: (value) => setState(() => _isWarmup = value),
              rpe: _rpe,
              onRpeChanged: (value) => setState(() => _rpe = value),
              restSeconds: _restSeconds,
              onRestChanged: (value) => setState(() => _restSeconds = value),
              onNoteChanged: (value) => _setNote = value,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('repeat_last_set'),
              onPressed: machine.records.isEmpty || _saving
                ? null : () => _repeatLastSeries(machine),
              icon: const Icon(Icons.repeat_rounded),
              label: const Text('Repetir última série'),
            ),
            const SizedBox(height: 26),
            SessionSeriesPanel(machine: machine),
            const SizedBox(height: 12),
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
    return _weight > 0;
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

    final saved = app.addRecord(
      machine,
      weight: _weight,
      repetitions: (_repetitions ?? 0) > 0 ? _repetitions : null,
      durationSeconds: durationSeconds > 0 ? durationSeconds : null,
      rpe: _rpe?.toDouble(),
      restSeconds: _restSeconds,
      note: _setNote,
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
    _showUndoForSaved(app, machine, saved);

    final isNewWeight = _weight > 0 && _weight > previousWeight;
    final isNewReps = (_repetitions ?? 0) > 0 && _repetitions! > previousRepetitions;
    final isNewDuration = durationSeconds > 0 && durationSeconds > previousDurationSeconds;

    if (!_isWarmup && (isNewWeight || isNewReps || isNewDuration)) {
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

    setState(() {});
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showUndoForSaved(AppController app, Machine machine,
      WorkoutRecord saved) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Série salva no dispositivo.'),
      action: SnackBarAction(
        label: 'Desfazer',
        onPressed: () {
          if (machine.records.any((r) => r.id == saved.id)) {
            app.removeRecord(machine, saved.id);
          }
        },
      ),
    ));
  }

  Future<void> _repeatLastSeries(Machine machine) async {
    if (_saving || machine.records.isEmpty) return;
    setState(() => _saving = true);
    try {
      final app = AppScope.of(context);
      final previous = machine.latestRecord!;
      final saved = app.addRecord(machine,
        weight: previous.weight,
        repetitions: previous.repetitions,
        durationSeconds: previous.durationSeconds,
        rpe: previous.rpe,
        rir: previous.rir,
        restSeconds: previous.restSeconds,
        note: previous.note,
        isWarmup: previous.isWarmup,
      );
      await app.flushPendingWrites();
      if (!mounted) return;
      if (app.persistenceError == null) {
        HapticFeedback.lightImpact();
        _showUndoForSaved(app, machine, saved);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao gravar a série repetida.')));
      }
      setState(() {});
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
  final int minutes, seconds;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onTapWeight;
  final ValueChanged<int?> onRepetitionsChanged;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<int> onSecondsChanged;

  @override
  Widget build(BuildContext context) {
    final showWeight = !machine.prefersBodyMetrics || showAdditionalWeight;
    return SectionCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (machine.prefersBodyMetrics) ...[
          OutlinedButton.icon(
            onPressed: onToggleAdditionalWeight,
            icon: Icon(showAdditionalWeight
              ? Icons.remove_circle_outline_rounded
              : Icons.add_circle_outline_rounded),
            label: Text(showAdditionalWeight
              ? 'Remover carga adicional'
              : 'Adicionar carga extra (opcional)'),
          ),
          const SizedBox(height: 10),
        ],
        if (showWeight || machine.supportsRepetitions)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (showWeight) ...[
              Expanded(child: _SetMetricCard(
                title: 'Carga ($unit)',
                value: formatWeight(weight, Localizations.localeOf(context)),
                onValueTap: onTapWeight,
                onMinus: () => onWeightChanged(
                  (weight - increment).clamp(0.0, 250.0).toDouble()),
                onPlus: () => onWeightChanged(
                  (weight + increment).clamp(0.0, 250.0).toDouble()),
              )),
              if (machine.supportsRepetitions)
                const SizedBox(width: 10),
            ],
            if (machine.supportsRepetitions)
              Expanded(child: _SetMetricCard(
                title: 'Repetições',
                value: repetitions?.toString() ?? '—',
                onMinus: () {
                  final n = repetitions ?? 0;
                  onRepetitionsChanged(n <= 1 ? null : n - 1);
                },
                onPlus: () => onRepetitionsChanged(
                  ((repetitions ?? 0) + 1).clamp(1, 1000)),
              )),
          ]),
        if (showWeight) ...[
          const SizedBox(height: 10),
          Slider(
            value: weight.clamp(0, 250).toDouble(),
            min: 0, max: 250, divisions: 100,
            label: '${weight.toStringAsFixed(1)} $unit',
            onChanged: onWeightChanged,
          ),
        ],
        if (machine.supportsDuration) ...[
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Text('Duração (opcional)',
            style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _TimeStepper(label: 'Minutos',
              value: minutes,
              onDecrement: () => onMinutesChanged(minutes - 1),
              onIncrement: () => onMinutesChanged(minutes + 1))),
            const SizedBox(width: 10),
            Expanded(child: _TimeStepper(label: 'Segundos',
              value: seconds,
              onDecrement: () => onSecondsChanged(seconds - 1),
              onIncrement: () => onSecondsChanged(seconds + 1))),
          ]),
        ],
      ],
    ));
  }
}

class _SetMetricCard extends StatelessWidget {
  const _SetMetricCard({
    required this.title,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.onValueTap,
  });

  final String title, value;
  final VoidCallback onMinus, onPlus;
  final VoidCallback? onValueTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$title: $value',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.deepNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.deepBlue),
      ),
      child: Column(children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.iceBlue, fontSize: 13,
            fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        InkWell(
          onTap: onValueTap,
          child: SizedBox(height: 47,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 38,
                  color: AppTheme.polarWhite,
                  fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
            tooltip: 'Diminuir $title',
            onPressed: onMinus,
            icon: const Icon(Icons.remove_rounded)),
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
            tooltip: 'Aumentar $title',
            onPressed: onPlus,
            icon: const Icon(Icons.add_rounded)),
        ]),
      ]),
    ),
  );
}

class _SetExtras extends StatelessWidget {
  const _SetExtras({
    required this.isWarmup, required this.onWarmupChanged,
    required this.rpe, required this.onRpeChanged,
    required this.restSeconds, required this.onRestChanged,
    required this.onNoteChanged,
  });

  final bool isWarmup;
  final ValueChanged<bool> onWarmupChanged;
  final int? rpe, restSeconds;
  final ValueChanged<int?> onRpeChanged, onRestChanged;
  final ValueChanged<String> onNoteChanged;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 10),
      title: const Text('Detalhes da série (opcional)'),
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
          title: const Text('Série de aquecimento'),
          subtitle: const Text('Não participa dos recordes pessoais.'),
          value: isWarmup,
          onChanged: onWarmupChanged),
        ListTile(
          title: const Text('Esforço percebido (RPE)'),
          trailing: DropdownButton<int>(
            value: rpe,
            hint: const Text('—'),
            items: [
              const DropdownMenuItem<int>(value: null, child: Text('—')),
              for (var value = 1; value <= 10; value++)
                DropdownMenuItem<int>(
                  value: value, child: Text(value.toString())),
            ],
            onChanged: onRpeChanged,
          ),
        ),
        ListTile(
          title: const Text('Descanso'),
          trailing: DropdownButton<int>(
            value: restSeconds,
            hint: const Text('—'),
            items: [
              const DropdownMenuItem<int>(value: null, child: Text('—')),
              for (final value in [60, 90, 120, 180])
                DropdownMenuItem<int>(
                  value: value, child: Text('${value}s')),
            ],
            onChanged: onRestChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          child: TextField(
            maxLength: 160,
            maxLines: 2,
            onChanged: onNoteChanged,
            decoration: const InputDecoration(
              labelText: 'Observação desta série',
              hintText: 'Ex.: execução controlada',
            ),
          ),
        ),
      ],
    ),
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
