import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class BlueConfettiOverlay extends StatelessWidget {
  const BlueConfettiOverlay({super.key, this.height = 150});

  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - value)),
              child: CustomPaint(
                painter: _BlueConfettiPainter(progress: value),
                size: Size(double.infinity, height),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlueConfettiPainter extends CustomPainter {
  _BlueConfettiPainter({required this.progress});

  final double progress;

  static const _palette = <Color>[
    AppTheme.accentBlue,
    AppTheme.deepBlue,
    AppTheme.iceBlue,
    Color(0xFF69D2FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    // Burst is anchored high above the record card; it never centres on the value.
    final centerY = size.height * 0.20;
    final pieces = <_ConfettiPiece>[
      _ConfettiPiece(-150, -20, 10, 4, 0.2, 0),
      _ConfettiPiece(-110, -32, 14, 5, -0.5, 1),
      _ConfettiPiece(-85, 8, 6, 6, 0.7, 2, circle: true),
      _ConfettiPiece(-55, -42, 8, 8, 0.3, 3, circle: true),
      _ConfettiPiece(-25, -14, 12, 5, -0.2, 0),
      _ConfettiPiece(15, -38, 10, 4, 0.6, 1),
      _ConfettiPiece(42, 2, 6, 6, -0.1, 2, circle: true),
      _ConfettiPiece(74, -28, 13, 5, 0.45, 3),
      _ConfettiPiece(104, -8, 8, 8, -0.4, 0, circle: true),
      _ConfettiPiece(135, -36, 12, 4, 0.9, 1),
      _ConfettiPiece(-130, 26, 10, 4, -0.8, 2),
      _ConfettiPiece(120, 22, 10, 4, 0.8, 3),
    ];

    for (final piece in pieces) {
      final paint = Paint()..color = _palette[piece.colorIndex].withValues(alpha: 0.95);
      final dx = centerX + piece.dx.clamp(-size.width * 0.46, size.width * 0.46).toDouble() * progress;
      final dy = centerY + piece.dy * progress;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(piece.rotation * math.pi * progress);
      if (piece.circle) {
        canvas.drawCircle(Offset.zero, piece.w / 2, paint);
      } else {
        final rrect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: piece.w, height: piece.h),
          const Radius.circular(2),
        );
        canvas.drawRRect(rrect, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BlueConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

class _ConfettiPiece {
  const _ConfettiPiece(this.dx, this.dy, this.w, this.h, this.rotation, this.colorIndex, {this.circle = false});

  final double dx;
  final double dy;
  final double w;
  final double h;
  final double rotation;
  final int colorIndex;
  final bool circle;
}
