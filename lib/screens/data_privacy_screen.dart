import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import 'package:file_selector/file_selector.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_controller.dart';
import '../services/local_data_store.dart';
import '../services/firebase_usage_sink.dart';
import '../theme/app_theme.dart';
import '../widgets/page_body.dart';
import '../widgets/section_card.dart';

/// Offline-first controls for local data and optional analytics consent.
class DataPrivacyScreen extends StatefulWidget {
  const DataPrivacyScreen({super.key});

  @override
  State<DataPrivacyScreen> createState() => _DataPrivacyScreenState();
}

class _DataPrivacyScreenState extends State<DataPrivacyScreen> {
  bool _working = false;
  LocalDatabaseStatus? _dbStatus;

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _copyBackup(AppController app) async {
    if (app.storageRecoveryRequired) {
      _message('Não é seguro gerar backup vazio: o banco local não pôde ser lido. '
          'Restaure um backup válido ou procure suporte antes de limpar os dados.');
      return;
    }
    setState(() => _working = true);
    try {
      await app.flushPendingWrites();
      await Clipboard.setData(ClipboardData(text: app.exportBackup()));
      if (mounted) _message('Backup JSON copiado. Cole em um arquivo seguro fora do aplicativo.');
    } catch (error) {
      if (mounted) _message('Erro ao copiar backup: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _restoreBackup(AppController app) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final raw = data?.text;
    if (raw == null || raw.trim().isEmpty) {
      _message('Copie antes o conteúdo de um backup JSON.');
      return;
    }
    await _confirmRestore(app, raw);
  }

  Future<void> _importBackupFile(AppController app) async {
    try {
      const group = XTypeGroup(label: 'Backup GymRecords JSON',
        extensions: ['json'], mimeTypes: ['application/json']);
      final file = await openFile(acceptedTypeGroups: [group]);
      if (file == null || !mounted) return;
      if (await file.length() > 25 * 1024 * 1024) {
        _message('O arquivo ultrapassa 25 MB. Verifique o backup.');
        return;
      }
      final raw = await file.readAsString();
      if (!mounted) return;
      if (raw.trim().isEmpty) {
        _message('O arquivo JSON está vazio. O histórico não foi alterado.');
        return;
      }
      await _confirmRestore(app, raw);
    } catch (error) {
      if (mounted) _message('Não foi possível abrir o arquivo: $error');
    }
  }

  Future<void> _downloadBackup(AppController app) async {
    if (app.storageRecoveryRequired) {
      _message('Dados locais indisponíveis. Não é seguro exportar backup vazio.');
      return;
    }
    setState(() => _working = true);
    try {
      await app.flushPendingWrites();
      if (app.persistenceError != null) {
        throw StateError('Verifique o erro de gravação antes de exportar.');
      }
      final now = DateTime.now();
      final date = '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      await FileSaver.instance.saveFile(
        name: 'gymrecords_backup_$date',
        bytes: Uint8List.fromList(utf8.encode(app.exportBackup())),
        fileExtension: 'json',
        mimeType: MimeType.json,
      );
      if (mounted) _message('Arquivo de backup JSON preparado. Guarde-o fora do app.');
    } catch (error) {
      if (mounted) _message('Não foi possível salvar o arquivo: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _confirmRestore(AppController app, String raw) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restaurar backup?'),
        content: const Text(
          'Isso substituirá o histórico de musculação, Cardio e exercícios '
          'personalizados deste dispositivo. Faça um backup atual antes de continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _working = true);
    try {
      await app.importBackup(raw);
      if (mounted) _message('Backup restaurado com sucesso.');
    } on FormatException catch (error) {
      if (mounted) _message('Backup inválido: ${error.message}');
    } catch (error) {
      if (mounted) _message('Não foi possível restaurar: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _checkIntegrity(AppController app) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final result = await app.checkLocalDatabaseIntegrity();
      if (!mounted) return;
      setState(() => _dbStatus = result);
      _message(result == null
        ? 'A verificação SQLite está disponível apenas no Android e iOS.'
        : result.isHealthy
          ? 'Banco SQLite verificado: estrutura e registros consistentes.'
          : 'A verificação encontrou divergências. Exporte o backup e não '
            'limpe os dados do aplicativo.');
    } catch (error) {
      if (mounted) _message('Não foi possível verificar o banco: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _retrySave(AppController app) async {
    setState(() => _working = true);
    try {
      final saved = await app.retrySave();
      if (!mounted) return;
      _message(saved ? 'Dados locais salvos com sucesso.' :
          'O banco não pôde ser recuperado. Seus dados não foram sobrescritos.');
    } catch (error) {
      if (mounted) _message('Erro ao tentar salvar: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _recoverPreviousSqlite(AppController app) async {
    if (_working || !app.supportsPreviousSqliteSnapshot) return;
    final confirmed = await showDialog<bool>(context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Recuperar cópia local anterior?'),
        content: const Text(
          'O GymRecords tentará restaurar a última versão válida '
          'guardada pelo SQLite. Alterações mais recentes podem ser '
          'perdidas. Nenhum dado será apagado sem uma cópia recuperável.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Recuperar')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _working = true);
    try {
      final recovered = await app.restorePreviousLocalSnapshot();
      if (mounted) _message(recovered
        ? 'Cópia local anterior restaurada.'
        : 'Não há uma cópia local anterior disponível.');
    } catch (e) {
      if (mounted) _message('Não foi possível recuperar: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final strengthCount = app.machines.fold<int>(0, (sum, m) => sum + m.records.length);
    final cardioCount = app.cardioActivities.fold<int>(0, (sum, a) => sum + a.records.length);
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: const Text('Dados e privacidade')),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const SizedBox(height: 14),
            Text('Seus treinos pertencem a você',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'O GymRecords funciona sem login e sem conexão à internet. '
              'Seus registros ficam armazenados neste dispositivo.',
            ),
            const SizedBox(height: 18),
            if (app.persistenceError != null) ...[
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.persistenceError!,
                        style: const TextStyle(color: Colors.orangeAccent)),
                    const SizedBox(height: 12),
                    Text(app.storageRecoveryRequired
                        ? 'Proteção ativada: não gravaremos dados sobre um banco '
                          'que não conseguimos ler. Não limpe os dados do app.'
                        : 'O armazenamento pode estar temporariamente indisponível. '
                          'Se necessário, copie um backup e tente salvar novamente.'),
                    if (!app.storageRecoveryRequired) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _working ? null : () => _retrySave(app),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tentar salvar novamente'),
                      ),
                    ] else if (app.supportsPreviousSqliteSnapshot) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('recover_sqlite_previous'),
                        onPressed: _working
                          ? null : () => _recoverPreviousSqlite(app),
                        icon: const Icon(Icons.restore_rounded),
                        label: const Text('Recuperar cópia local anterior'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Armazenamento local',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('$strengthCount registros de musculação • $cardioCount de Cardio'),
                  const SizedBox(height: 10),
                  const Text(
                    'Android e iOS: SQLite privado do app. Na prévia Web, '
                    'os dados ficam no navegador. Não há sincronização entre eles.',
                  ),
                  if (app.supportsPreviousSqliteSnapshot) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('verify_sqlite_integrity'),
                      onPressed: _working ? null : () => _checkIntegrity(app),
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text('Verificar banco local'),
                    ),
                    if (_dbStatus != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _dbStatus!.isHealthy
                          ? 'SQLite v${_dbStatus!.schemaVersion} íntegro · '
                            '${_dbStatus!.actualCounts['workout_sessions']} treinos · '
                            '${_dbStatus!.actualCounts['workout_sets']} séries · '
                            '${_dbStatus!.actualCounts['cardio_entries']} registros de cardio'
                          : 'Atenção: divergência no SQLite. '
                            'Verifique e faça backup dos dados.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _dbStatus!.isHealthy
                            ? AppTheme.iceBlue : AppTheme.warning,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _working ? null : () => _copyBackup(app),
                    icon: const Icon(Icons.content_copy_rounded),
                    label: const Text('Copiar backup JSON'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('download_backup_json'),
                    onPressed: _working ? null : () => _downloadBackup(app),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Salvar arquivo JSON'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('import_backup_file'),
                    onPressed: _working ? null : () => _importBackupFile(app),
                    icon: const Icon(Icons.file_open_outlined),
                    label: const Text('Restaurar de arquivo JSON'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _working ? null : () => _restoreBackup(app),
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Restaurar backup copiado'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Salve o JSON em um arquivo seguro. Desinstalar o app '
                    'ou limpar dados pode excluir os treinos locais.',
                    style: TextStyle(fontSize: 12, color: AppTheme.iceBlue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Métricas de uso (opcional)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Autorizar métricas de uso'),
                    subtitle: Text(
                      FirebaseUsageSink.isConfigured
                          ? 'Ao autorizar, eventos de uso poderão ser enviados '
                            'ao Firebase, que utiliza identificadores de instalação. '
                            'Não enviamos nomes, pesos ou anotações.'
                          : 'A coleta ainda não está disponível: o Firebase '
                            'não está configurado nesta versão.',
                    ),
                    value: app.analyticsConsent,
                    onChanged: FirebaseUsageSink.isConfigured ? app.setAnalyticsConsent : null,
                  ),
                  const Text(
                    'Nenhum nome, peso, anotação ou histórico pessoal '
                    'será enviado em eventos. Registrar treinos continuará offline.',
                    style: TextStyle(fontSize: 12, color: AppTheme.iceBlue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
