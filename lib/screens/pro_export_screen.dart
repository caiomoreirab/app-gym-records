import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/muscle_group.dart';
import '../services/analytics_service.dart';
import '../services/report_export_service.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/analytics_widgets.dart';
import '../widgets/page_body.dart';
import '../widgets/pro_widgets.dart';
import '../widgets/section_card.dart';
import 'pro_overview_screen.dart';

class ProExportScreen extends StatefulWidget {
  const ProExportScreen({super.key});
  @override
  State<ProExportScreen> createState() => _ProExportScreenState();
}

class _ProExportScreenState extends State<ProExportScreen> {
  MuscleGroup? _group;
  AnalyticsPeriod _period = AnalyticsPeriod.all;
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.isPro) return const ProOverviewScreen();
    final entries = ReportExportService.entries(
      machines: app.machines,
      cardioActivities: app.cardioActivities,
      period: _period,
      now: DateTime.now(),
      group: _group,
    );
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: Text(context.strings.t('Exportar dados', 'Export data', 'Exportar datos'))),
      body: PageBody(
        child: ListView(padding: const EdgeInsets.only(bottom: 30), children: [
          const SizedBox(height: 12),
          Text(context.strings.t('Selecione o que exportar', 'Choose what to export', 'Elige qué exportar'), style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          AnalyticsFilters(group: _group, period: _period, onGroupChanged: (g) => setState(() => _group = g), onPeriodChanged: (p) => setState(() => _period = p)),
          const SizedBox(height: 20),
          ProFeatureCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${entries.length} ${context.strings.t('registros selecionados', 'selected records', 'registros seleccionados')}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(context.strings.t('O relatório usa somente os registros disponíveis nesta versão de validação.', 'The report uses only records available in this preview.', 'El informe usa solamente los registros disponibles en esta vista previa.'), style: Theme.of(context).textTheme.bodySmall),
          ])),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _working ? null : () async {
              await Clipboard.setData(ClipboardData(text: ReportExportService.toCsv(entries)));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.strings.t('CSV copiado para a área de transferência.', 'CSV copied to clipboard.', 'CSV copiado al portapapeles.'))));
            },
            icon: const Icon(Icons.table_rows_rounded),
            label: Text(context.strings.t('Copiar CSV', 'Copy CSV', 'Copiar CSV')),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _working ? null : () async {
              setState(() => _working = true);
              try {
                await ReportExportService.sharePdf(
                  entries: entries,
                  title: 'GymRecords - Relatorio',
                  subtitle: '${_period.label(Localizations.localeOf(context))} • ${_group?.label ?? 'Todos os grupos'}',
                );
              } catch (error) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao gerar PDF: $error')));
              } finally {
                if (mounted) setState(() => _working = false);
              }
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(_working ? context.strings.t('Gerando...', 'Generating...', 'Generando...') : context.strings.t('Gerar e compartilhar PDF', 'Generate & share PDF', 'Generar y compartir PDF')),
          ),
          const SizedBox(height: 20),
          Text(context.strings.t('Prévia dos dados', 'Data preview', 'Vista previa de datos'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            SectionCard(child: Text(context.strings.t('Nenhum registro neste filtro.', 'No records in this filter.', 'No hay registros en este filtro.')))
          else
            SectionCard(child: Column(children: [
              for (final entry in entries.take(15)) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(children: [
                    Expanded(child: Text(entry.exercise, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall)),
                    Text('${entry.date.day}/${entry.date.month}', style: const TextStyle(color: AppTheme.iceBlue)),
                    const SizedBox(width: 10),
                    Text(entry.weight > 0 ? '${entry.weight.toStringAsFixed(1)} kg' : entry.repetitions != null ? '${entry.repetitions} reps' : entry.distanceKm != null ? '${entry.distanceKm!.toStringAsFixed(2)} km' : '—', style: const TextStyle(color: AppTheme.electricLime)),
                  ]),
                ),
              ],
            ])),
        ]),
      ),
    );
  }
}
