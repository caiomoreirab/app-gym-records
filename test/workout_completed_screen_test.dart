import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gymrecords/screens/workout_completed_screen.dart';
import 'package:gymrecords/screens/home_screen.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/theme/app_theme.dart';

void main() {
  testWidgets('celebracao e botao compartilhar aparecem em 320px',
      (tester) async {
    tester.view.physicalSize = const Size(320, 750);
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
    final session = app.startSession();
    app.completeSession(at: session.startedAt.add(
      const Duration(minutes: 45)));
    await tester.pumpWidget(AppScope(controller: app,
      child: MaterialApp(theme: AppTheme.dark, home:
        WorkoutCompletedScreen(sessionId: session.id))));
    await tester.pumpAndSettle();
    expect(find.text('Treino concluído!'), findsOneWidget);
    expect(find.text('Calorias estimadas: —'), findsOneWidget);
    expect(find.byType(SvgPicture), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const Key('share_completed_workout')), 200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('share_completed_workout')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('concluir treino da Home abre resumo real e encerra sessão',
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
    app.startSession(name: 'Treino A');
    await tester.pumpWidget(AppScope(controller: app,
      child: MaterialApp(theme: AppTheme.dark,
        home: const HomeScreen())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull,
      reason: 'Home antes de rolar até Concluir');
    await tester.scrollUntilVisible(find.byKey(const Key('finish_workout')), 200,
      scrollable: find.byType(Scrollable).first);
    expect(tester.takeException(), isNull,
      reason: 'Home depois da rolagem');
    await tester.tap(find.byKey(const Key('finish_workout')));
    await tester.pumpAndSettle();
    expect(app.activeSession, isNull);
    expect(find.byType(WorkoutCompletedScreen), findsOneWidget);
    expect(find.text('Treino concluído!'), findsOneWidget);
    final layoutError = tester.takeException();
    if (layoutError is FlutterError) {
      // Full diagnostics localize the exact overflowing Row in CI.
      // ignore: avoid_print
      print(layoutError.toStringDeep());
    }
    expect(layoutError, isNull, reason: 'Resumo apos finalizar treino');
  });
}
