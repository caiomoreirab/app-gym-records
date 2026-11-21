import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gymrecords/screens/review_experience.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/theme/app_theme.dart';
import 'package:gymrecords/widgets/adaptive_illustration.dart';

void main() {
  testWidgets('menu principal acessível e catálogo completo em 320px',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final app = AppController(persistenceEnabled: false);
    app.setDisplayName('Nome grande para testar layout');
    addTearDown(app.dispose);
    await tester.pumpWidget(AppScope(
      controller: app,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.3),
          ),
          child: child!,
        ),
        home: const ReviewHomeScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 5; i++) {
      final button = find.byKey(Key('primary_nav_$i'));
      expect(button, findsOneWidget);
      final size = tester.getSize(button);
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    }
    await tester.tap(find.byKey(const Key('primary_nav_1')));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewCatalogScreen), findsOneWidget);
    expect(find.byKey(const Key('catalog_search')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byKey(const Key('catalog_search')), 'peito');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    expect(find.byType(AdaptiveExerciseImage), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu permanece legível com fonte ampliada no histórico',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final app = AppController(persistenceEnabled: false);
    addTearDown(app.dispose);
    await tester.pumpWidget(AppScope(
      controller: app,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.6),
          ),
          child: child!,
        ),
        home: const ReviewHistoryScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('primary_nav_3')), findsOneWidget);
    expect(find.text('Histórico por sessão'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
