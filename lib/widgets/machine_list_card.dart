import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/machine.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'adaptive_illustration.dart';

class MachineListCard extends StatelessWidget {
  const MachineListCard({super.key, required this.machine, required this.unit, required this.onTap});

  final Machine machine;
  final String unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latest = machine.latestRecord;
    return Material(
      color: AppTheme.surfaceNavy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius), side: const BorderSide(color: AppTheme.deepBlue)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ExerciseVisualPager(machine: machine, width: 82, height: 82, fit: BoxFit.cover, compact: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(machine.localizedName(Localizations.localeOf(context)), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 7),
                  Text(
                    latest == null ? context.strings.t('Ainda sem registros', 'No records yet', 'Aún sin registros') : '${context.strings.updatedOn} ${formatShortDate(latest.date, Localizations.localeOf(context))}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              Text(_summary(context), style: TextStyle(color: _hasAnyRecord ? AppTheme.electricLime : AppTheme.iceBlue, fontSize: _hasAnyRecord ? 24 : 13, fontWeight: _hasAnyRecord ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasAnyRecord => machine.recordWeight > 0 || machine.bestRepetitions > 0 || machine.bestDurationSeconds > 0;

  String _summary(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (machine.recordWeight > 0) return '${formatWeight(machine.recordWeight, locale)} $unit';
    if (machine.bestRepetitions > 0) return '${machine.bestRepetitions} reps';
    if (machine.bestDurationSeconds > 0) {
      final seconds = machine.bestDurationSeconds % 60;
      final minutes = machine.bestDurationSeconds ~/ 60;
      return minutes > 0 ? '${minutes}m ${seconds.toString().padLeft(2, '0')}s' : '${seconds}s';
    }
    return context.strings.noRecords;
  }
}
