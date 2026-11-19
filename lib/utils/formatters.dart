import 'dart:ui';

String formatWeight(double value, [Locale? locale]) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  final formatted = value.toStringAsFixed(1);
  return locale?.languageCode == 'en' ? formatted : formatted.replaceAll('.', ',');
}

String formatShortDate(DateTime date, [Locale? locale]) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return locale?.languageCode == 'en' ? '$month/$day' : '$day/$month';
}

String formatFullDate(DateTime date, [Locale? locale]) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return locale?.languageCode == 'en'
      ? '$month/$day/${date.year}'
      : '$day/$month/${date.year}';
}
