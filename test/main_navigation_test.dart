import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gymrecords/screens/exercise_catalog_screen.dart';
import 'package:gymrecords/screens/home_screen.dart';
import 'package:gymrecords/screens/reports_hub_screen.dart';
import 'package:gymrecords/screens/settings_screen.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/theme/app_theme.dart';

void main() {
  testWidgets('quatro abas acessiveis funcionam em 320px',
      (tester) async {
    tester.view.physicalSize = const Size(320, 750);
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
            textScaler: const TextScaler.linear(1.25)),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 4; i++) {
      final tab = find.byKey(Key('main_nav_$i'));
      expect(tab, findsOneWidget);
      expect(tester.getSize(tab).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(tab).height, greaterThanOrEqualTo(48));
    }
    await tester.tap(find.byKey(const Key('main_nav_1')));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseCatalogScreen), findsOneWidget);
    expect(find.byKey(const Key('catalog_search')), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'Catálogo 320px');
    await tester.tap(find.byKey(const Key('main_nav_2')));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsHubScreen), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'Relatórios 320px');
    await tester.tap(find.byKey(const Key('main_nav_3')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'Perfil 320px');
    await tester.tap(find.byKey(const Key('main_nav_0')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
