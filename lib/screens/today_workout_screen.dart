import 'package:material_ui/material_ui.dart';

import '../models/machine.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/page_body.dart';
import '../widgets/section_card.dart';
import 'machine_screen.dart';

/// One local-day session, without a mandatory template or login.
class TodayWorkoutScreen extends StatelessWidget {
  const TodayWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final machines = app.todaysMachines;
    final sets = machines.fold<int>(0, (sum, m) => sum + app.todaysSets(m).length);
    final volume = machines.fold<double>(0.0, (sum, m) =>
      sum + app.todaysSets(m).fold<double>(0.0, (total, r) =>
        total + (r.isWarmup ? 0 : r.weight * (r.repetitions ?? 0))));
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: const Text('Treino de hoje')),
      body: PageBody(child: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        const SizedBox(height: 12),
        Text('Sua sessão', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 7),
        const Text('Cada série é salva no celular. Funciona sem internet.',
            style: TextStyle(color: AppTheme.iceBlue)),
        const SizedBox(height: 18),
        SectionCard(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _stat('Exercícios', machines.length.toString()),
          _stat('Séries', sets.toString()),
          _stat('Volume', volume.toStringAsFixed(0) + ' kg'),
        ])),
        const SizedBox(height: 24),
        if (machines.isEmpty)
          SectionCard(child: Column(children: [
            const Icon(Icons.fitness_center, size: 44, color: AppTheme.electricLime),
            const SizedBox(height: 10),
            const Text('Nenhum exercício registrado hoje.'),
            const SizedBox(height: 8),
            const Text('Abra um exercício na Home para começar.',
                style: TextStyle(color: AppTheme.iceBlue)),
            TextButton(onPressed: () => Navigator.of(context).pop(),
                child: const Text('Escolher exercício')),
          ]))
        else for (final machine in machines) ...[
          SectionCard(child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: AppTheme.accentBlueSoft,
                child: Icon(Icons.check, color: AppTheme.electricLime)),
            title: Text(machine.localizedName(Localizations.localeOf(context))),
            subtitle: Text(app.todaysSets(machine).length.toString() + ' séries'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, machine),
          )),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 15),
        Text('Atalhos: exercícios favoritos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (app.favoriteMachines.isEmpty)
          const Text('Toque na estrela de um exercício para colocá-lo aqui.',
              style: TextStyle(color: AppTheme.iceBlue))
        else for (final machine in app.favoriteMachines) ...[
          ListTile(
            title: Text(machine.localizedName(Localizations.localeOf(context))),
            leading: const Icon(Icons.star, color: AppTheme.warning),
            trailing: const Icon(Icons.add_circle_outline, color: AppTheme.electricLime),
            onTap: () => _open(context,machine),
          ),
        ],
      ])),
    );
  }

  Widget _stat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600)),
    Text(label, style: const TextStyle(color: AppTheme.iceBlue, fontSize: 12)),
  ]);

  void _open(BuildContext context, Machine m) {
    final app = AppScope.of(context);
    app.ensureMachineAdded(m);
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => MachineScreen(machineId: m.id)));
  }
}
