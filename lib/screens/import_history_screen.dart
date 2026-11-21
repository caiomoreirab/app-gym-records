import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../services/csv_history_import_service.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

/// Explicit import screen; never silently overwrites workouts.
class ImportHistoryScreen extends StatefulWidget {
  const ImportHistoryScreen({super.key});
  @override
  State<ImportHistoryScreen> createState() => _ImportHistoryScreenState();
}
class _ImportHistoryScreenState extends State<ImportHistoryScreen> {
  final textController = TextEditingController();
  List<CsvWorkoutEntry>? preview;
  String? error;
  String? result;
  bool importing = false;

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> _clipboard() async {
    try {
      final content = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      textController.text = content?.text ?? '';
      _preview();
    } catch (e) {
      setState(() => error = 'Não foi possível ler a área de transferência: $e');
    }
  }

  void _preview() {
    try {
      final rows = CsvHistoryImportService.parse(textController.text);
      setState(() {
        preview = rows;
        error = rows.isEmpty ? 'Nenhuma série válida encontrada.' : null;
        result = null;
      });
    } catch (e) {
      setState(() {
        preview = null;
        result = null;
        error = e.toString();
      });
    }
  }

  Future<void> _import() async {
    final entries = preview;
    if (entries == null || entries.isEmpty || importing) return;
    final app = AppScope.of(context);
    final confirmed = await showDialog<bool>(context: context,
      builder: (d) => AlertDialog(
        title: const Text('Importar histórico?'),
        content: Text('Adicionar ${entries.length} linha(s) analisadas '
          'ao histórico local? Exporte um backup JSON antes de continuar. '
          'Exercícios não reconhecidos serão ignorados, sem criar nomes errados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(d, true),
            child: const Text('Importar')),
        ],
      ));
    if (confirmed != true || !mounted) return;
    setState(() => importing = true);
    try {
      final summary = app.importCsvEntries(entries);
      await app.flushPendingWrites();
      if (!mounted) return;
      setState(() => result = '${summary.imported} séries importadas · '
        '${summary.skipped} já existentes · '
        '${summary.unmatched} exercícios sem correspondência.');
      if (app.persistenceError != null && mounted) {
        setState(() => error = 'Falha de escrita local: ${app.persistenceError}');
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Importação não concluída: $e');
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: const Text('Importar histórico CSV')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const Text('Traga seus registros',
          style: TextStyle(fontSize: 26,fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Cole um CSV exportado do GymRecords ou um arquivo com colunas '
          'compatíveis de Hevy/Strong. Esta versão importa séries com data, '
          'exercício, carga e repetições; nomes desconhecidos não são importados.',
          style: TextStyle(color: AppTheme.iceBlue)),
        const SizedBox(height: 15),
        OutlinedButton.icon(
          onPressed: _clipboard,
          icon: const Icon(Icons.content_paste_go_rounded),
          label: const Text('Colar CSV da área de transferência')),
        const SizedBox(height: 12),
        TextField(controller: textController, minLines: 5,maxLines: 10,
          decoration: const InputDecoration(
            labelText: 'Conteúdo CSV',
            alignLabelWithHint: true,
            hintText: 'date,exercise,weight,repetitions\n2026-11-20,Supino reto com barra,80,10')),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: _preview,
          icon: const Icon(Icons.preview_outlined),
          label: const Text('Conferir dados')),
        if (preview case final entries?) ...[
          const SizedBox(height: 15),
          Text('${entries.length} série(s) interpretadas',
            style: const TextStyle(color: AppTheme.electricLime,
              fontWeight: FontWeight.bold)),
          for (final item in entries.take(5))
            ListTile(dense: true,
              title: Text(item.exercise),
              subtitle: Text('${item.weight} kg × ${item.repetitions} · '
                '${item.date.day}/${item.date.month}/${item.date.year}')),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: importing || entries.isEmpty ? null : _import,
            icon: const Icon(Icons.file_download_done_outlined),
            label: Text(importing ? 'Importando...' : 'Confirmar importação')),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: AppTheme.warning)),
        ],
        if (result != null) ...[
          const SizedBox(height: 12),
          Text(result!, style: const TextStyle(color: AppTheme.success)),
        ],
      ]),
    );
  }
}
