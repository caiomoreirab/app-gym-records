import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Original inline SVG line-art for GymRecords, with theme-controlled color.
/// These paths are vector assets, not emojis or raster icon screenshots.
enum WorkoutGlyph { trophy, clock, flame, dumbbell, sets, volume, check, calendar }

class WorkoutSvgIcon extends StatelessWidget {
  const WorkoutSvgIcon(this.glyph, {
    super.key,
    this.size = 24,
    this.color = AppTheme.electricLime,
    this.semanticsLabel,
  });

  final WorkoutGlyph glyph;
  final double size;
  final Color color;
  final String? semanticsLabel;

  static String svgMarkup(WorkoutGlyph glyph) {
    final paths = switch (glyph) {
      WorkoutGlyph.trophy =>
        '<path d="M16 10h32v20c0 12-6.7 19-16 19s-16-7-16-19V10Z"/>'
        '<path d="M16 16H7v8c0 8 5 13 11 13M48 16h9v8c0 8-5 13-11 13"/>'
        '<path d="M32 49v7m-11 0h22M25 61h14"/>'
        '<path d="m32 19 2.6 5.4 6 .9-4.3 4.2 1 6-5.3-2.8-5.3 2.8 1-6-4.3-4.2 6-.9Z"/>',
      WorkoutGlyph.clock =>
        '<circle cx="32" cy="32" r="24"/>'
        '<path d="M32 17v16l11 7"/>',
      WorkoutGlyph.flame =>
        '<path d="M32 58c-13 0-21-9-21-21 0-8 4-15 10-21-1 8 3 11 5 12C27 16 33 10 37 5c1 11 6 15 11 21 4 5 5 10 5 16 0 9-8 16-21 16Z"/>'
        '<path d="M32 56c-7 0-11-5-11-11 0-5 3-9 8-14 0 6 4 7 6 8 0-5 3-8 5-11 1 7 5 10 5 16 0 7-5 12-13 12Z"/>',
      WorkoutGlyph.dumbbell =>
        '<path d="M20 22 44 46M15 14 8 21l15 15 7-7-15-15ZM41 38l15 15-7 7-15-15 7-7Z"/>'
        '<path d="m11 25-5 5m28 23-5 5"/>',
      WorkoutGlyph.sets =>
        '<rect x="14" y="8" width="36" height="12" rx="5"/>'
        '<rect x="14" y="26" width="36" height="12" rx="5"/>'
        '<rect x="14" y="44" width="36" height="12" rx="5"/>',
      WorkoutGlyph.volume =>
        '<path d="M12 52V33m13 19V22m13 30V12m13 40V28"/>'
        '<path d="M7 56h49"/>',
      WorkoutGlyph.check =>
        '<circle cx="32" cy="32" r="24"/>'
        '<path d="m20 32 8 8 17-18"/>',
      WorkoutGlyph.calendar =>
        '<rect x="10" y="14" width="44" height="40" rx="7"/>'
        '<path d="M10 26h44M23 8v12M42 8v12M22 37h7M35 37h7M22 45h7"/>',
    };
    return '<svg xmlns="http://www.w3.org/2000/svg" '
        'viewBox="0 0 64 64" width="64" height="64" fill="none" '
        'stroke="#10B7F4" stroke-width="3.4" '
        'stroke-linecap="round" stroke-linejoin="round">$paths</svg>';
  }

  @override
  Widget build(BuildContext context) => SvgPicture.string(
    svgMarkup(glyph),
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    semanticsLabel: semanticsLabel,
  );
}
