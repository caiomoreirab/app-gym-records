import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/app.dart';
import 'package:gymrecords/models/user_profile.dart';
import 'package:gymrecords/state/app_controller.dart';

void main() {
  AppController testController() {
    final controller = AppController(persistenceEnabled: false);
    controller.setLanguageCode('pt');
    return controller;
  }

  testWidgets('abre no splash do GymRecords', (tester) async {
    await tester.pumpWidget(GymRecordsApp(controller: testController()));
    expect(find.text('Seja bem-vindo!'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('splash segue para a tela de nome', (tester) async {
    await tester.pumpWidget(GymRecordsApp(controller: testController()));
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();
    expect(find.text('Como você quer ser chamado?'), findsOneWidget);
    expect(find.byKey(const Key('displayNameField')), findsOneWidget);
  });

  testWidgets('nome e preferência concluem o onboarding', (tester) async {
    final controller = testController();
    await tester.pumpWidget(GymRecordsApp(controller: controller));
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('displayNameField')),
      '  Caio  ',
    );
    await tester.tap(find.text('Continuar →'));
    await tester.pumpAndSettle();

    // Verify navigation and persisted name without depending on Text.rich matching.
    expect(controller.displayName, 'Caio');
    expect(find.byKey(const Key('style_feminine')), findsOneWidget);
    await tester.tap(find.byKey(const Key('style_feminine')));
    await tester.tap(find.text('Continuar →'));
    await tester.pumpAndSettle();

    expect(controller.displayName, 'Caio');
    expect(controller.illustrationStyle, IllustrationStyle.feminine);
    expect(controller.onboardingComplete, isTrue);
    expect(find.text('Caio'), findsOneWidget);
    expect(find.text('Registre sua execução'), findsOneWidget);
    expect(find.byKey(const Key('globalExerciseSearch')), findsOneWidget);
    expect(find.text('GymRecords Pro'), findsOneWidget);
  });

  testWidgets('nome em branco não avança', (tester) async {
    await tester.pumpWidget(GymRecordsApp(controller: testController()));
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('displayNameField')), '   ');
    await tester.pump();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
