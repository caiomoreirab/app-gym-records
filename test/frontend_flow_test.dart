import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/app.dart';
import 'package:gymrecords/screens/onboarding/illustration_style_screen.dart';
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
    // The TextEditingController listener enables the button on the next frame.
    await tester.pumpAndSettle();
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar →'));
    await tester.pumpAndSettle();

    // Verify navigation and persisted name without depending on Text.rich matching.
    expect(controller.displayName, 'Caio');
    expect(find.byType(IllustrationStyleScreen), findsOneWidget);
    // The appearance cards live in a lazily built ListView. On compact
    // test screens the feminine choice may start outside the viewport.
    await tester.drag(find.byType(ListView).last, const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('style_feminine')), findsOneWidget);
    await tester.tap(find.byKey(const Key('style_feminine')));
    // The selection rebuilds the bottom navigation button on the next frame.
    await tester.pumpAndSettle();
    final continueButton = find.widgetWithText(FilledButton, 'Continuar →');
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(controller.displayName, 'Caio');
    expect(controller.illustrationStyle, IllustrationStyle.feminine);
    expect(controller.onboardingComplete, isTrue);
    expect(find.text('Caio'), findsOneWidget);
    expect(find.text('Registre sua execução'), findsOneWidget);
    expect(find.byKey(const Key('globalExerciseSearch')), findsOneWidget);
    // The Pro card may be outside the visible viewport on compact testers.
    // The search field and welcome copy confirm that Home is mounted.
    expect(find.byType(IllustrationStyleScreen), findsNothing);
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
