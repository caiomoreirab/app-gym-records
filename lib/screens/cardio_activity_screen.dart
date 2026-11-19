import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/cardio_activity.dart';
import '../models/cardio_record.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/page_body.dart';
import '../widgets/cardio_visual_pager.dart';
import '../widgets/cardio_record_achievement_sheet.dart';
import '../widgets/section_card.dart';

class CardioActivityScreen extends StatefulWidget {
  const CardioActivityScreen({super.key, required this.activityId});

  final String activityId;

  @override
  State<CardioActivityScreen> createState() => _CardioActivityScreenState();
}

class _CardioActivityScreenState extends State<CardioActivityScreen> {
  final _distance = TextEditingController();
  final _minutes = TextEditingController();
  final _seconds = TextEditingController();
  final _heartRate = TextEditingController();
  final _calories = TextEditingController();
  final _incline = TextEditingController();
  final _resistance = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    for (final controller in [_distance, _minutes, _seconds, _heartRate, _calories, _incline, _resistance, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _number(String value) => double.tryParse(value.trim().replaceAll(',', '.'));
  int? _int(String value) => int.tryParse(value.trim());

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final activity = app.cardioActivities.firstWhere((item) => item.id == widget.activityId);
    final locale = Localizations.localeOf(context);
    final preview = _previewRecord(app.distanceUnit);

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(activity.localizedName(locale)),
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            const SizedBox(height: 8),
            _Hero(activity: activity),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.strings.registerCardio, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minutes,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(labelText: context.strings.t('Minutos', 'Minutes'), hintText: '30'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _seconds,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(labelText: context.strings.t('Segundos', 'Seconds'), hintText: '00'),
                        ),
                      ),
                    ],
                  ),
                  if (activity.supportsDistance) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _distance,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(labelText: '${context.strings.distance} (${app.distanceUnit})', hintText: '5,00'),
                    ),
                  ],
                  if (preview != null && (preview.paceMinutesPerKm != null || preview.averageSpeedKmh != null)) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (activity.supportsPace && preview.distanceKm != null)
                          Expanded(child: _Metric(label: context.strings.pace, value: _formatPace(_activityPace(preview, activity, app.distanceUnit), activity, app.distanceUnit))),
                        if (activity.supportsPace && preview.distanceKm != null) const SizedBox(width: 10),
                        if (preview.averageSpeedKmh != null)
                          Expanded(child: _Metric(label: context.strings.avgSpeed, value: _speedLabel(preview.averageSpeedKmh!, app.distanceUnit))),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    context.strings.t('Métricas opcionais', 'Optional metrics'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _heartRate, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: '${context.strings.heartRate} (bpm)'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: _calories, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: '${context.strings.calories} (kcal)'))),
                    ],
                  ),
                  if (activity.supportsIncline) ...[
                    const SizedBox(height: 10),
                    TextField(controller: _incline, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: '${context.strings.incline} (%)')),
                  ],
                  if (activity.supportsResistance) ...[
                    const SizedBox(height: 10),
                    TextField(controller: _resistance, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: context.strings.resistance)),
                  ],
                  const SizedBox(height: 10),
                  TextField(controller: _notes, maxLines: 2, decoration: InputDecoration(labelText: '${context.strings.notes} (${context.strings.optional})')),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _canSave(activity) ? () => _save(app, activity) : null,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(context.strings.saveRecord),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _PersonalBests(activity: activity),
            if (activity.records.isNotEmpty) ...[
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.strings.t('Histórico', 'History'), style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    for (final record in ([...activity.records]..sort((a, b) => b.date.compareTo(a.date))).take(6))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text('${record.date.day.toString().padLeft(2, '0')}/${record.date.month.toString().padLeft(2, '0')}/${record.date.year}')),
                            Text(_recordSummary(record), style: const TextStyle(color: AppTheme.electricLime, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  CardioRecord? _previewRecord(String distanceUnit) {
    final minutes = int.tryParse(_minutes.text) ?? 0;
    final seconds = int.tryParse(_seconds.text) ?? 0;
    final duration = Duration(minutes: minutes, seconds: seconds);
    if (duration.inSeconds <= 0) return null;
    final rawDistance = _number(_distance.text);
    final distanceKm = rawDistance == null ? null : (distanceUnit == 'mi' ? rawDistance * 1.609344 : rawDistance);
    return CardioRecord(date: DateTime.now(), duration: duration, distanceKm: distanceKm);
  }

  bool _canSave(CardioActivity activity) {
    final minutes = int.tryParse(_minutes.text) ?? 0;
    final seconds = int.tryParse(_seconds.text) ?? 0;
    if (minutes * 60 + seconds <= 0) return false;
    if (activity.supportsDistance && (_number(_distance.text) ?? 0) <= 0) return false;
    return true;
  }

  Future<void> _save(AppController app, CardioActivity activity) async {
    final duration = Duration(
      minutes: int.tryParse(_minutes.text) ?? 0,
      seconds: int.tryParse(_seconds.text) ?? 0,
    );
    final achievement = app.addCardioRecord(
      activity,
      CardioRecord(
        date: DateTime.now(),
        duration: duration,
        distanceKm: activity.supportsDistance ? _distanceInKm(_distance.text, app.distanceUnit) : null,
        heartRateBpm: _int(_heartRate.text),
        calories: _int(_calories.text),
        inclinePercent: activity.supportsIncline ? _number(_incline.text) : null,
        resistanceLevel: activity.supportsResistance ? _number(_resistance.text) : null,
        notes: _notes.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _distance.clear(); _minutes.clear(); _seconds.clear(); _heartRate.clear(); _calories.clear();
      _incline.clear(); _resistance.clear(); _notes.clear();
    });
    if (achievement != null) {
      await showCardioRecordAchievementSheet(
        context: context,
        activity: activity,
        achievement: achievement,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.strings.t('Cardio registrado.', 'Cardio logged.', 'Cardio registrado.'))),
      );
    }
  }

  double? _distanceInKm(String value, String distanceUnit) {
    final raw = _number(value);
    if (raw == null) return null;
    return distanceUnit == 'mi' ? raw * 1.609344 : raw;
  }

  double _activityPace(CardioRecord record, CardioActivity activity, String distanceUnit) {
    final distanceKm = record.distanceKm ?? 0;
    if (distanceKm <= 0) return 0;
    final paceDistanceKm = activity.paceDistanceKm == 0.5
        ? 0.5
        : (distanceUnit == 'mi' ? 1.609344 : 1.0);
    return (record.duration.inSeconds / 60) / (distanceKm / paceDistanceKm);
  }

  String _formatPace(double minutes, CardioActivity activity, String distanceUnit) {
    final whole = minutes.floor();
    final seconds = ((minutes - whole) * 60).round().clamp(0, 59);
    final unit = activity.paceDistanceKm == 0.5 ? '/500m' : (distanceUnit == 'mi' ? '/mi' : '/km');
    return '$whole:${seconds.toString().padLeft(2, '0')} $unit';
  }

  String _speedLabel(double kmh, String distanceUnit) {
    if (distanceUnit == 'mi') return '${(kmh / 1.609344).toStringAsFixed(1)} mph';
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  String _recordSummary(CardioRecord record) {
    final min = record.duration.inMinutes;
    final sec = record.duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final distanceKm = record.distanceKm;
    if (distanceKm == null) return '$min:$sec';
    final unit = AppScope.of(context).distanceUnit;
    final distance = unit == 'mi' ? distanceKm / 1.609344 : distanceKm;
    return '${distance.toStringAsFixed(2)} $unit • $min:$sec';
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.activity});
  final CardioActivity activity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Stack(
        children: [
          CardioVisualPager(
            activity: activity,
            width: double.infinity,
            height: 230,
            fit: BoxFit.cover,
            showLabel: true,
          ),

        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.mutedSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.deepBlue)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.electricLime)),
        ]),
      );
}

class _PersonalBests extends StatelessWidget {
  const _PersonalBests({required this.activity});
  final CardioActivity activity;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final bestPace = _bestPace(activity, app.distanceUnit);
    final longest = activity.longestDuration;
    final longestDistance = app.distanceUnit == 'mi' ? activity.longestDistanceKm / 1.609344 : activity.longestDistanceKm;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.strings.bestMarks, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _Metric(label: context.strings.longestDistance, value: activity.longestDistanceKm == 0 ? '—' : '${longestDistance.toStringAsFixed(2)} ${app.distanceUnit}')),
            const SizedBox(width: 10),
            Expanded(child: _Metric(label: context.strings.bestPace, value: bestPace == null ? '—' : _pace(bestPace, activity, app.distanceUnit))),
          ]),
          const SizedBox(height: 10),
          _Metric(label: context.strings.longestDuration, value: longest == Duration.zero ? '—' : '${longest.inMinutes}:${longest.inSeconds.remainder(60).toString().padLeft(2, '0')}'),
        ],
      ),
    );
  }

  static double? _bestPace(CardioActivity activity, String distanceUnit) {
    if (!activity.supportsPace) return null;
    final targetDistanceKm = activity.paceDistanceKm == 0.5 ? 0.5 : (distanceUnit == 'mi' ? 1.609344 : 1.0);
    final values = activity.records.map((record) {
      final distance = record.distanceKm;
      if (distance == null || distance <= 0) return null;
      return (record.duration.inSeconds / 60) / (distance / targetDistanceKm);
    }).whereType<double>().toList()..sort();
    return values.isEmpty ? null : values.first;
  }

  static String _pace(double minutes, CardioActivity activity, String distanceUnit) {
    final whole = minutes.floor();
    final seconds = ((minutes - whole) * 60).round().clamp(0, 59);
    final unit = activity.paceDistanceKm == 0.5 ? '/500m' : (distanceUnit == 'mi' ? '/mi' : '/km');
    return '$whole:${seconds.toString().padLeft(2, '0')} $unit';
  }
}


IconData _cardioIcon(CardioKind kind) => switch (kind) {
  CardioKind.outdoorRun => Icons.directions_run_rounded,
  CardioKind.treadmill => Icons.directions_run_rounded,
  CardioKind.walk => Icons.directions_walk_rounded,
  CardioKind.cycling => Icons.directions_bike_rounded,
  CardioKind.stationaryBike => Icons.pedal_bike_rounded,
  CardioKind.elliptical => Icons.fitness_center_rounded,
  CardioKind.stairClimber => Icons.stairs_rounded,
  CardioKind.rowing => Icons.rowing_rounded,
  CardioKind.jumpRope => Icons.timer_outlined,
};
