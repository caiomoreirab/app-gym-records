import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/muscle_group.dart';
import '../services/analytics_service.dart';
import '../services/report_export_service.dart';
import '../services/weight_units.dart';
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

  Future<void> _savePdfLocally(List<ReportEntry> entries) async {
    if (entries.isEmpty || _working) return;
    setState(() => _working = true);
    try {
      final data = await ReportExportService.buildPdf(
        entries: entries, title: 'GymRecords - Relatório',
        subtitle: 'Histórico de treinos · pesos em kg, distância em km',
      );
      final now = DateTime.now();
      final name = 'gymrecords_relatorio_${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
      await FileSaver.instance.saveFile(
        name: name, bytes: data,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
          'Arquivo PDF gerado. Confira os downloads ou arquivos do dispositivo.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível baixar PDF: $error')));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

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
            Text(context.strings.t(
              'CSV e PDF exportam peso em kg e distância em km, independentemente da unidade escolhida no app.',
              'CSV and PDF use kg for weights and km for distances, regardless of the display units.',
              'CSV y PDF usan kg para pesos y km para distancias, independientemente de las unidades de pantalla.'
            ), style: Theme.of(context).textTheme.bodySmall),
          ])),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('export_csv_button'),
            onPressed: _working || entries.isEmpty ? null : () async {
              await Clipboard.setData(ClipboardData(text: ReportExportService.toCsv(entries)));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.strings.t('CSV copiado para a área de transferência.', 'CSV copied to clipboard.', 'CSV copiado al portapapeles.'))));
            },
            icon: const Icon(Icons.table_rows_rounded),
            label: Text(context.strings.t('Copiar CSV', 'Copy CSV', 'Copiar CSV')),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const Key('share_pdf_button'),
            onPressed: _working || entries.isEmpty ? null : () async {
              setState(() => _working = true);
              try {
                await ReportExportService.sharePdf(
                  entries: entries,
                  title: 'GymRecords - Relatorio',
                  subtitle: '${_period.label(Localizations.localeOf(context))} • ${_group?.label ?? 'Todos os grupos'}',
                );
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(
                    'PDF enviado ao compartilhamento. Se não houver janela, use Baixar PDF.')));

              } catch (error) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao gerar PDF: $error')));
              } finally {
                if (mounted) setState(() => _working = false);
              }
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(_working ? context.strings.t('Gerando...', 'Generating...', 'Generando...') : context.strings.t('Gerar e compartilhar PDF', 'Generate & share PDF', 'Generar y compartir PDF')),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const Key('download_pdf'),
            onPressed: _working || entries.isEmpty
              ? null : () => _savePdfLocally(entries),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Baixar PDF'),
          ),
          const SizedBox(height: 20),
          Text(context.strings.t('Prévia dos dados', 'Data preview', 'Vista previa de datos'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            SectionCard(child: Text(context.strings.t(
              'Nenhum registro neste filtro. Altere o período ou grupo muscular para exportar. '
              'Os botões de exportação permanecem indisponíveis até haver dados.',
              'No records for this filter. Change the period or muscle group to export.',
              'No hay registros con este filtro. Cambia el período o el grupo muscular.'
            )))
          else
            SectionCard(child: Column(children: [
              for (final entry in entries.take(15)) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(children: [
                    Expanded(child: Text(entry.exercise, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall)),
                    Text('${entry.date.day}/${entry.date.month}', style: const TextStyle(color: AppTheme.iceBlue)),
                    const SizedBox(width: 10),
                    Flexible(child: Text(
                      entry.weight > 0
                        ? '${WeightUnits.format(entry.weight, app.unit, Localizations.localeOf(context))} ${app.unit}'
                        : entry.repetitions != null
                          ? '${entry.repetitions} reps'
                          : entry.distanceKm != null
                            ? '${(app.distanceUnit == 'mi' ? entry.distanceKm! / 1.609344 : entry.distanceKm!).toStringAsFixed(2)} ${app.distanceUnit}'
                            : '—',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.electricLime))),
                  ]),
                ),
              ],
            ])),
        ]),
      ),
    );
  }
}
