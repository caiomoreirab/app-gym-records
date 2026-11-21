import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/theme/app_theme.dart';
import 'package:gymrecords/widgets/adaptive_illustration.dart';
import 'package:gymrecords/widgets/machine_list_card.dart';

void main() {
  testWidgets('miniatura sempre mostra execução inteira sem carrossel',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final app = AppController(persistenceEnabled: false);
    addTearDown(app.dispose);
    final exercise = buildExerciseCatalog().firstWhere((m) => m.id == 'crunch');
    await tester.pumpWidget(AppScope(
      controller: app,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: MachineListCard(machine: exercise, unit: 'kg', onTap: () {}),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseVisualPager), findsNothing);
    final thumb = tester.widget<AdaptiveExerciseImage>(
        find.byType(AdaptiveExerciseImage));
    expect(thumb.fit, BoxFit.contain);
    expect(thumb.width, 84);
    expect(thumb.height, 62);
    expect(tester.takeException(), isNull);
  });

  testWidgets('prancha não exibe o arquivo com outro movimento',
      (tester) async {
    final app = AppController(persistenceEnabled: false);
    addTearDown(app.dispose);
    final exercise = buildExerciseCatalog().firstWhere((m) => m.id == 'plank');
    await tester.pumpWidget(AppScope(
      controller: app,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: AdaptiveExerciseImage(
              machine: exercise, width: 84, height: 62),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.fitness_center_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
