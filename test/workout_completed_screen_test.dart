import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/models/workout_session.dart';
import 'package:gymrecords/screens/workout_completed_screen.dart';
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
    expect(find.text('Treino concluído! 🏆'), findsOneWidget);
    expect(find.text('Calorias estimadas: —'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const Key('share_completed_workout')), 200,
      scrollable: find.descendant(
        of: find.byType(ListView).first, matching: find.byType(Scrollable)).first,
    );
    expect(find.byKey(const Key('share_completed_workout')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
