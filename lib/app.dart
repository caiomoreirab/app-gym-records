import 'package:material_ui/material_ui.dart';

import 'screens/splash_screen.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';

class GymRecordsScrollBehavior extends MaterialScrollBehavior {
  const GymRecordsScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();
}

class GymRecordsApp extends StatefulWidget {
  const GymRecordsApp({super.key, this.controller});

  final AppController? controller;

  @override
  State<GymRecordsApp> createState() => _GymRecordsAppState();
}

class _GymRecordsAppState extends State<GymRecordsApp> {
  late final AppController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? AppController();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => MaterialApp(
          title: 'GymRecords',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          locale: _controller.appLocale,
          supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US'), Locale('es', 'ES')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          scrollBehavior: const GymRecordsScrollBehavior(),
          builder: (context, child) {
            final original = MediaQuery.of(context);
            final multiplier = _controller.largeText ? 1.25 : 1.0;
            return MediaQuery(
              data: original.copyWith(textScaler: TextScaler.linear(
                original.textScaler.scale(1.0) * multiplier)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
