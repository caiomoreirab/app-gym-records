import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/models/workout_session.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/services/local_data_store.dart';
import 'package:gymrecords/services/workout_snapshot_codec.dart';
import 'package:gymrecords/screens/workout_live_screen.dart';
import 'package:gymrecords/theme/app_theme.dart';

void main() {
  test('progresso fica separado das séries e persiste após reabrir', () async {
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    await app.loadPreferences();
    final session = app.startSession(name: 'Treino A');
    final catalog = buildExerciseCatalog();
    final bench = app.ensureMachineAdded(catalog.firstWhere(
      (m) => m.id == 'barbell_bench_press'));
    final squat = app.ensureMachineAdded(catalog.firstWhere(
      (m) => m.id == 'barbell_squat'));
    app.addExerciseToSession(bench);
    app.addExerciseToSession(squat);
    expect(app.activeSession!.progress, 0);
    expect(app.activeSession!.pendingCount, 2);
    app.setExerciseCompleted(bench.id, true);
    expect(app.activeSession!.completedCount, 1);
    expect(app.activeSession!.progress, .5);
    expect(app.recordsForSession(session.id), isEmpty,
      reason: 'Marcar concluído não deve inventar séries.');
    app.addRecord(squat, weight: 70, repetitions: 8);
    app.setExerciseCompleted(squat.id, true);
    expect(app.activeSession!.progress, 1);
    app.setExerciseCompleted(bench.id, false);
    expect(app.activeSession!.progress, .5);
    await app.flushPendingWrites();
    final reopened = AppController(persistenceEnabled: false, store: store);
    await reopened.loadPreferences();
    expect(reopened.activeSession?.exerciseIds, [bench.id, squat.id]);
    expect(reopened.activeSession?.completedExerciseIds, [squat.id]);
    expect(reopened.recordsForSession(session.id).length, 1);
    reopened.dispose();
    app.dispose();
  });

  test('backup antigo migra sem marcar exercício concluído', () {
    final snapshot = WorkoutSnapshotCodec.encode(
      machines: [], cardioActivities: [], sessions: [
        WorkoutSession(id: 'legacy', startedAt: DateTime(2026, 11, 20),
          exerciseIds: const ['bench']),
      ]);
    (snapshot['sessions'] as List).first.remove('completedExerciseIds');
    final decoded = WorkoutSnapshotCodec.decode(snapshot);
    expect(decoded.sessions.single.completedExerciseIds, isEmpty);
    expect(decoded.sessions.single.progress, 0);
  });

  test('backup inconsistente é recusado sem alterar o histórico', () async {
    final app = AppController(persistenceEnabled: false);
    addTearDown(app.dispose);
    final session = app.startSession();
    final original = app.exportBackup();
    final invalid = jsonDecode(original) as Map<String, dynamic>;
    final sessions = invalid['sessions'] as List;
    (sessions.first as Map<String, dynamic>)['completedExerciseIds'] =
      ['exercise_not_in_workout'];
    await expectLater(app.importBackup(jsonEncode(invalid)),
      throwsFormatException);
    expect(app.activeSession?.id, session.id);
  });

  testWidgets('tela ativa mostra progresso sem séries fictícias em 320px',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
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
      .firstWhere((m) => m.id == 'barbell_bench_press'));
    final session = app.startSession();
    app.addExerciseToSession(machine);
    await tester.pumpWidget(AppScope(controller: app, child:
      MaterialApp(theme: AppTheme.dark, home: const WorkoutLiveScreen())));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('live_done_barbell_bench_press')), 100,
      scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(
      find.byKey(const Key('live_done_barbell_bench_press')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('live_done_barbell_bench_press')),
      findsOneWidget);
    await tester.tap(find.byKey(const Key('live_done_barbell_bench_press')));
    await tester.pumpAndSettle();
    expect(app.activeSession!.completedCount, 1);
    expect(app.recordsForSession(session.id), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
