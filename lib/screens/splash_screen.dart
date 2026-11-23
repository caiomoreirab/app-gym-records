import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'main_tabs_shell.dart';
import 'onboarding/name_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _textFade = CurvedAnimation(
      parent: _animation,
      curve: const Interval(.30, .82, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, .14), end: Offset.zero).animate(
      CurvedAnimation(parent: _animation, curve: const Interval(.30, .82, curve: Curves.easeOutCubic)),
    );
    _animation.forward();
    _timer = Timer(const Duration(milliseconds: 1750), _continue);
  }

  void _continue() {
    if (!mounted) return;
    final controller = AppScope.of(context);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => controller.onboardingComplete ? const MainTabsShell() : const NameScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.splashNavy,
      body: ColoredBox(
        color: AppTheme.splashNavy,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 228,
                  height: 228,
                  child: Image.asset(
                    'assets/branding/splash_intro.gif',
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: 'Gym', style: TextStyle(color: AppTheme.polarWhite)),
                              TextSpan(text: 'Records', style: TextStyle(color: AppTheme.electricLime)),
                            ],
                          ),
                          style: TextStyle(
                            fontFamily: 'Barlow',
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.strings.welcome,
                          style: const TextStyle(
                            color: AppTheme.polarWhite,
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
