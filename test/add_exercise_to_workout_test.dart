import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gymrecords/screens/home_screen.dart';
import 'package:gymrecords/screens/exercise_catalog_screen.dart';
import 'package:gymrecords/screens/machine_screen.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/widgets/machine_list_card.dart';
import 'package:gymrecords/theme/app_theme.dart';

void main() {
  testWidgets('iniciar, adicionar aparelho sem série e abrir registro',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final app = AppController(persistenceEnabled: false);
    addTearDown(app.dispose);
    await app.importBackup(
      '{"schemaVersion":2,"machines":[],"cardio":{},'
      '"sessions":[],"favorites":[],"activeSessionId":null}');
    await tester.pumpWidget(AppScope(controller: app,
      child: MaterialApp(theme: AppTheme.dark,
        home: const HomeScreen())));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('start_workout_session')), 150,
      scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('start_workout_session')));
    await tester.pumpAndSettle();
    expect(app.activeSession, isNotNull);
    expect(find.byKey(const Key('add_exercise_to_session')), findsOneWidget);

    await tester.tap(find.byKey(const Key('add_exercise_to_session')));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseCatalogScreen), findsOneWidget);
    expect(find.text('Escolha um aparelho'), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(MachineListCard).first, 120,
      scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byType(MachineListCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    final session = app.activeSession!;
    expect(session.exerciseIds.length, 1);
    expect(app.recordsForSession(session.id), isEmpty);
    expect(find.byKey(const Key('add_exercise_to_session')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
