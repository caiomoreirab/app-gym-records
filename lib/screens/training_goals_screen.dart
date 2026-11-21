import 'package:material_ui/material_ui.dart';
import '../state/app_controller.dart';
import '../models/machine.dart';
import '../theme/app_theme.dart';
import 'machine_screen.dart';

/// Simple, optional goals, stored only in the local snapshot.
class TrainingGoalsScreen extends StatelessWidget {
  const TrainingGoalsScreen({super.key});

  Future<void> _setGoal(BuildContext context, Machine machine) async {
    final app = AppScope.of(context);
    final controller = TextEditingController(
      text: app.targetWeights[machine.id]?.toStringAsFixed(1) ?? '');
    try {
      final kg = await showDialog<double?>(context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Meta para ${machine.name}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Carga desejada (kg)')),
            const SizedBox(height: 7),
            const Text('A meta é opcional. Ela não substitui orientações de um profissional.'),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, -1.0),
              child: const Text('Remover meta')),
            FilledButton(onPressed: () {
              final value = double.tryParse(controller.text.replaceAll(',', '.'));
              if (value != null && value > 0 && value <= 10000) {
                Navigator.pop(dialogContext, value);
              }
            }, child: const Text('Salvar')),
          ],
        ));
      if (kg == -1.0) app.setTargetWeight(machine.id, null);
      else if (kg != null) app.setTargetWeight(machine.id, kg);
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final registered = app.machines.where((m) => m.records.isNotEmpty).toList();
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: const Text('Metas por exercício')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const Text('Sua evolução, no seu ritmo',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Defina uma carga-alvo e acompanhe seu melhor registro.',
          style: TextStyle(color: AppTheme.iceBlue)),
        const SizedBox(height: 18),
        if (registered.isEmpty)
          Container(padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppTheme.surfaceNavy,
              borderRadius: BorderRadius.circular(16)),
            child: const Text('Registre seu primeiro exercício para criar uma meta.')),
        for (final machine in registered) ...[
          Container(
            padding: const EdgeInsets.all(17),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppTheme.surfaceNavy,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.deepBlue)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(machine.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                IconButton(tooltip: 'Definir meta', icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _setGoal(context, machine)),
              ]),
              Text('Seu melhor: ${machine.recordWeight.toStringAsFixed(1)} kg',
                style: const TextStyle(color: AppTheme.iceBlue)),
              if (app.targetWeights[machine.id] case final target?) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (machine.recordWeight / target).clamp(0.0, 1.0),
                  minHeight: 8, borderRadius: BorderRadius.circular(5),
                  color: AppTheme.electricLime),
                const SizedBox(height: 7),
                Text(machine.recordWeight >= target
                    ? 'Meta alcançada! 🏆'
                    : 'Objetivo: ${target.toStringAsFixed(1)} kg',
                  style: const TextStyle(color: AppTheme.electricLime)),
              ] else
                TextButton(onPressed: () => _setGoal(context, machine),
                  child: const Text('+ Criar uma meta')),
              TextButton(onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) =>
                  MachineScreen(machineId: machine.id))),
                child: const Text('Ver exercício')),
            ]),
          ),
        ],
      ]),
    );
  }
}
