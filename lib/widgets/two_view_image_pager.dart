import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// A full-frame image alternator. Unlike PageView, a drag can never leave
/// two half-width images visible side-by-side while awaiting the next frame.
/// All paths are supplied by the active illustration profile only.
class TwoViewImagePager extends StatefulWidget {
  const TwoViewImagePager({
    super.key,
    required this.visualSetKey,
    required this.executionPath,
    required this.musclePath,
    required this.height,
    this.width,
    this.executionFallback,
    this.muscleFallback,
    this.compact = false,
    this.showLabel = false,
    this.fit = BoxFit.contain,
    this.executionIcon = Icons.fitness_center_rounded,
  });

  final String visualSetKey;
  final String executionPath;
  final String musclePath;
  final String? executionFallback;
  final String? muscleFallback;
  final double height;
  final double? width;
  final bool compact;
  final bool showLabel;
  final BoxFit fit;
  final IconData executionIcon;

  @override
  State<TwoViewImagePager> createState() => _TwoViewImagePagerState();
}

class _TwoViewImagePagerState extends State<TwoViewImagePager> {
  bool _muscles = false;
  double _dragDistance = 0;

  @override
  void didUpdateWidget(covariant TwoViewImagePager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visualSetKey != widget.visualSetKey) {
      _muscles = false;
    }
  }

  void _toggle() => setState(() => _muscles = !_muscles);

  void _onDragEnd(DragEndDetails details) {
    if (_dragDistance.abs() >= 28 || details.primaryVelocity != null && details.primaryVelocity!.abs() >= 240) {
      _toggle();
    }
    _dragDistance = 0;
  }

  @override
  Widget build(BuildContext context) {
    final path = _muscles ? widget.musclePath : widget.executionPath;
    final fallback = _muscles ? widget.muscleFallback : widget.executionFallback;
    final locale = Localizations.localeOf(context).languageCode;
    final label = _muscles
        ? (locale == 'en' ? 'Muscles' : 'Músculos')
        : (locale == 'en' ? 'Execution' : locale == 'es' ? 'Ejecución' : 'Execução');
    final radius = BorderRadius.circular(widget.compact ? 14 : AppTheme.radius);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: radius,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) => _dragDistance = 0,
          onHorizontalDragUpdate: (details) => _dragDistance += details.delta.dx,
          onHorizontalDragEnd: _onDragEnd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The image always occupies the ENTIRE card. No page offset.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 170),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeOut,
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [
                    ...previous,
                    if (current != null) current,
                  ],
                ),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: SizedBox.expand(
                  key: ValueKey('${widget.visualSetKey}|${_muscles ? 'muscles' : 'execution'}'),
                  child: _StrictProfileImage(
                    path: path,
                    fallback: fallback,
                    fit: widget.fit,
                  ),
                ),
              ),
              if (widget.showLabel)
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: GestureDetector(
                    onTap: _toggle,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xCC060B13),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_muscles ? Icons.accessibility_new_rounded : widget.executionIcon, color: AppTheme.electricLime, size: 15),
                          const SizedBox(width: 6),
                          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: widget.compact ? 6 : 12,
                bottom: widget.compact ? 6 : 10,
                child: GestureDetector(
                  onTap: _toggle,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: const Color(0xC907111B), borderRadius: BorderRadius.circular(99)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        _Dot(active: !_muscles, compact: widget.compact),
                        const SizedBox(width: 4),
                        _Dot(active: _muscles, compact: widget.compact),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active, required this.compact});
  final bool active;
  final bool compact;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: compact ? 6 : 7,
        height: compact ? 6 : 7,
        decoration: BoxDecoration(shape: BoxShape.circle, color: active ? AppTheme.electricLime : AppTheme.iceBlue.withValues(alpha: .50)),
      );
}

class _StrictProfileImage extends StatelessWidget {
  const _StrictProfileImage({required this.path, this.fallback, required this.fit});
  final String path;
  final String? fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget noAsset() => ColoredBox(
          color: const Color(0xFF0C1926),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.image_not_supported_outlined, color: AppTheme.iceBlue, size: 34),
              const SizedBox(height: 6),
              Text(
                Localizations.localeOf(context).languageCode == 'en' ? 'Illustration under review' : 'Ilustração em revisão',
                style: const TextStyle(color: AppTheme.iceBlue, fontSize: 11),
              ),
            ]),
          ),
        );
    return Image.asset(
      path,
      fit: fit,
      alignment: Alignment.center,
      gaplessPlayback: false,
      errorBuilder: (context, error, stack) {
        if (fallback == null || fallback == path) return noAsset();
        return Image.asset(fallback!, fit: fit, alignment: Alignment.center, errorBuilder: (context, error, stack) => noAsset());
      },
    );
  }
}
