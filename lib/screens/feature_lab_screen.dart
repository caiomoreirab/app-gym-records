import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/page_body.dart';
import '../widgets/section_card.dart';

/// Concept screens for product validation. No network, imports or payments.
class FeatureLabScreen extends StatefulWidget {
  const FeatureLabScreen({super.key});
  @override
  State<FeatureLabScreen> createState() => _FeatureLabScreenState();
}

class _FeatureLabScreenState extends State<FeatureLabScreen> {
  String _gym = 'Academia principal';
  int _remaining = 90;
  Timer? _timer;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    if (_remaining <= 0) setState(() => _remaining = 90);
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _remaining -= 1);
      if (_remaining <= 0) {
        timer.cancel();
        HapticFeedback.mediumImpact();
        setState(() { _remaining = 0; _running = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Descanso finalizado.')));
      }
    });
  }

  void _demoAlert(String title, String explanation) {
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(explanation),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx),
        child: const Text('Entendi'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 7));
    final recent = [for (final m in app.machines)
      for (final r in m.records) if (!r.date.isBefore(since)) r];
    final uniqueDays = recent.map((r) => DateTime(r.date.year,r.date.month,r.date.day)).toSet().length;
    final volume = recent.where((r) => !r.isWarmup).fold<double>(0,
      (sum,r) => sum+r.weight*(r.repetitions ?? 0));
    final minutes = _remaining ~/ 60;
    final seconds = (_remaining % 60).toString().padLeft(2,'0');
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: const Text('Laboratório de recursos')),
      body: PageBody(child: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        const SizedBox(height: 12),
        const Text('Propostas para a próxima fase',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Aqui você pode testar conceitos. Estes recursos não fazem parte do lançamento offline 1.0.',
          style: TextStyle(color: AppTheme.iceBlue)),
        const SizedBox(height: 18),
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Resumo semanal', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          const Text('Calculado com seus registros locais dos últimos 7 dias.',
            style: TextStyle(color: AppTheme.iceBlue)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('Dias', uniqueDays.toString()),
            _stat('Séries', recent.length.toString()),
            _stat('Volume', volume.toStringAsFixed(0) + ' kg'),
          ]),
        ])),
        const SizedBox(height: 14),
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Temporizador de descanso', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          const Text('Funciona nesta tela. Notificações em segundo plano ficam para depois.',
            style: TextStyle(color: AppTheme.iceBlue)),
          const SizedBox(height: 10),
          Center(child: Text(minutes.toString() + ':' + seconds,
            style: const TextStyle(fontSize: 45, color: AppTheme.electricLime, fontWeight: FontWeight.w600))),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: _running ? null : () => setState(() => _remaining = 90),
              child: const Text('90 s'))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton(onPressed: _toggleTimer,
              child: Text(_running ? 'Pausar' : 'Iniciar'))),
          ]),
        ])),
        const SizedBox(height: 14),
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Academias diferentes', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          const Text('Conceito: cada academia pode ter regulagens e pesos próprios.',
            style: TextStyle(color: AppTheme.iceBlue)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            for (final name in ['Academia principal','Outra academia'])
              ChoiceChip(label: Text(name), selected: _gym == name,
                onSelected: (_) => setState(() => _gym = name)),
          ]),
          Text('Selecionada: ' + _gym + ' (demonstração, sem separar dados)',
            style: const TextStyle(color: AppTheme.iceBlue, fontSize: 12)),
        ])),
        const SizedBox(height: 14),
        _concept(Icons.camera_alt_outlined, 'Foto do aparelho',
          'Imagem personalizada para identificar cada máquina',
          'Requer acesso à câmera/galeria, permissões e estratégia de backup de fotos.'),
        const SizedBox(height: 12),
        _concept(Icons.file_upload_outlined, 'Importar Hevy, Strong ou CSV',
          'Trazer treinos de outros aplicativos',
          'A importação real depende dos layouts dos arquivos, identificação de exercícios e tratamento de duplicatas.'),
        const SizedBox(height: 12),
        _concept(Icons.image_outlined, 'Cartão de recorde para Stories',
          'Compartilhar sua evolução como imagem',
          'A geração e o compartilhamento de imagens ainda precisam ser implementados.'),
        const SizedBox(height: 12),
        _concept(Icons.workspace_premium_outlined, 'Conquistas e metas',
          'Consistência semanal, objetivos e comemorações',
          'O desenho das conquistas será validado primeiro, sem ranking social ou internet.'),
        const SizedBox(height: 12),
        _concept(Icons.cloud_outlined, 'Backup automático na nuvem',
          'Sincronização entre Android e iPhone',
          'Não disponível no lançamento 100% offline. Exige conta, backend e gestão de privacidade.'),
      ])),
    );
  }

  Widget _stat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
    Text(label, style: const TextStyle(color: AppTheme.iceBlue)),
  ]);

  Widget _concept(IconData icon, String title, String subtitle, String details) =>
      SectionCard(child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppTheme.electricLime),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.iceBlue)),
        trailing: const Icon(Icons.info_outline, color: AppTheme.warning),
        onTap: () => _demoAlert(title, details),
      ));
}
