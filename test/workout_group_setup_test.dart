import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/models/cardio_record.dart';
import 'package:gymrecords/screens/home_screen.dart';
import 'package:gymrecords/screens/workout_group_selection_screen.dart';
import 'package:gymrecords/screens/workout_exercise_selection_screen.dart';
import 'package:gymrecords/screens/workout_live_screen.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/services/local_data_store.dart';
import 'package:gymrecords/theme/app_theme.dart';
import 'package:gymrecords/widgets/machine_list_card.dart';

void main() {
  test('groups and cardio plan survive backup and a reopened local store', () async {
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    addTearDown(app.dispose);
    await app.loadPreferences();
    await app.importBackup(
      '{"schemaVersion":2,"machines":[],"cardio":{},'
      '"sessions":[],"favorites":[],"activeSessionId":null}');
    final cardioId = app.cardioActivities.first.id;
    final session = app.startSession(
      selectedGroupIds: ['chest', 'triceps', 'cardio'],
      plannedCardioIds: [cardioId]);
    final machine = app.ensureMachineAdded(buildExerciseCatalog()
      .firstWhere((m) => m.id == 'barbell_bench_press'));
    app.addExerciseToSession(machine);
    app.addRecord(machine, weight: 40, repetitions: 8);
    app.addCardioRecord(app.cardioActivities.first, CardioRecord(
      sessionId: session.id, date: DateTime.now(),
      duration: const Duration(minutes: 15), distanceKm: 2.5,
    ));
    final count = app.recordsForSession(session.id).length;
    app.setActiveSessionGroups(['legs', 'cardio']);
    expect(app.activeSession!.exerciseIds, [machine.id]);
    expect(app.recordsForSession(session.id).length, count);
    final backup = jsonDecode(app.exportBackup()) as Map<String, dynamic>;
    final savedSession = (backup['sessions'] as List).single;
    expect(savedSession['selectedGroupIds'], ['legs', 'cardio']);
    expect(savedSession['plannedCardioIds'], [cardioId]);
    expect((backup['cardio'] as Map)[cardioId].single['sessionId'], session.id);
    await app.flushPendingWrites();
    final reopened = AppController(persistenceEnabled: false, store: store);
    await reopened.loadPreferences();
    expect(reopened.activeSession!.selectedGroupIds, ['legs', 'cardio']);
    expect(reopened.activeSession!.plannedCardioIds, [cardioId]);
    expect(reopened.recordsForSession(session.id).length, 1);
    expect(reopened.cardioActivities.first.records.single.sessionId, session.id);
    reopened.dispose();
  });

  test('old backups have no chosen groups; invalid ones are rejected', () async {
    final app = AppController(persistenceEnabled: false);
    addTearDown(app.dispose);
    final session = app.startSession();
    final json = jsonDecode(app.exportBackup()) as Map<String, dynamic>;
    final s = (json['sessions'] as List).single as Map<String, dynamic>;
    s.remove('selectedGroupIds');
    s.remove('plannedCardioIds');
    await app.importBackup(jsonEncode(json));
    expect(app.activeSession!.selectedGroupIds, isEmpty);
    expect(app.activeSession!.plannedCardioIds, isEmpty);
    s['selectedGroupIds'] = ['invalid_group'];
    await expectLater(app.importBackup(jsonEncode(json)), throwsFormatException);
    expect(app.activeSession!.id, session.id);
    expect(app.activeSession!.selectedGroupIds, isEmpty);
  });

  testWidgets('pode pular grupos e escolher exercício depois', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final app = AppController(persistenceEnabled: false);
    addTearDown(app.dispose);
    await app.importBackup('{"schemaVersion":2,"machines":[],"cardio":{},'
      '"sessions":[],"favorites":[],"activeSessionId":null}');
    await tester.pumpWidget(AppScope(controller: app,
      child: MaterialApp(theme: AppTheme.dark, home: const HomeScreen())));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('start_workout_session')), 120,
      scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('start_workout_session')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutGroupSelectionScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('workout_groups_skip')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutExerciseSelectionScreen), findsOneWidget);
    expect(find.byType(MachineListCard), findsWidgets);
    await tester.tap(find.byKey(const Key('workout_exercises_finish')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutLiveScreen), findsOneWidget);
    expect(app.activeSession!.selectedGroupIds, isEmpty);
    expect(app.activeSession!.exerciseIds, isEmpty);
    await tester.scrollUntilVisible(find.byKey(const Key('live_edit_groups')),
      100, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('live_edit_groups')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutGroupSelectionScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('workout_group_chest')));
    await tester.tap(find.byKey(const Key('workout_groups_continue')));
    await tester.pumpAndSettle();
    expect(app.activeSession!.selectedGroupIds, ['chest']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('seleção de vários grupos mostra o catálogo filtrado',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final app = AppController(persistenceEnabled: false);
    addTearDown(app.dispose);
    await tester.pumpWidget(AppScope(controller: app,
      child: MaterialApp(theme: AppTheme.dark,
        home: const WorkoutGroupSelectionScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('workout_group_chest')));
    await tester.tap(find.byKey(const Key('workout_group_back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('workout_groups_continue')));
    await tester.pumpAndSettle();
    final count = tester.widget<ListView>(
      find.byKey(const Key('workout_exercises_list')))
      .childrenDelegate.estimatedChildCount;
    final wanted = app.availableMachines.where((m) =>
      m.group.name == 'chest' || m.group.name == 'back').length;
    expect(count, wanted);
    await tester.tap(find.byKey(const Key('workout_exercises_filter_all')));
    await tester.pumpAndSettle();
    final all = tester.widget<ListView>(
      find.byKey(const Key('workout_exercises_list')))
      .childrenDelegate.estimatedChildCount;
    expect(all, app.availableMachines.length + 1 + app.cardioActivities.length);
    expect(tester.takeException(), isNull);
  });
  test('invalid strength input does not add phantom planned exercises', () {
    final app = AppController(persistenceEnabled: false);
    addTearDown(app.dispose);
    app.startSession(selectedGroupIds: ['chest']);
    final machine = app.ensureMachineAdded(buildExerciseCatalog()
      .firstWhere((m) => m.id == 'barbell_bench_press'));
    expect(app.activeSession!.exerciseIds, isEmpty);
    expect(() => app.addRecord(machine, weight: -1, repetitions: 8),
      throwsFormatException);
    expect(() => app.addRecord(machine, weight: 10, repetitions: -3),
      throwsFormatException);
    expect(app.activeSession!.exerciseIds, isEmpty);
    expect(app.activeSession!.selectedGroupIds, ['chest']);
    expect(app.activeSession!.progress, 0);
  });

}
