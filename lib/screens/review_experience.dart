import 'package:material_ui/material_ui.dart';

import '../models/machine.dart';
import '../models/workout_record.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/adaptive_illustration.dart';
import 'home_screen.dart';
import 'machine_screen.dart';
import 'settings_screen.dart';

/// Mobile validation experience, visually based on the approved cyan mockups.
/// Uses the real AppController/SQLite data, not the standalone HTML prototype.
class ReviewHomeScreen extends StatelessWidget {
  const ReviewHomeScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final name = app.displayName.trim().split(' ').first;
    final favorites = app.favoriteMachines.take(3).toList();
    final recent = app.recentlyUsedMachines.take(3).toList();
    final today = app.todaysMachines;
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      bottomNavigationBar: _ReviewBottomBar(index: 0),
      body: SafeArea(
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              Row(children: [
                const Icon(Icons.fitness_center_rounded, color: AppTheme.electricLime, size: 28),
                const SizedBox(width: 8),
                const Expanded(child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'Gym', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  TextSpan(text: 'Records', style: TextStyle(color: AppTheme.electricLime,
                      fontSize: 24, fontWeight: FontWeight.bold)),
                ]))),
                IconButton(tooltip: 'Configurações', icon: const Icon(Icons.settings_outlined),
                  onPressed: () => _open(context, const SettingsScreen())),
              ]),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Olá, $name! 👋', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 5),
                  const Text('Vamos registrar o treino de hoje?',
                      style: TextStyle(color: AppTheme.iceBlue)),
                ])),
                Image.asset('assets/branding/pro_mascot.webp', width: 82, height: 82,
                    fit: BoxFit.contain, errorBuilder: (_, __, ___) =>
                        const Icon(Icons.emoji_events_rounded, color: AppTheme.electricLime, size: 55)),
              ]),
              const SizedBox(height: 17),
              InkWell(
                key: const Key('review_search_exercises'),
                onTap: () => _open(context, const HomeScreen()),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
                  decoration: BoxDecoration(color: AppTheme.surfaceNavy,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.deepBlue)),
                  child: const Row(children: [
                    Icon(Icons.search_rounded, color: AppTheme.electricLime),
                    SizedBox(width: 12),
                    Expanded(child: Text('Buscar exercício ou aparelho',
                      style: TextStyle(color: AppTheme.iceBlue))),
                    Icon(Icons.tune_rounded),
                  ]),
                ),
              ),
              const SizedBox(height: 19),
              _CyanCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.track_changes_rounded, color: AppTheme.electricLime),
                    const SizedBox(width: 9),
                    const Expanded(child: Text('Treino de hoje',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20))),
                    if (app.hasActiveSession)
                      const Chip(label: Text('EM ANDAMENTO')),
                  ]),
                  const SizedBox(height: 7),
                  Text(app.hasActiveSession ? app.currentSessionName
                    : today.isEmpty ? 'Comece seu primeiro exercício'
                    : '${today.length} exercício(s) com registros hoje',
                    style: const TextStyle(color: AppTheme.iceBlue)),
                  if (app.hasActiveSession && app.activeSessionMachines.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final m in app.activeSessionMachines.take(3))
                      _MachineRow(machine: m, onTap: () =>
                        _open(context, MachineScreen(machineId: m.id))),
                  ],
                  const SizedBox(height: 13),
                  FilledButton.icon(
                    key: const Key('start_training'),
                    onPressed: () {
                      if (!app.hasActiveSession) app.startSession();
                      _open(context, const ReviewSessionScreen());
                    },
                    icon: Icon(app.hasActiveSession ? Icons.play_arrow_rounded : Icons.add_rounded),
                    label: Text(app.hasActiveSession ? 'Continuar treino' : 'Iniciar treino'),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _ShortcutCard(icon: Icons.history_rounded,
                  title: 'Recentes', subtitle: 'Últimos usados',
                  onTap: () => _open(context, const ReviewExerciseList(favoritesOnly: false)))),
                const SizedBox(width: 10),
                Expanded(child: _ShortcutCard(icon: Icons.star_border_rounded,
                  title: 'Favoritos', subtitle: '${app.favoriteMachines.length} exercícios',
                  onTap: () => _open(context, const ReviewExerciseList(favoritesOnly: true)))),
              ]),
              const SizedBox(height: 22),
              const Text('Seu acesso rápido',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              for (final machine in [...favorites, ...recent].fold<List<Machine>>(
                  [], (items, m) { if (!items.any((v) => v.id == m.id)) items.add(m); return items; }))
                _MachineRow(machine: machine, onTap: () =>
                  _open(context, MachineScreen(machineId: machine.id))),
              if (favorites.isEmpty && recent.isEmpty)
                const _CyanCard(child: Text(
                  'Toque na estrela dos exercícios para encontrá-los rapidamente aqui.',
                  style: TextStyle(color: AppTheme.iceBlue))),
              const SizedBox(height: 19),
              const Text('Explorar exercícios', style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.bold)),
              const SizedBox(height: 11),
              OutlinedButton.icon(
                onPressed: () => _open(context, const HomeScreen()),
                icon: const Icon(Icons.fitness_center_rounded),
                label: const Text('Ver aparelhos e grupos musculares'),
              ),
              if (app.persistenceError != null) ...[
                const SizedBox(height: 15),
                Text('Atenção: ${app.persistenceError}',
                  style: const TextStyle(color: AppTheme.warning)),
              ],
            ],
          ),
        )),
      ),
    );
  }
}

class ReviewSessionScreen extends StatelessWidget {
  const ReviewSessionScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final app = AppScope.of(context);
    final selected = await Navigator.of(context).push<Machine>(
      MaterialPageRoute(builder: (_) => const ReviewExercisePicker()));
    if (selected == null || !context.mounted) return;
    app.addExerciseToSession(selected);
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => MachineScreen(machineId: selected.id)));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final id = app.activeSessionId;
    final items = app.activeSessionMachines;
    final recorded = [
      for (final m in items)
        ...m.records.where((r) => r.sessionId == id),
    ];
    final volume = recorded.where((r) => !r.isWarmup)
      .fold<double>(0, (sum, r) => sum + r.weight * (r.repetitions ?? 0));
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: Text(app.currentSessionName)),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(padding: const EdgeInsets.all(18), children: [
          const Text('Treino em andamento', style: TextStyle(
            fontSize: 27, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Metric(label: 'Exercícios', value: '${items.length}')),
            const SizedBox(width: 8),
            Expanded(child: _Metric(label: 'Séries', value: '${recorded.length}')),
            const SizedBox(width: 8),
            Expanded(child: _Metric(label: 'Volume (kg)', value: volume.toStringAsFixed(0))),
          ]),
          const SizedBox(height: 20),
          if (items.isEmpty) const _CyanCard(child: Text(
            'Adicione um exercício para começar a registrar suas séries.',
            style: TextStyle(color: AppTheme.iceBlue))),
          for (final machine in items)
            _MachineRow(machine: machine,
              detail: '${machine.records.where((r) => r.sessionId == id).length} série(s) nesta sessão',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => MachineScreen(machineId: machine.id)))),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const Key('add_session_exercise'),
            onPressed: () => _add(context),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Adicionar exercício'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('finish_training'),
            onPressed: () async {
              final confirmed = await showDialog<bool>(context: context,
                builder: (d) => AlertDialog(
                  title: const Text('Concluir este treino?'),
                  content: const Text('As séries ficam salvas no histórico local.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(d, false),
                      child: const Text('Continuar treino')),
                    FilledButton(onPressed: () => Navigator.pop(d, true),
                      child: const Text('Concluir')),
                  ],
                ));
              if (confirmed == true && context.mounted) {
                app.finishSession();
                await app.flushPendingWrites();
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Concluir treino'),
          ),
        ]),
      ))),
    );
  }
}

class ReviewExercisePicker extends StatefulWidget {
  const ReviewExercisePicker({super.key});
  @override
  State<ReviewExercisePicker> createState() => _ReviewExercisePickerState();
}
class _ReviewExercisePickerState extends State<ReviewExercisePicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final list = AppScope.of(context).availableMachines
      .where((m) => m.name.toLowerCase().contains(query.toLowerCase()))
      .take(70).toList();
    return Scaffold(backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: const Text('Selecione o exercício')),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: TextField(
          autofocus: true,
          onChanged: (text) => setState(() => query = text),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Buscar aparelho ou exercício',
          ),
        )),
        Expanded(child: ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final m = list[index];
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              child: _MachineRow(machine: m,
                onTap: () => Navigator.pop(context, m)));
          },
        )),
      ])),
    );
  }
}

class ReviewExerciseList extends StatelessWidget {
  const ReviewExerciseList({super.key, required this.favoritesOnly});
  final bool favoritesOnly;
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = favoritesOnly ? app.favoriteMachines : app.recentlyUsedMachines;
    return Scaffold(backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: Text(favoritesOnly ? 'Favoritos' : 'Exercícios recentes')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        if (items.isEmpty) const _CyanCard(
          child: Text('Ainda não há exercícios nesta lista.',
            style: TextStyle(color: AppTheme.iceBlue))),
        for (final m in items) _MachineRow(machine: m,
          onTap: () {
            final added = app.ensureMachineAdded(m);
            Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => MachineScreen(machineId: added.id)));
          }),
      ]));
  }
}

class ReviewHistoryScreen extends StatelessWidget {
  const ReviewHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final grouped = <String, List<({Machine machine, WorkoutRecord record})>>{};
    for (final m in app.machines) {
      for (final r in m.records) {
        final id = r.sessionId.isEmpty ? WorkoutRecord.dayKey(r.date) : r.sessionId;
        grouped.putIfAbsent(id, () => []).add((machine:m, record:r));
      }
    }
    final sorted = grouped.entries.toList()..sort((a,b) {
      final da = a.value.map((x)=>x.record.date).reduce((a,b)=>a.isAfter(b)?a:b);
      final db = b.value.map((x)=>x.record.date).reduce((a,b)=>a.isAfter(b)?a:b);
      return db.compareTo(da);
    });
    return Scaffold(backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: const Text('Histórico por sessão')),
      bottomNavigationBar: const _ReviewBottomBar(index: 3),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        if (sorted.isEmpty) const _CyanCard(child: Text(
          'Suas sessões aparecerão aqui depois do primeiro registro.',
          style: TextStyle(color: AppTheme.iceBlue))),
        for (final entry in sorted) ...[
          _CyanCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app.sessionNames[entry.key] ?? 'Treino registrado',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('${entry.value.first.record.date.day}/${entry.value.first.record.date.month}/'
                '${entry.value.first.record.date.year} · ${entry.value.length} séries',
              style: const TextStyle(color: AppTheme.iceBlue)),
            const SizedBox(height: 10),
            for (final item in entry.value.take(15))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(item.machine.name),
                subtitle: Text('${item.record.weight.toStringAsFixed(1)} kg × '
                    '${item.record.repetitions ?? 0} rep'
                    '${item.record.isWarmup ? ' · Aquecimento' : ''}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => MachineScreen(machineId: item.machine.id))),
              ),
          ])),
          const SizedBox(height: 12),
        ],
      ]),
    );
  }
}

class _ReviewBottomBar extends StatelessWidget {
  const _ReviewBottomBar({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String title, Widget screen})>[
      (icon: Icons.home_rounded, title: 'Início', screen: const ReviewHomeScreen()),
      (icon: Icons.fitness_center_rounded, title: 'Exercícios', screen: const HomeScreen()),
      (icon: Icons.play_circle_outline_rounded, title: 'Treino', screen: const ReviewSessionScreen()),
      (icon: Icons.history_rounded, title: 'Histórico', screen: const ReviewHistoryScreen()),
      (icon: Icons.settings_rounded, title: 'Perfil', screen: const SettingsScreen()),
    ];
    return SafeArea(top: false, child: Container(
      height: 65, decoration: const BoxDecoration(color: AppTheme.surfaceNavy,
        border: Border(top: BorderSide(color: AppTheme.deepBlue))),
      child: Row(children: [
        for (var i=0; i<items.length; i++)
          Expanded(child: InkWell(
            onTap: () {
              if (i == index) return;
              if (i == 2) {
                final app = AppScope.of(context);
                if (!app.hasActiveSession) app.startSession();
              }
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => items[i].screen));
            },
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(items[i].icon, size: 23,
                color: i == index ? AppTheme.electricLime : AppTheme.iceBlue),
              const SizedBox(height: 3),
              Text(items[i].title, style: TextStyle(fontSize: 11,
                color: i == index ? AppTheme.electricLime : AppTheme.iceBlue)),
            ]),
          )),
      ]),
    ));
  }
}

class _CyanCard extends StatelessWidget {
  const _CyanCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceNavy,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: AppTheme.deepBlue)),
    child: child,
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label,required this.value});
  final String label,value;
  @override
  Widget build(BuildContext context) => _CyanCard(child: Column(children: [
    Text(value, style: const TextStyle(fontSize: 23,
        fontWeight: FontWeight.bold, color: AppTheme.electricLime)),
    Text(label, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 11,color: AppTheme.iceBlue)),
  ]));
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.icon,required this.title,
    required this.subtitle, required this.onTap});
  final IconData icon;
  final String title,subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(19),
    onTap: onTap,
    child: _CyanCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.electricLime),
        const SizedBox(height: 9),
        Text(title, style: const TextStyle(fontSize: 16,fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(fontSize: 12,color: AppTheme.iceBlue)),
      ])),
  );
}

class _MachineRow extends StatelessWidget {
  const _MachineRow({required this.machine,required this.onTap,this.detail});
  final Machine machine;
  final String? detail;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Material(color: AppTheme.surfaceNavy,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(padding: const EdgeInsets.all(11),child: Row(children: [
          Container(width: 42, height: 42,
            decoration: BoxDecoration(color: AppTheme.accentBlueSoft,
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.fitness_center_rounded, color: AppTheme.electricLime)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(machine.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(detail ?? (machine.latestRecord == null ? machine.group.label :
                'Última: ${machine.latestRecord!.weight.toStringAsFixed(0)} kg × '
                '${machine.latestRecord!.repetitions ?? 0}'),
                style: const TextStyle(fontSize: 12,color: AppTheme.iceBlue)),
            ])),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.electricLime),
        ])),
      ),
    ),
  );
}
