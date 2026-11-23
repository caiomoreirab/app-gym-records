import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gymrecords/screens/main_tabs_shell.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/theme/app_theme.dart';

void main() {
  testWidgets('trocar de aba mantém as buscas das telas montadas', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final app = AppController(persistenceEnabled: false);
    addTearDown(app.dispose);
    await tester.pumpWidget(AppScope(controller: app, child:
      MaterialApp(theme: AppTheme.dark, home: const MainTabsShell())));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('globalExerciseSearch')), 'agachamento');
    await tester.tap(find.byKey(const Key('main_nav_1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('catalog_search')), 'supino');
    await tester.tap(find.byKey(const Key('main_nav_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('main_nav_1')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const Key('catalog_search')))
      .controller?.text, 'supino');

    await tester.tap(find.byKey(const Key('main_nav_0')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const Key('globalExerciseSearch')))
      .controller?.text, 'agachamento');
    expect(tester.takeException(), isNull);
  });
}
