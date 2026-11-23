import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/screens/workout_live_screen.dart';
import 'package:gymrecords/screens/workout_completed_screen.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/theme/app_theme.dart';

void main() {
  testWidgets('série rápida registra dados reais e finaliza treino validado',
      (tester) async {
    tester.view.physicalSize = const Size(375, 820);
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
    final machine = app.ensureMachineAdded(buildExerciseCatalog()
      .firstWhere((m) => m.id == 'barbell_squat'));
    final session = app.startSession();
    app.addExerciseToSession(machine);

    await tester.pumpWidget(AppScope(controller: app,
      child: MaterialApp(theme: AppTheme.dark,
        home: const WorkoutLiveScreen())));
    await tester.pumpAndSettle();
    expect(app.recordsForSession(session.id), isEmpty);
    await tester.scrollUntilVisible(
      find.byKey(const Key('live_repeat_barbell_squat')), 120,
      scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('live_repeat_barbell_squat')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('live_quick_weight')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('live_quick_weight')), '90');
    await tester.enterText(
      find.byKey(const Key('live_quick_repetitions')), '8');
    await tester.ensureVisible(
      find.byKey(const Key('live_save_quick_set')));
    await tester.tap(find.byKey(const Key('live_save_quick_set')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('live_rest_card')), findsOneWidget);
    expect(find.byKey(const Key('live_rest_skip')), findsOneWidget);
    final recorded = app.recordsForSession(session.id);
    expect(recorded.length, 1);
    expect(recorded.single.weight, 90);
    expect(recorded.single.repetitions, 8);
    expect(machine.recordWeight, 90);
    await tester.scrollUntilVisible(
      find.byKey(const Key('live_done_barbell_squat')), 120,
      scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('live_done_barbell_squat')));
    await tester.pumpAndSettle();
    expect(app.activeSession!.completedCount, 1);
    await tester.tap(find.byKey(const Key('live_finish_workout')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutCompletedScreen), findsOneWidget);
    expect(app.activeSession, isNull);
    expect(tester.takeException(), isNull);
  });
}
