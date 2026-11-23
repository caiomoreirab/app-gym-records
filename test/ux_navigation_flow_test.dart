import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/screens/exercise_catalog_screen.dart';
import 'package:gymrecords/screens/machine_screen.dart';
import 'package:gymrecords/screens/reports_hub_screen.dart';
import 'package:gymrecords/screens/workout_completed_screen.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/theme/app_theme.dart';
import 'package:gymrecords/widgets/machine_list_card.dart';

void main() {
  test('contraste do texto no azul atende WCAG AA', () {
    final style = AppTheme.dark.filledButtonTheme.style!;
    final foreground = style.foregroundColor!.resolve({})!;
    final background = style.backgroundColor!.resolve({})!;
    final bright = foreground.computeLuminance();
    final dark = background.computeLuminance();
    final ratio = (1.05 + (bright > dark ? bright : dark)) /
      (0.05 + (bright < dark ? bright : dark));
    expect(ratio, greaterThanOrEqualTo(4.5));
  });

  testWidgets('consultar catálogo não inclui item sem intenção de adicionar',
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
    final machine = app.ensureMachineAdded(buildExerciseCatalog().first);
    final session = app.startSession();
    expect(app.activeSession!.exerciseIds, isEmpty);

    await tester.pumpWidget(AppScope(controller: app,
      child: MaterialApp(theme: AppTheme.dark,
        home: const ExerciseCatalogScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MachineListCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(MachineScreen), findsOneWidget);
    expect(app.activeSession!.id, session.id);
    expect(app.activeSession!.exerciseIds, isEmpty);
    expect(app.machineById(machine.id), isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('histórico abre resumo do treino concluído', (tester) async {
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
    final machine = app.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((m) => m.id == 'barbell_squat'));
    final session = app.startSession(name: 'Treino de teste');
    app.addExerciseToSession(machine);
    app.addRecord(machine, weight: 70, repetitions: 8);
    app.completeSession();

    await tester.pumpWidget(AppScope(controller: app,
      child: MaterialApp(theme: AppTheme.dark,
        home: const ReportsHubScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Histórico de treinos'), findsOneWidget);
    await tester.tap(find.text('Treino de teste'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutCompletedScreen), findsOneWidget);
    expect(find.text('Exercícios realizados'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(app.recordsForSession(session.id).length, 1);
  });
}
