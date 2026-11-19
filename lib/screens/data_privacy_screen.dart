import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_controller.dart';
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

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _copyBackup(AppController app) async {
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
                child: Text(app.persistenceError!,
                    style: const TextStyle(color: Colors.orangeAccent)),
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
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _working ? null : () => _copyBackup(app),
                    icon: const Icon(Icons.content_copy_rounded),
                    label: const Text('Copiar backup JSON'),
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
