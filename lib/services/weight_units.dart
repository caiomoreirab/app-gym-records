import 'dart:ui';

import '../utils/formatters.dart';

/// WorkoutRecord.weight is ALWAYS stored in kilograms. Switching the UI unit
/// only changes presentation and input conversion, never historical data.
abstract final class WeightUnits {
  static const double kgPerPound = 0.45359237;

  static double toDisplay(double kilograms, String unit) =>
      unit == 'lb' ? kilograms / kgPerPound : kilograms;

  static double toKilograms(double displayed, String unit) =>
      unit == 'lb' ? displayed * kgPerPound : displayed;

  static String format(double kilograms, String unit, [Locale? locale]) =>
      formatWeight(toDisplay(kilograms, unit), locale);

  static double volumeForDisplay(double volumeKg, String unit) =>
      toDisplay(volumeKg, unit);
}
