import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/machine.dart';
import '../models/workout_record.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/adaptive_illustration.dart';
import '../widgets/page_body.dart';
import '../widgets/section_card.dart';

/// Functional validation UI; no backend or payment service is required.
class MachineScreen extends StatefulWidget {
  const MachineScreen({super.key, required this.machineId});
  final String machineId;
  @override
  State<MachineScreen> createState() => _MachineScreenState();
}

class _MachineScreenState extends State<MachineScreen> {
  bool _ready = false;
  bool _saving = false;
  double _weight = 0;
  int _reps = 10;
  int _seconds = 0;
  bool _warmup = false;
  int? _rpe;
  int _tab = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    final last = AppScope.of(context).machineById(widget.machineId).latestRecord;
    _weight = last?.weight ?? 0;
    _reps = last?.repetitions ?? 10;
    _seconds = last?.durationSeconds ?? 0;
    _ready = true;
  }

  String _w(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1).replaceAll('.', ',');
  String _date(DateTime d) => d.day.toString().padLeft(2, '0') + '/' +
      d.month.toString().padLeft(2, '0') + '/' + d.year.toString();

  Future<void> _manualInput() async {
    final weight = TextEditingController(text: _w(_weight));
    final reps = TextEditingController(text: _reps.toString());
    final answer = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Carga e repetições'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(key: const Key('weight_field'), controller: weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Carga')),
        const SizedBox(height: 10),
        TextField(key: const Key('reps_field'), controller: reps, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Repetições')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aplicar')),
      ],
    ));
    final w = double.tryParse(weight.text.replaceAll(',', '.'));
    final n = int.tryParse(reps.text);
    weight.dispose();
    reps.dispose();
    if (!mounted || answer != true || w == null || !w.isFinite || w < 0 ||
        n == null || n < 0 || n > 999) return;
    setState(() { _weight = w; _reps = n; });
  }

  Future<void> _save(Machine m, {WorkoutRecord? repeat}) async {
    if (_saving) return;
    final app = AppScope.of(context);
    final w = repeat?.weight ?? _weight;
    final n = repeat?.repetitions ?? _reps;
    if (w <= 0 && n <= 0 && _seconds <= 0) return;
    setState(() => _saving = true);
    try {
      final record = app.addRecord(m, weight: w, repetitions: n,
        durationSeconds: repeat?.durationSeconds ?? (_seconds > 0 ? _seconds : null),
        isWarmup: repeat?.isWarmup ?? _warmup, rpe: repeat?.rpe ?? _rpe);
      await app.flushPendingWrites();
      if (!mounted) return;
      if (app.persistenceError != null) {
        _snack('Falha ao salvar no banco local. Veja Dados e privacidade.');
        return;
      }
      HapticFeedback.lightImpact();
      setState(() => _tab = 0);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Série salva: ' + _w(w) + ' ' + app.unit + ' × ' + n.toString() + ' rep'),
        action: SnackBarAction(label: 'DESFAZER', onPressed: () {
          if (m.records.contains(record)) app.deleteRecord(m, record);
        }),
      ));
    } catch (e) {
      if (mounted) _snack('Não foi possível salvar: ' + e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _repeat(Machine m) {
    if (m.records.isEmpty || _saving) return;
    final items = [...m.records]..sort((a, b) => b.date.compareTo(a.date));
    final last = items.firstWhere((r) => !r.isWarmup, orElse: () => items.first);
    _save(m, repeat: last);
  }

  Future<void> _edit(Machine m, WorkoutRecord original) async {
    final weight = TextEditingController(text: _w(original.weight));
    final reps = TextEditingController(text: (original.repetitions ?? 0).toString());
    bool warmup = original.isWarmup;
    int? effort = original.rpe;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) =>
      StatefulBuilder(builder: (ctx, refresh) => AlertDialog(
        title: const Text('Editar série'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: weight, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Carga')),
          const SizedBox(height: 10),
          TextField(controller: reps, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Repetições')),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Aquecimento'),
            value: warmup, onChanged: (v) => refresh(() => warmup = v)),
          DropdownButton<int?>(
            value: effort,
            hint: const Text('RPE opcional'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Sem RPE')),
              for (var i=1;i<=10;i++) DropdownMenuItem<int?>(value: i, child: Text('RPE ' + i.toString())),
            ],
            onChanged: (v) => refresh(() => effort = v),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      )));
    final w = double.tryParse(weight.text.replaceAll(',', '.'));
    final n = int.tryParse(reps.text);
    weight.dispose();
    reps.dispose();
    if (!mounted || confirmed != true || w == null || !w.isFinite || w < 0 ||
        n == null || n < 0 || n > 999) { if (confirmed == true && mounted) _snack('Valores inválidos.'); return; }
    final app = AppScope.of(context);
    app.editRecord(m, original, original.copyWith(weight: w, repetitions: n,
      isWarmup: warmup, rpe: effort));
    await app.flushPendingWrites();
    if (mounted) _snack(app.persistenceError == null ? 'Série alterada.' : 'Erro ao gravar edição.');
  }

  Future<void> _delete(Machine m, WorkoutRecord r) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Excluir esta série?'),
      content: const Text('Seu restante do histórico será preservado.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
      ],
    ));
    if (ok != true || !mounted) return;
    final app = AppScope.of(context);
    final index = app.deleteRecord(m, r);
    await app.flushPendingWrites();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Série excluída'),
      action: SnackBarAction(label: 'DESFAZER', onPressed: () => app.restoreRecord(m, r, index)),
    ));
  }

  Future<void> _note(Machine m) async {
    final c = TextEditingController(text: m.note);
    final value = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Regulagem do aparelho'),
      content: TextField(controller: c, maxLength: 1000, maxLines: 3,
        decoration: const InputDecoration(hintText: 'Ex.: assento 4, pegada aberta')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Salvar')),
      ],
    ));
    c.dispose();
    if (value != null && mounted) AppScope.of(context).updateMachineNote(m, value);
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final m = app.machineById(widget.machineId);
    final today = app.todaysSets(m);
    final history = [...m.records]..sort((a,b) => b.date.compareTo(a.date));
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        title: Text(m.localizedName(Localizations.localeOf(context)),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(key: const Key('favorite_toggle'),
            tooltip: app.isFavorite(m.id) ? 'Remover favorito' : 'Favoritar exercício',
            icon: Icon(app.isFavorite(m.id) ? Icons.star : Icons.star_border,
              color: app.isFavorite(m.id) ? AppTheme.warning : AppTheme.iceBlue),
            onPressed: () => app.toggleFavorite(m.id)),
        ],
      ),
      body: PageBody(child: ListView(padding: const EdgeInsets.only(bottom: 36), children: [
        ExerciseVisualPager(machine: m, width: double.infinity,
          height: 176, fit: BoxFit.cover, showLabel: true),
        const SizedBox(height: 12),
        _info(Icons.history, m.latestRecord == null ? 'Comece seu histórico' : 'Última série',
          m.latestRecord == null ? 'Sua próxima série ficará salva neste aparelho.' :
          _w(m.latestRecord!.weight) + ' ' + app.unit + ' × ' +
          (m.latestRecord!.repetitions ?? 0).toString() + ' rep'),
        const SizedBox(height: 15),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          _chip('Registrar', 0, const Key('tab_today')),
          const SizedBox(width: 8), _chip('Histórico', 1, const Key('tab_history')),
          const SizedBox(width: 8), _chip('Recordes', 2, const Key('tab_records')),
        ])),
        const SizedBox(height: 15),
        if (_tab == 0) ...[
          Text('Séries de hoje', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (today.isEmpty) _info(Icons.event_note, 'Sem séries ainda', 'Registre sua primeira série.')
          else SectionCard(child: Column(children: [
            for (var i=0;i<today.length;i++) _recordRow(m, today[i], i+1, app.unit),
          ])),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _metric('CARGA', _w(_weight) + ' ' + app.unit,
              () => setState(() => _weight = (_weight-app.increment).clamp(0,9999).toDouble()),
              () => setState(() => _weight = (_weight+app.increment).clamp(0,9999).toDouble()),
              const Key('weight_plus'))),
            const SizedBox(width: 10),
            Expanded(child: _metric('REPETIÇÕES', _reps.toString(),
              () => setState(() => _reps = (_reps-1).clamp(0,999)),
              () => setState(() => _reps = (_reps+1).clamp(0,999)),
              const Key('reps_plus'))),
          ]),
          const SizedBox(height: 6),
          TextButton(onPressed: _manualInput, child: const Text('Digitar carga e repetições')),
          SectionCard(child: Column(children: [
            SwitchListTile(key: const Key('warmup_toggle'), title: const Text('Série de aquecimento'),
              subtitle: const Text('Não contabilizar como recorde'),
              contentPadding: EdgeInsets.zero, value: _warmup,
              onChanged: (v) => setState(() => _warmup = v)),
            Row(children: [
              const Text('Esforço (RPE)'),
              const Spacer(),
              DropdownButton<int?>(value: _rpe, hint: const Text('Opcional'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Não informar')),
                  for(var n=1;n<=10;n++) DropdownMenuItem<int?>(value: n, child: Text(n.toString() + '/10')),
                ], onChanged: (v) => setState(() => _rpe=v)),
            ]),
            if (m.prefersBodyMetrics) Row(children: [
              const Expanded(child: Text('Duração (segundos)')),
              IconButton(onPressed: () => setState(() => _seconds = (_seconds-10).clamp(0,99999)),
                icon: const Icon(Icons.remove_circle_outline)),
              Text(_seconds.toString()),
              IconButton(onPressed: () => setState(() => _seconds += 10),
                icon: const Icon(Icons.add_circle_outline)),
            ]),
          ])),
          const SizedBox(height: 12),
          if (history.isNotEmpty) OutlinedButton.icon(
            key: const Key('repeat_set'), onPressed: _saving ? null : () => _repeat(m),
            icon: const Icon(Icons.repeat), label: const Text('Repetir última série')),
          const SizedBox(height: 10),
          FilledButton.icon(key: const Key('save_set'),
            onPressed: _saving || (_weight<=0 && _reps<=0 && _seconds<=0) ? null : () => _save(m),
            icon: const Icon(Icons.add), label: Text(_saving ? 'Salvando…' : 'Adicionar série')),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => _note(m),
            icon: const Icon(Icons.tune),
            label: Text(m.note.isEmpty ? 'Anotar regulagem do aparelho' : 'Regulagem: ' + m.note,
              maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
        if (_tab == 1) ...[
          Text('Histórico por sessão', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (history.isEmpty) _info(Icons.history, 'Histórico vazio', 'Seu primeiro treino aparecerá aqui.')
          else for (final item in _sessions(history).values) ...[
            SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.calendar_today, size: 18, color: AppTheme.electricLime),
                const SizedBox(width: 10),
                Expanded(child: Text(_date(item.first.date), style: Theme.of(context).textTheme.titleMedium)),
                Text(item.length.toString() + ' séries', style: const TextStyle(color: AppTheme.iceBlue)),
              ]),
              const Divider(),
              for (var i=0;i<item.length;i++) _recordRow(m,item[i],i+1,app.unit),
            ])),
            const SizedBox(height: 12),
          ],
        ],
        if (_tab == 2) _records(m, app.unit),
      ])),
    );
  }

  Map<String,List<WorkoutRecord>> _sessions(List<WorkoutRecord> items) {
    final groups = <String,List<WorkoutRecord>>{};
    for (final r in items) { groups.putIfAbsent(r.effectiveSessionId, () => []).add(r); }
    for (final v in groups.values) { v.sort((a,b)=>a.date.compareTo(b.date)); }
    return groups;
  }

  Widget _chip(String text, int index, Key key) => ChoiceChip(
    key: key, label: Text(text), selected: _tab==index,
    onSelected: (_) => setState(() => _tab=index),
    selectedColor: AppTheme.electricLime,
    labelStyle: TextStyle(color: _tab==index ? AppTheme.deepNavy : AppTheme.polarWhite),
  );

  Widget _info(IconData icon, String title, String subtitle) => SectionCard(
    child: Row(children: [
      Icon(icon, color: AppTheme.electricLime),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(subtitle, style: const TextStyle(color: AppTheme.iceBlue)),
      ])),
    ]),
  );

  Widget _metric(String label, String value, VoidCallback minus,
      VoidCallback plus, Key plusKey) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(color: AppTheme.surfaceNavy,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.electricLime.withValues(alpha: .4))),
    child: Column(children: [
      Text(label, style: const TextStyle(color: AppTheme.iceBlue, fontSize: 12)),
      const SizedBox(height: 6),
      FittedBox(fit: BoxFit.scaleDown,
        child: Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600))),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(onPressed: minus, icon: const Icon(Icons.remove_circle_outline)),
        IconButton(key: plusKey, onPressed: plus,
          icon: const Icon(Icons.add_circle, color: AppTheme.electricLime)),
      ]),
    ]),
  );

  Widget _recordRow(Machine m, WorkoutRecord r, int number, String unit) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
      CircleAvatar(radius: 14, backgroundColor: AppTheme.accentBlueSoft,
        child: Text(number.toString(), style: const TextStyle(color: AppTheme.polarWhite))),
      const SizedBox(width: 9),
      Expanded(child: Text(_w(r.weight) + ' ' + unit + ' × ' +
          (r.repetitions ?? 0).toString() + ' rep' +
          (r.isWarmup ? ' • Aquecimento' : ''),
        style: const TextStyle(fontSize: 15))),
      IconButton(tooltip: 'Editar série', onPressed: () => _edit(m,r),
        icon: const Icon(Icons.edit_outlined, size: 19, color: AppTheme.electricLime)),
      IconButton(tooltip: 'Excluir série', onPressed: () => _delete(m,r),
        icon: const Icon(Icons.delete_outline, size: 19)),
    ]));

  Widget _records(Machine m, String unit) {
    final series = m.records.where((r) => !r.isWarmup && r.weight>0).toList();
    final range = series.where((r) => (r.repetitions ?? 0)>=8 && (r.repetitions ?? 0)<=12).toList();
    final maxes = series.where((r) => (r.repetitions ?? 0)>0 && (r.repetitions ?? 0)<=12).toList();
    double maxOf(List<WorkoutRecord> r) => r.isEmpty ? 0 : r.map((v) => v.weight).reduce((a,b)=>a>b?a:b);
    final estimate = maxes.isEmpty ? 0.0 : maxes.map((r)=>r.weight*(1+r.repetitions!/30)).reduce((a,b)=>a>b?a:b);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Seus recordes', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      if (series.isEmpty) _info(Icons.emoji_events, 'Ainda sem recordes', 'Registre uma série válida.')
      else ...[
        _info(Icons.fitness_center, 'Maior carga', _w(maxOf(series))+' '+unit),
        const SizedBox(height: 10),
        _info(Icons.repeat, 'Maior carga de 8 a 12 repetições',
          range.isEmpty ? 'Ainda sem séries nessa faixa' : _w(maxOf(range))+' '+unit),
        const SizedBox(height: 10),
        _info(Icons.auto_graph, 'Carga máxima estimada (1RM)',
          maxes.isEmpty ? 'Ainda sem dados' : _w(estimate)+' '+unit),
        const SizedBox(height: 12),
        const Text('1RM é uma estimativa (Epley: carga × (1 + repetições/30)), não um teste real. '
          'Aquecimentos não entram no cálculo.',
          style: TextStyle(color: AppTheme.iceBlue, fontSize: 13)),
      ],
    ]);
  }
}
