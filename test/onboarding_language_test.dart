import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart' as localization;
import 'package:material_ui/material_ui.dart';
import 'package:gymrecords/screens/onboarding/name_screen.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/theme/app_theme.dart';

void main() {
  testWidgets('idioma e fonte acessíveis antes de completar onboarding',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final app = AppController(persistenceEnabled: false);
    addTearDown(app.dispose);
    await tester.pumpWidget(AppScope(controller: app,
      child: ListenableBuilder(
        listenable: app,
        builder: (context, _) => MaterialApp(
          theme: AppTheme.dark,
          supportedLocales: const [
            Locale('pt', 'BR'), Locale('en', 'US'), Locale('es', 'ES'),
          ],
          localizationsDelegates: const [
            localization.GlobalMaterialLocalizations.delegate,
            localization.GlobalWidgetsLocalizations.delegate,
            localization.GlobalCupertinoLocalizations.delegate,
          ],
          locale: app.appLocale,
          home: const NameScreen(),
        ),
      )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding_language')), findsOneWidget);
    expect(find.byKey(const Key('onboarding_large_text')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding_language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PT-BR').last);
    await tester.pumpAndSettle();
    expect(app.languageCode, 'pt');
    expect(find.text('Continuar →'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
