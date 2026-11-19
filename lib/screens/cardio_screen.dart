import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/cardio_activity.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_header.dart';
import '../widgets/cardio_visual_pager.dart';
import '../widgets/page_body.dart';
import 'cardio_activity_screen.dart';

class CardioScreen extends StatefulWidget {
  const CardioScreen({super.key});

  @override
  State<CardioScreen> createState() => _CardioScreenState();
}

class _CardioScreenState extends State<CardioScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final locale = Localizations.localeOf(context);
    final activities = app.cardioActivities.where((activity) {
      if (_query.trim().isEmpty) return true;
      return activity.localizedName(locale).toLowerCase().contains(_query.trim().toLowerCase());
    }).toList(growable: false);

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(context.strings.cardio),
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            const BrandHeader(compact: true),
            const SizedBox(height: 18),
            Text(
              context.strings.cardioActivities,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              context.strings.t(
                'Registre distância, tempo, pace e métricas específicas de cada atividade.',
                'Log distance, duration, pace and activity-specific metrics.',
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.iceBlue),
            ),
            const SizedBox(height: 18),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: context.strings.t('Buscar atividade...', 'Search activity...'),
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 18),
            for (var index = 0; index < activities.length; index++) ...[
              _CardioActivityCard(
                activity: activities[index],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CardioActivityScreen(activityId: activities[index].id),
                  ),
                ),
              ),
              if (index != activities.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardioActivityCard extends StatelessWidget {
  const _CardioActivityCard({required this.activity, required this.onTap});

  final CardioActivity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final latest = activity.latestRecord;
    final distanceUnit = AppScope.of(context).distanceUnit;
    return Material(
      color: AppTheme.surfaceNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: const BorderSide(color: AppTheme.deepBlue),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CardioVisualPager(
                activity: activity,
                width: 82,
                height: 82,
                fit: BoxFit.cover,
                compact: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.localizedName(locale), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 7),
                    Text(
                      latest == null
                          ? context.strings.noCardioYet
                          : _latestSummary(context, latest.duration, latest.distanceKm, distanceUnit),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _CardioMetric(activity: activity, distanceUnit: distanceUnit),
            ],
          ),
        ),
      ),
    );
  }

  String _latestSummary(BuildContext context, Duration duration, double? distanceKm, String distanceUnit) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final time = '$minutes:$seconds';
    if (distanceKm == null) return context.strings.t('Último: $time', 'Latest: $time');
    final distance = distanceUnit == 'mi' ? distanceKm / 1.609344 : distanceKm;
    final formatted = distance.toStringAsFixed(2);
    return context.strings.t(
      'Último: ${formatted.replaceAll('.', ',')} $distanceUnit • $time',
      'Latest: $formatted $distanceUnit • $time',
    );
  }
}

class _CardioMetric extends StatelessWidget {
  const _CardioMetric({required this.activity, required this.distanceUnit});

  final CardioActivity activity;
  final String distanceUnit;

  @override
  Widget build(BuildContext context) {
    final latest = activity.latestRecord;
    if (latest == null) {
      return const Icon(Icons.chevron_right_rounded, color: AppTheme.iceBlue);
    }
    if (latest.distanceKm != null && latest.distanceKm! > 0) {
      final distance = distanceUnit == 'mi' ? latest.distanceKm! / 1.609344 : latest.distanceKm!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            distance.toStringAsFixed(1).replaceAll('.', ','),
            style: const TextStyle(
              color: AppTheme.electricLime,
              fontSize: 27,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(distanceUnit, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
    }
    final minutes = latest.duration.inMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$minutes',
          style: const TextStyle(
            color: AppTheme.electricLime,
            fontSize: 27,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(context.strings.t('min', 'min'), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
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
