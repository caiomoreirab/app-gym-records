import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gymrecords/theme/app_theme.dart';

double _linear(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) => 0.2126 * _linear(c.r) +
    0.7152 * _linear(c.g) + 0.0722 * _linear(c.b);

double _contrast(Color a, Color b) {
  final aa = _luminance(a), bb = _luminance(b);
  return (math.max(aa, bb) + 0.05) / (math.min(aa, bb) + 0.05);
}

void main() {
  test('cores do tema oficial alcançam contraste WCAG AA para texto', () {
    expect(_contrast(AppTheme.polarWhite, AppTheme.deepNavy),
        greaterThanOrEqualTo(4.5));
    expect(_contrast(AppTheme.iceBlue, AppTheme.surfaceNavy),
        greaterThanOrEqualTo(4.5));
    expect(_contrast(AppTheme.electricLime, AppTheme.surfaceNavy),
        greaterThanOrEqualTo(4.5));
    expect(_contrast(AppTheme.deepNavy, AppTheme.electricLime),
        greaterThanOrEqualTo(4.5));
  });
}
