import 'package:material_ui/material_ui.dart';

import '../state/app_controller.dart';
import '../theme/app_theme.dart';

/// Local profiles. Training records are tagged with the gym selected at save.
class GymProfilesScreen extends StatelessWidget {
  const GymProfilesScreen({super.key});

  Future<void> _create(BuildContext context, AppController app) async {
    final controller = TextEditingController();
    try {
      final name = await showDialog<String>(context: context,
        builder: (d) => AlertDialog(
          title: const Text('Adicionar academia'),
          content: TextField(controller: controller, maxLength: 100,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Ex.: Academia Centro')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d),
              child: const Text('Cancelar')),
            FilledButton(onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(d, controller.text.trim());
              }
            }, child: const Text('Salvar')),
          ],
        ));
      if (name != null) app.addGym(name);
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: const Text('Minhas academias')),
      body: ListView(padding: const EdgeInsets.all(18),children: [
        const Text('Onde você treina?',
          style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Use um perfil para identificar o local de cada série. '
          'Seus registros antigos continuam em Minha academia.',
          style: TextStyle(color: AppTheme.iceBlue)),
        const SizedBox(height: 18),
        for (final entry in app.gyms.entries) ...[
          Card(child: RadioListTile<String>(
            value: entry.key,
            groupValue: app.selectedGymId,
            onChanged: (value) {
              if (value != null) app.selectGym(value);
            },
            title: Text(entry.value),
            subtitle: const Text('Dados guardados neste dispositivo'),
            secondary: const Icon(Icons.location_city_rounded,
              color: AppTheme.electricLime),
          )),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 14),
        OutlinedButton.icon(onPressed: () => _create(context, app),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar academia')),
        const SizedBox(height: 12),
        const Text('Não é necessário GPS nem conexão com a internet.',
          style: TextStyle(color: AppTheme.iceBlue)),
      ]),
    );
  }
}
