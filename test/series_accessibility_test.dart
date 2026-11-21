import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/screens/machine_screen.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/theme/app_theme.dart';

void main() {
  testWidgets('registro de série cabe em tela de 320 px com texto ampliado',
      (tester) async {
    tester.view.physicalSize = const Size(320, 780);
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
      buildExerciseCatalog().firstWhere((m) => m.id == 'barbell_bench_press'));
    await tester.pumpWidget(AppScope(
      controller: app,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.25)),
          child: child!,
        ),
        home: MachineScreen(machineId: machine.id),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The classic detail screen has a tall illustration and record section.
    // Scroll to the set controls before asserting visible content.
    await tester.drag(find.byType(ListView).first, const Offset(0, -470));
    await tester.pumpAndSettle();
    expect(find.text('Repetições'), findsOneWidget);
    expect(find.byKey(const Key('repeat_last_set')), findsOneWidget);
    expect(find.text('Séries e histórico por sessão'), findsOneWidget);
    await tester.tap(find.byKey(const Key('favorite_exercise')));
    await tester.pumpAndSettle();
    expect(app.isFavorite(machine.id), isTrue);
    expect(tester.takeException(), isNull);
  });
}
