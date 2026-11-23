import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/machine.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../services/weight_units.dart';
import 'adaptive_illustration.dart';

class MachineListCard extends StatelessWidget {
  const MachineListCard({super.key, required this.machine, required this.unit,
    required this.onTap, this.selectable = false, this.selected = false});

  final Machine machine;
  final String unit;
  final VoidCallback onTap;
  final bool selectable;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final latest = machine.latestRecord;
    final compact = MediaQuery.sizeOf(context).width < 380;
    return Material(
      color: AppTheme.surfaceNavy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius),
        side: BorderSide(color: selected ? AppTheme.electricLime
          : AppTheme.deepBlue, width: selected ? 2 : 1)),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true, selected: selectable && selected,
        child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ExerciseVisualPager(machine: machine,
                width: compact ? 68 : 82,
                height: compact ? 68 : 82,
                fit: BoxFit.contain, compact: true),
              SizedBox(width: compact ? 10 : 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(machine.localizedName(Localizations.localeOf(context)), maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 7),
                  Text(
                    latest == null ? context.strings.t('Ainda sem registros', 'No records yet', 'Aún sin registros') : '${context.strings.updatedOn} ${formatShortDate(latest.date, Localizations.localeOf(context))}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ]),
              ),
              SizedBox(width: compact ? 8 : 10),
              if (selectable)
                Icon(selected ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppTheme.electricLime : AppTheme.iceBlue,
                  size: 28)
              else SizedBox(
                width: compact ? 70 : 93,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(_summary(context), maxLines: 1,
                    style: TextStyle(
                      color: _hasAnyRecord
                        ? AppTheme.electricLime : AppTheme.iceBlue,
                      fontSize: _hasAnyRecord ? 24 : 13,
                      fontWeight: _hasAnyRecord
                        ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ), // Semantics
      ),
    );
  }

  bool get _hasAnyRecord => machine.recordWeight > 0 || machine.bestRepetitions > 0 || machine.bestDurationSeconds > 0;

  String _summary(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (machine.recordWeight > 0) return '${WeightUnits.format(machine.recordWeight, unit, locale)} $unit';
    if (machine.bestRepetitions > 0) return '${machine.bestRepetitions} reps';
    if (machine.bestDurationSeconds > 0) {
      final seconds = machine.bestDurationSeconds % 60;
      final minutes = machine.bestDurationSeconds ~/ 60;
      return minutes > 0 ? '${minutes}m ${seconds.toString().padLeft(2, '0')}s' : '${seconds}s';
    }
    return context.strings.noRecords;
  }
}
