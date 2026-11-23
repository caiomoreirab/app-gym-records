import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../models/workout_session.dart';
import '../services/completed_workout_summary.dart';
import '../services/weight_units.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/page_body.dart';
import '../widgets/section_card.dart';
import '../widgets/workout_svg_icon.dart';
import 'main_tabs_shell.dart';
import 'settings_screen.dart';

/// Celebration that reuses the classic dark/cyan GymRecords design.
class WorkoutCompletedScreen extends StatefulWidget {
  const WorkoutCompletedScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  State<WorkoutCompletedScreen> createState() => _WorkoutCompletedScreenState();
}

class _WorkoutCompletedScreenState extends State<WorkoutCompletedScreen> {
  final GlobalKey _shareCardKey = GlobalKey(debugLabel: 'workout-share-card');
  bool _sharing = false;

  Future<Uint8List> _captureCard() async {
    final cardContext = _shareCardKey.currentContext;
    if (cardContext == null) {
      throw StateError('Cartão ainda não disponível.');
    }
    await Scrollable.ensureVisible(cardContext,
      duration: const Duration(milliseconds: 160),
      alignment: .04);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) throw StateError('Tela fechada.');
    final boundary = _shareCardKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('Cartão indisponível.');
    }
    final image = await boundary.toImage(pixelRatio: 2.4);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Não foi possível gerar o PNG.');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> _downloadCard() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await _captureCard();
      await FileSaver.instance.saveFile(
        name: 'gymrecords_treino',
        bytes: bytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Imagem do treino preparada para salvar.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível salvar a imagem neste dispositivo.')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _share(CompletedWorkoutSummary summary) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await _captureCard();
      if (!mounted) return;
      final renderObject = context.findRenderObject();
      Rect? origin;
      if (renderObject is RenderBox) {
        origin = renderObject.localToGlobal(Offset.zero) & renderObject.size;
      }
      final result = await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png',
          name: 'gymrecords-treino.png')],
        fileNameOverrides: const ['gymrecords-treino.png'],
        text: 'Meu treino no GymRecords',
        downloadFallbackEnabled: true,
        sharePositionOrigin: origin,
      ));
      if (mounted && result.status == ShareResultStatus.success) {
        AppScope.of(context).markRecordShared();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Treino compartilhado.')));
      } else if (mounted && result.status == ShareResultStatus.unavailable) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Compartilhamento indisponível. Use Salvar imagem PNG.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Não foi possível compartilhar. Use Salvar imagem PNG.'),
          action: SnackBarAction(label: 'Salvar imagem',
            onPressed: _downloadCard),
        ));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _duration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 1) return 'menos de 1 min';
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}min';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    WorkoutSession? session;
    for (final current in app.sessions) {
      if (current.id == widget.sessionId) session = current;
    }
    if (session == null || session.completedAt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treino concluído')),
        body: const Center(child: Text(
          'Esse treino não foi encontrado no dispositivo.')),
      );
    }
    final summary = CompletedWorkoutSummary(
      session: session,
      machines: app.machines,
      bodyWeightKg: app.bodyWeightKg,
    );

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        title: const Text('Resumo do treino'),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: PageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              RepaintBoundary(
                key: _shareCardKey,
                child: _ShareCard(
                  summary: summary,
                  weightUnit: app.unit,
                  dateText: _date(session.completedAt!.toLocal()),
                  durationText: _duration(summary.duration),
                ),
              ),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: Text('Exercícios realizados',
                  style: Theme.of(context).textTheme.titleLarge)),
                Text('${summary.exerciseCount} no total',
                  style: const TextStyle(color: AppTheme.iceBlue,
                    fontSize: 13)),
              ]),
              const SizedBox(height: 10),
              if (summary.exercises.isEmpty)
                const SectionCard(child: Text(
                  'Nenhuma série registrada nesta sessão.',
                  style: TextStyle(color: AppTheme.iceBlue)))
              else
                SectionCard(child: Column(children: [
                  for (final entry in summary.exercises.entries) ...[
                    if (entry.key != summary.exercises.keys.first)
                      const Divider(color: AppTheme.deepBlue, height: 16),
                    Row(children: [
                      const WorkoutSvgIcon(WorkoutGlyph.check, size: 22),
                      const SizedBox(width: 10),
                      Expanded(child: Text(entry.key,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                      const SizedBox(width: 8),
                      Text('${entry.value.length} séries',
                        style: const TextStyle(color: AppTheme.iceBlue,
                          fontSize: 13)),
                    ]),
                  ],
                ])),
              const SizedBox(height: 16),
              if (summary.estimatedKcal == null)
                SectionCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Calorias estimadas: —',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text(
                      'Para obter uma estimativa, informe seu peso corporal '
                      'e registre um treino com duração válida.',
                      style: TextStyle(color: AppTheme.iceBlue,
                        fontSize: 13)),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen())),
                      icon: const Icon(Icons.monitor_weight_outlined),
                      label: const Text('Informar peso no Perfil'),
                    ),
                  ],
                )),
              if (summary.estimatedKcal == null)
                const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  'Gasto energético estimado por 3,5 MET para musculação '
                  'geral. Considera a duração total, incluindo descansos. '
                  'Não equivale a uma medição individual.',
                  style: TextStyle(color: AppTheme.iceBlue,
                    fontSize: 12, height: 1.45),
                ),
              ),
              if (app.persistenceError != null) ...[
                const SizedBox(height: 14),
                const SectionCard(child: Text(
                  'Falha ao salvar dados no dispositivo. '
                  'Verifique o armazenamento antes de compartilhar.',
                  style: TextStyle(color: AppTheme.warning))),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                key: const Key('share_completed_workout'),
                onPressed: _sharing || app.persistenceError != null
                  ? null : () => _share(summary),
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(_sharing
                  ? 'Preparando cartão...' : 'Compartilhar treino'),
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                key: const Key('download_workout_card'),
                onPressed: _sharing ? null : _downloadCard,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Salvar imagem PNG'),
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => const MainTabsShell(initialIndex: 2)),
                  (_) => false),
                icon: const Icon(Icons.history_rounded),
                label: const Text('Ver histórico'),
              ),
              const SizedBox(height: 7),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.summary,
    required this.weightUnit,
    required this.dateText,
    required this.durationText,
  });

  final CompletedWorkoutSummary summary;
  final String weightUnit;
  final String dateText;
  final String durationText;

  String _time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.accentBlueSoft,
          AppTheme.surfaceNavy, AppTheme.surfaceNavy],
        stops: [0.0, 0.48, 1.0],
      ),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: AppTheme.deepBlue),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 17),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Image.asset('assets/branding/icon_blue.png',
              width: 34, height: 34, fit: BoxFit.contain),
            const SizedBox(width: 8),
            const Expanded(child: Text.rich(TextSpan(children: [
              TextSpan(text: 'Gym',
                style: TextStyle(color: AppTheme.polarWhite)),
              TextSpan(text: 'Records',
                style: TextStyle(color: AppTheme.electricLime)),
            ]), style: TextStyle(fontSize: 19,
              fontWeight: FontWeight.w600))),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: AppTheme.deepNavy,
                border: Border.all(color: AppTheme.deepBlue),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 9, vertical: 6),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                WorkoutSvgIcon(WorkoutGlyph.check, size: 15),
                SizedBox(width: 5),
                Text('SALVO', style: TextStyle(
                  color: AppTheme.electricLime,
                  letterSpacing: 0.7, fontSize: 10,
                  fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 11),
          SizedBox(height: 131, child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 140, height: 116,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(90),
                  color: AppTheme.electricLime.withValues(alpha: .055),
                ),
              ),
              Image.asset('assets/branding/pro_mascot.webp',
                width: 131, height: 123, fit: BoxFit.contain),
              const Positioned(
                right: 38, top: 1,
                child: WorkoutSvgIcon(WorkoutGlyph.trophy, size: 39),
              ),
            ],
          )),
          const SizedBox(height: 4),
          Text('Treino concluído!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 29, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          const Text('Mais um passo na sua evolução.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.iceBlue, fontSize: 13)),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: AppTheme.deepNavy,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const WorkoutSvgIcon(WorkoutGlyph.calendar, size: 18),
                  const SizedBox(width: 7),
                  Text(dateText, style: const TextStyle(
                    color: AppTheme.polarWhite,
                    fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
              const SizedBox(height: 5),
              Text(
                'Início ${_time(summary.session.startedAt.toLocal())}'
                '    ·    Fim ${_time(summary.session.completedAt!.toLocal())}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.iceBlue, fontSize: 12),
              ),
            ]),
          ),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _HighlightMetric(
              glyph: WorkoutGlyph.clock,
              label: 'Duração',
              value: durationText,
            )),
            const SizedBox(width: 10),
            Expanded(child: _HighlightMetric(
              glyph: WorkoutGlyph.flame,
              label: 'Calorias estimadas',
              value: summary.estimatedKcal == null ? '—'
                : '${summary.estimatedKcal!.round()} kcal',
            )),
          ]),
          const SizedBox(height: 14),
          Container(height: 1, color: AppTheme.deepBlue),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _SmallMetric(
              glyph: WorkoutGlyph.dumbbell,
              value: '${summary.exerciseCount}',
              label: 'Exercícios')),
            const SizedBox(width: 6),
            Expanded(child: _SmallMetric(
              glyph: WorkoutGlyph.sets,
              value: '${summary.totalSets}',
              label: 'Séries')),
            const SizedBox(width: 6),
            Expanded(child: _SmallMetric(
              glyph: WorkoutGlyph.volume,
              value: WeightUnits.volumeForDisplay(summary.volumeKg, weightUnit).toStringAsFixed(0),
              label: 'Volume ($weightUnit)')),
          ]),
          if (summary.weightPersonalRecords > 0) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: AppTheme.accentBlueSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.deepBlue),
              ),
              child: Row(children: [
                const WorkoutSvgIcon(WorkoutGlyph.trophy, size: 25),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  '${summary.weightPersonalRecords} '
                  'novo(s) recorde(s) de carga',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          const Text('GYMRECORDS  ·  SEU PROGRESSO CONTA',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.iceBlue,
              letterSpacing: 1.1, fontSize: 9,
              fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}

class _HighlightMetric extends StatelessWidget {
  const _HighlightMetric({
    required this.glyph, required this.label, required this.value,
  });
  final WorkoutGlyph glyph;
  final String label, value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      vertical: 14, horizontal: 10),
    decoration: BoxDecoration(
      color: AppTheme.deepNavy,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.deepBlue),
    ),
    child: Column(children: [
      WorkoutSvgIcon(glyph, size: 25),
      const SizedBox(height: 7),
      FittedBox(fit: BoxFit.scaleDown,
        child: Text(value, maxLines: 1,
          style: const TextStyle(
            color: AppTheme.polarWhite,
            fontSize: 25, fontWeight: FontWeight.w600))),
      const SizedBox(height: 5),
      Text(label, textAlign: TextAlign.center,
        maxLines: 2,
        style: const TextStyle(
          color: AppTheme.iceBlue, fontSize: 12)),
    ]),
  );
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({
    required this.glyph, required this.value, required this.label,
  });
  final WorkoutGlyph glyph;
  final String value, label;

  @override
  Widget build(BuildContext context) => Column(children: [
    WorkoutSvgIcon(glyph, size: 23),
    const SizedBox(height: 6),
    FittedBox(fit: BoxFit.scaleDown,
      child: Text(value, maxLines: 1,
        style: const TextStyle(fontSize: 22,
          fontWeight: FontWeight.w600))),
    const SizedBox(height: 3),
    Text(label, textAlign: TextAlign.center,
      maxLines: 2,
      style: const TextStyle(
        color: AppTheme.iceBlue, fontSize: 11)),
  ]);
}
