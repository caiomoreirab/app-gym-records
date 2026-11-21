import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../models/workout_session.dart';
import '../services/completed_workout_summary.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/page_body.dart';
import '../widgets/section_card.dart';
import 'reports_hub_screen.dart';
import 'settings_screen.dart';

/// One post-workout celebration. Never guesses missing body weight or duration.
class WorkoutCompletedScreen extends StatefulWidget {
  const WorkoutCompletedScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  State<WorkoutCompletedScreen> createState() => _WorkoutCompletedScreenState();
}

class _WorkoutCompletedScreenState extends State<WorkoutCompletedScreen> {
  final GlobalKey _shareCardKey = GlobalKey(debugLabel: 'workout-share-card');
  bool _sharing = false;

  Future<void> _share(CompletedWorkoutSummary summary) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary = _shareCardKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('Cartão não está disponível para compartilhamento.');
      }
      final img = await boundary.toImage(pixelRatio: 2.5);
      final raw = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      if (raw == null) throw StateError('Não foi possível gerar o PNG.');
      if (!mounted) return;
      final rectObject = context.findRenderObject();
      Rect? origin;
      if (rectObject is RenderBox) {
        origin = rectObject.localToGlobal(Offset.zero) & rectObject.size;
      }
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(raw.buffer.asUint8List(),
            mimeType: 'image/png',
            name: 'gymrecords-treino-${summary.session.id}.png')],
          fileNameOverrides: [
            'gymrecords-treino.png',
          ],
          text: 'Meu treino no GymRecords 🏆',
          sharePositionOrigin: origin,
        ),
      );
      if (mounted && result.status == ShareResultStatus.success) {
        AppScope.of(context).localMetrics.sharedRecord();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treino compartilhado.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Não foi possível compartilhar a imagem: $e')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _dateTime(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year} · '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  String _clock(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  String _duration(Duration duration) {
    final total = duration.inMinutes;
    if (total < 1) return 'menos de 1 min';
    if (total < 60) return '$total min';
    return '${total ~/ 60}h ${(total % 60).toString().padLeft(2, '0')}min';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    WorkoutSession? session;
    for (final s in app.sessions) {
      if (s.id == widget.sessionId) session = s;
    }
    if (session == null || session.completedAt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treino finalizado')),
        body: const Center(child: Text('Treino não encontrado neste dispositivo.')),
      );
    }
    final summary = CompletedWorkoutSummary(
      session: session, machines: app.machines,
      bodyWeightKg: app.bodyWeightKg,
    );
    final kcal = summary.estimatedKcal;
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: const Text('Resumo do treino'),
        leading: BackButton(onPressed: () => Navigator.of(context).pop())),
      body: PageBody(child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 8),
          Center(child: Image.asset('assets/branding/pro_mascot.webp',
            width: 148, height: 125, fit: BoxFit.contain)),
          const SizedBox(height: 4),
          Text('Treino concluído! 🏆',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            app.displayName.isEmpty ? 'Mais um treino registrado.'
              : 'Boa, ${app.displayName}! Mais um treino registrado.',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.iceBlue)),
          const SizedBox(height: 18),
          RepaintBoundary(
            key: _shareCardKey,
            child: _ShareCard(
              summary: summary,
              dateText: _dateTime(session.completedAt!.toLocal()),
              durationText: _duration(summary.duration),
            ),
          ),
          const SizedBox(height: 16),
          if (app.persistenceError != null) ...[
            const SectionCard(child: Text(
              'Atenção: houve um problema ao salvar seus dados. '
              'Não apague o histórico e tente novamente antes de compartilhar.',
              style: TextStyle(color: AppTheme.warning))),
            const SizedBox(height: 12),
          ],
          Text('Exercícios realizados',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (summary.exercises.isEmpty)
            const SectionCard(child: Text(
              'Treino finalizado sem séries registradas.',
              style: TextStyle(color: AppTheme.iceBlue))),
          for (final item in summary.exercises.entries) ...[
            SectionCard(child: Row(children: [
              const Icon(Icons.check_circle_outline_rounded,
                color: AppTheme.electricLime),
              const SizedBox(width: 12),
              Expanded(child: Text(item.key,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600))),
              const SizedBox(width: 8),
              Text('${item.value.length} séries',
                style: const TextStyle(color: AppTheme.iceBlue)),
            ])),
            const SizedBox(height: 8),
          ],
          if (kcal == null) ...[
            const SizedBox(height: 10),
            SectionCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Calorias estimadas: —',
                  style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                const Text(
                  'Informe seu peso corporal no Perfil para estimar '
                  'o gasto energético de treinos com duração válida.',
                  style: TextStyle(color: AppTheme.iceBlue)),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
                  icon: const Icon(Icons.monitor_weight_outlined),
                  label: const Text('Configurar peso no Perfil')),
              ],
            )),
          ],
          const SizedBox(height: 8),
          const Text(
            'Estimativa de calorias: 3,5 MET (musculação geral, Compêndio 2024). '
            'Considera duração total, incluindo pausas. '
            'Não é uma medição individual nem uma meta de gasto energético.',
            style: TextStyle(color: AppTheme.iceBlue, fontSize: 12),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('share_completed_workout'),
            onPressed: _sharing || app.persistenceError != null
              ? null : () => _share(summary),
            icon: Icon(_sharing ? Icons.hourglass_top_rounded
              : Icons.ios_share_rounded),
            label: Text(_sharing ? 'Preparando imagem...' : 'Compartilhar treino')),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const ReportsHubScreen()),
              (_) => false),
            icon: const Icon(Icons.history_rounded),
            label: const Text('Ver histórico')),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Voltar para o início')),
        ],
      )),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.summary,
    required this.dateText,
    required this.durationText,
  });
  final CompletedWorkoutSummary summary;
  final String dateText, durationText;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.surfaceNavy,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppTheme.deepBlue),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Image.asset('assets/branding/icon_blue.png',
          width: 39, height: 39, fit: BoxFit.contain),
        const SizedBox(width: 8),
        const Expanded(child: Text.rich(TextSpan(children: [
          TextSpan(text: 'Gym', style: TextStyle(color: AppTheme.polarWhite)),
          TextSpan(text: 'Records', style: TextStyle(color: AppTheme.electricLime)),
        ]), style: TextStyle(fontSize: 20,
          fontWeight: FontWeight.w600))),
        const Icon(Icons.emoji_events_rounded,
          color: AppTheme.electricLime, size: 29),
      ]),
      const SizedBox(height: 12),
      const Text('TREINO CONCLUÍDO',
        style: TextStyle(color: AppTheme.electricLime,
          fontSize: 13, fontWeight: FontWeight.w600,
          letterSpacing: 1.2)),
      const SizedBox(height: 3),
      Text(dateText, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppTheme.iceBlue, fontSize: 13)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _SummaryMetric(
          icon: Icons.timer_outlined,
          value: durationText, label: 'Duração')),
        const SizedBox(width: 8),
        Expanded(child: _SummaryMetric(
          icon: Icons.local_fire_department_outlined,
          value: summary.estimatedKcal == null ? '—'
            : '${summary.estimatedKcal!.round()} kcal',
          label: 'Estimativa')),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _SummaryMetric(
          icon: Icons.fitness_center_rounded,
          value: '${summary.exerciseCount}', label: 'Exercícios')),
        const SizedBox(width: 8),
        Expanded(child: _SummaryMetric(
          icon: Icons.repeat_rounded,
          value: '${summary.totalSets}', label: 'Séries')),
      ]),
      const SizedBox(height: 13),
      const Divider(color: AppTheme.deepBlue),
      const SizedBox(height: 7),
      Row(children: [
        Expanded(child: Text('Volume registrado',
          style: Theme.of(context).textTheme.bodyMedium)),
        Text('${summary.volumeKg.toStringAsFixed(0)} kg',
          style: const TextStyle(color: AppTheme.electricLime,
            fontSize: 20, fontWeight: FontWeight.w600)),
      ]),
      if (summary.weightPersonalRecords > 0) ...[
        const SizedBox(height: 8),
        Text('🏆 ${summary.weightPersonalRecords} recorde(s) de carga',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
      const SizedBox(height: 11),
      const Text('Sua evolução, uma série de cada vez.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.iceBlue, fontSize: 12)),
    ]),
  );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon, required this.value, required this.label,
  });
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.deepNavy,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.deepBlue),
    ),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 9),
    child: Column(children: [
      Icon(icon, size: 23, color: AppTheme.electricLime),
      const SizedBox(height: 5),
      FittedBox(fit: BoxFit.scaleDown,
        child: Text(value, maxLines: 1,
          style: const TextStyle(fontSize: 22,
            fontWeight: FontWeight.w600))),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(
        color: AppTheme.iceBlue, fontSize: 12)),
    ]),
  );
}
