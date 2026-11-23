import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gymrecords/screens/home_screen.dart';
import 'package:gymrecords/screens/exercise_catalog_screen.dart';
import 'package:gymrecords/screens/workout_live_screen.dart';
import 'package:gymrecords/screens/workout_group_selection_screen.dart';
import 'package:gymrecords/screens/workout_exercise_selection_screen.dart';
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
    // Session is created only when setup is confirmed.
    expect(app.activeSession, isNull);
    expect(find.byType(WorkoutGroupSelectionScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('workout_group_chest')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('workout_groups_continue')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutExerciseSelectionScreen), findsOneWidget);
    expect(app.activeSession, isNull);
    await tester.tap(find.byType(MachineListCard).first);
    await tester.tap(find.byKey(const Key('workout_exercises_finish')));
    await tester.pumpAndSettle();
    expect(app.activeSession, isNotNull);
    expect(app.activeSession!.selectedGroupIds, ['chest']);
    expect(find.byType(WorkoutLiveScreen), findsOneWidget);
    expect(find.byKey(const Key('live_add_exercise')), findsOneWidget);

    await tester.tap(find.byKey(const Key('live_add_exercise')));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseCatalogScreen), findsOneWidget);
    expect(find.byKey(const Key('catalog_search')), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(MachineListCard).first, 120,
      scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byType(MachineListCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutLiveScreen), findsOneWidget);
    final session = app.activeSession!;
    expect(session.exerciseIds.length, 2);
    expect(app.recordsForSession(session.id), isEmpty);
    expect(find.byKey(const Key('live_add_exercise')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
