import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/page_body.dart';
import '../widgets/section_card.dart';
import '../widgets/pro_widgets.dart';
import 'evolution_screen.dart';
import 'pro_export_screen.dart';
import 'pro_radar_screen.dart';
import 'pro_records_screen.dart';

class ProOverviewScreen extends StatelessWidget {
  const ProOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final features = <({String eventKey, IconData icon, String title, String subtitle, WidgetBuilder page})>[
      (
        eventKey: 'pr_radar',
        icon: Icons.radar_rounded,
        title: context.strings.t('PR Radar e próximo alvo', 'PR Radar & next target', 'PR Radar y próximo objetivo'),
        subtitle: context.strings.t('Sinal heurístico de proximidade e metas por exercício.', 'Heuristic proximity score and exercise targets.', 'Indicador heurístico y metas por ejercicio.'),
        page: (_) => const ProRadarScreen(),
      ),
      (
        eventKey: 'gymrecords_iq',
        icon: Icons.auto_graph_rounded,
        title: 'GymRecords IQ',
        subtitle: context.strings.t('Relatórios a partir dos seus registros reais.', 'Reports calculated from your available logs.', 'Informes a partir de tus registros.'),
        page: (_) => const EvolutionScreen(),
      ),
      (
        eventKey: 'muscle_map',
        icon: Icons.accessibility_new_rounded,
        title: context.strings.t('Mapa muscular', 'Muscle groups', 'Grupos musculares'),
        subtitle: context.strings.t('Compare grupos e abra seus relatórios individualmente.', 'Compare groups and open their individual reports.', 'Compara grupos y abre sus informes.'),
        page: (_) => const EvolutionScreen(),
      ),
      (
        eventKey: 'records',
        icon: Icons.emoji_events_outlined,
        title: context.strings.t('Hall de recordes avançado', 'Advanced record hall', 'Salón de récords avanzado'),
        subtitle: context.strings.t('Recordes, repetições e atalhos por grupo.', 'Records, repetitions and shortcuts by group.', 'Récords, repeticiones y accesos por grupo.'),
        page: (_) => const ProRecordsScreen(),
      ),
      (
        eventKey: 'charts',
        icon: Icons.show_chart_rounded,
        title: context.strings.t('Gráficos avançados', 'Advanced charts', 'Gráficos avanzados'),
        subtitle: context.strings.t('Filtre métricas por período e grupo muscular.', 'Filter metrics by date range and muscle group.', 'Filtra métricas por periodo y grupo.'),
        page: (_) => const EvolutionScreen(),
      ),
      (
        eventKey: 'export',
        icon: Icons.file_download_outlined,
        title: context.strings.t('Exportação CSV/PDF', 'CSV/PDF export', 'Exportación CSV/PDF'),
        subtitle: context.strings.t('Copie seu CSV ou compartilhe um relatório PDF.', 'Copy CSV or share a PDF report.', 'Copia CSV o comparte un PDF.'),
        page: (_) => const ProExportScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Row(mainAxisSize: MainAxisSize.min, children: [Text('GymRecords Pro'), SizedBox(width: 9), ProPill()]),
      ),
      body: PageBody(
        child: ListView(padding: const EdgeInsets.only(bottom: 30), children: [
          const SizedBox(height: 12),
          ProFeatureCard(
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const ProPill(label: 'GYMRECORDS PRO'),
                const SizedBox(height: 12),
                Text(context.strings.t('Sua evolução, com inteligência.', 'Your progress, with intelligence.', 'Tu progreso, con inteligencia.'), style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(context.strings.t('Métricas, tendências e recordes com base no histórico disponível.', 'Metrics, trends and records based on your available history.', 'Métricas, tendencias y récords de tu historial.'), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.iceBlue, height: 1.35)),
              ])),
              const SizedBox(width: 10),
              Image.asset('assets/branding/pro_mascot.webp', width: 112, height: 108, fit: BoxFit.contain),
            ]),
          ),
          const SizedBox(height: 16),
          SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('O que é gratuito?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 7),
            const Text('Registro de séries, histórico completo, edição, favoritos, '
                'exercícios personalizados e exportação básica CSV/PDF.',
              style: TextStyle(color: AppTheme.iceBlue)),
            const Divider(),
            Text('O que poderá ser Pro?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 7),
            const Text('Gráficos avançados, objetivos e relatórios detalhados. '
                'Sincronização na nuvem fica para outra versão.',
              style: TextStyle(color: AppTheme.iceBlue)),
            const SizedBox(height: 10),
            const Text('Hipótese para pesquisa: R\$ 7,90–9,90/mês. '
                'Não há cobrança nem assinatura real nesta prévia.',
              style: TextStyle(color: AppTheme.warning)),
          ])),
          const SizedBox(height: 18),
          for (final feature in features) ...[
            Material(
              color: AppTheme.surfaceNavy,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  app.trackUsage('pro_feature_viewed', {'feature': feature.eventKey});
                  if (!app.isPro && feature.eventKey != 'export') {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.strings.t('Ative a prévia Pro para explorar os recursos.', 'Enable Pro preview to explore features.', 'Activa la vista Pro para explorar las funciones.'))));
                    return;
                  }
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: feature.page));
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.deepBlue), borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.accentBlueSoft, borderRadius: BorderRadius.circular(12)), child: Icon(feature.icon, color: AppTheme.electricLime)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(feature.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(feature.subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.3)),
                    ])),
                    const SizedBox(width: 6),
                    Icon(app.isPro ? Icons.chevron_right_rounded : Icons.lock_outline_rounded, color: AppTheme.iceBlue),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {
              app.setProPreview(!app.isPro);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.isPro ? context.strings.t('Prévia Pro ativada.', 'Pro preview enabled.', 'Vista Pro activada.') : context.strings.t('Prévia Pro desativada.', 'Pro preview disabled.', 'Vista Pro desactivada.'))));
            },
            icon: Icon(app.isPro ? Icons.check_circle_outline : Icons.workspace_premium_outlined),
            label: Text(app.isPro ? context.strings.t('Pro ativo nesta prévia', 'Pro active in this preview', 'Pro activo en esta vista') : context.strings.t('Ativar prévia Pro', 'Enable Pro preview', 'Activar vista Pro')),
          ),
          const SizedBox(height: 10),
          Text(context.strings.t('Assinatura real ainda não configurada; esta é uma prévia funcional.', 'Real billing is not configured; this is a functional preview.', 'La facturación real aún no está configurada.'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}
