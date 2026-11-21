import 'package:material_ui/material_ui.dart';

import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_header.dart';
import '../widgets/gym_bottom_navigation.dart';
import '../widgets/page_body.dart';
import '../widgets/section_card.dart';
import 'evolution_screen.dart';
import 'pro_records_screen.dart';

/// Free workout overview: users can inspect their own records at any tier.
class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final records = app.machines.fold<int>(0, (sum, m) => sum + m.records.length);
    final sessions = app.sessions.where((s) =>
      s.completedAt != null && app.recordsForSession(s.id).isNotEmpty).toList()
      ..sort((a,b) => b.startedAt.compareTo(a.startedAt));

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      bottomNavigationBar: const GymBottomNavigation(index: 2),
      body: PageBody(child: ListView(children: [
        const SizedBox(height: 14),
        const BrandHeader(compact: true),
        const SizedBox(height: 20),
        Text('Relatórios',
          style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text('Sua evolução com base nos registros do dispositivo.',
          style: TextStyle(color: AppTheme.iceBlue)),
        const SizedBox(height: 16),
        SectionCard(child: Row(children: [
          Expanded(child: _Metric(
            label: 'Treinos concluídos', value: '${sessions.length}')),
          const SizedBox(width: 15),
          Expanded(child: _Metric(label: 'Séries registradas', value: '$records')),
        ])),
        const SizedBox(height: 16),
        SectionCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Histórico de treinos',
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (sessions.isEmpty)
              const Text('Conclua um treino para começar seu histórico.',
                style: TextStyle(color: AppTheme.iceBlue)),
            for (final session in sessions.take(15))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline_rounded,
                  color: AppTheme.electricLime),
                title: Text(session.name, maxLines: 1,
                  overflow: TextOverflow.ellipsis),
                subtitle: Text('${session.startedAt.day.toString().padLeft(2, '0')}/'
                  '${session.startedAt.month.toString().padLeft(2, '0')}/'
                  '${session.startedAt.year} · '
                  '${app.recordsForSession(session.id).length} séries'),
              ),
          ],
        )),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: app.isPro ? () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const EvolutionScreen()))
            : null,
          icon: const Icon(Icons.auto_graph_rounded),
          label: Text(app.isPro
            ? 'Gráficos e análises avançadas'
            : 'Gráficos avançados · Pro'),
        ),
        if (app.isPro) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const ProRecordsScreen())),
            icon: const Icon(Icons.emoji_events_outlined),
            label: const Text('Todos os recordes'),
          ),
        ],
        const SizedBox(height: 26),
      ])),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FittedBox(fit: BoxFit.scaleDown, child: Text(value,
        style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w600,
          color: AppTheme.electricLime))),
      const SizedBox(height: 4),
      Text(label, maxLines: 2,
        style: const TextStyle(color: AppTheme.iceBlue, fontSize: 12)),
    ],
  );
}
