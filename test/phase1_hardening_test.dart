import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/models/user_profile.dart';
import 'package:gymrecords/services/illustration_assets.dart';
import 'package:gymrecords/services/strength_set_validation.dart';
import 'package:gymrecords/services/weight_units.dart';
import 'package:gymrecords/services/local_data_store.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/widgets/adaptive_illustration.dart';
import 'package:gymrecords/widgets/unverified_exercise_illustration.dart';
import 'package:gymrecords/theme/app_theme.dart';

void main() {
  final catalog = buildExerciseCatalog();
  final barbell = catalog.firstWhere((m) => m.id == 'barbell_bench_press');
  final dumbbell = catalog.firstWhere((m) => m.id == 'dumbbell_bench_press');
  final machine = catalog.firstWhere((m) => m.id == 'chest_press_machine');
  final pushup = catalog.firstWhere((m) => m.id == 'push_up');

  test('não mostra máquina de supino no supino com barra ou halteres', () {
    expect(IllustrationAssets.hasVerifiedExecution(barbell), isFalse);
    expect(IllustrationAssets.hasVerifiedExecution(dumbbell), isFalse);
    expect(IllustrationAssets.hasVerifiedExecution(machine), isTrue);
    for (final style in IllustrationStyle.values) {
      expect(IllustrationAssets.exercise(machine, style),
        contains('chest_0.webp'));
      expect(IllustrationAssets.group(barbell.group, style),
        contains(style.assetFolder));
    }
  });

  test('validação separa carga externa, peso corporal e valores inválidos', () {
    expect(StrengthSetValidation.error(machine: barbell, weight: 0,
      repetitions: 8, durationSeconds: null), contains('carga'));
    expect(StrengthSetValidation.error(machine: barbell, weight: 40,
      repetitions: 0, durationSeconds: null), contains('repetições'));
    expect(StrengthSetValidation.error(machine: barbell, weight: -1,
      repetitions: 8, durationSeconds: null), isNotNull);
    expect(StrengthSetValidation.error(machine: barbell, weight: 40,
      repetitions: 8, durationSeconds: null), isNull);
    expect(StrengthSetValidation.error(machine: pushup, weight: 0,
      repetitions: 12, durationSeconds: null), isNull);
    expect(StrengthSetValidation.error(machine: pushup, weight: 0,
      repetitions: null, durationSeconds: null), isNotNull);
  });

  test('converter lb não altera o peso físico nem o backup', () async {
    expect(WeightUnits.toDisplay(100, 'lb'), closeTo(220.46226, 0.001));
    final kg = WeightUnits.toKilograms(WeightUnits.toDisplay(100, 'lb'),'lb');
    expect(kg, closeTo(100, 0.000001));
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    await app.importBackup('{"schemaVersion":2,"machines":[],'
      '"cardio":{},"sessions":[],"favorites":[],"activeSessionId":null}');
    final m = app.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((x) => x.id == barbell.id));
    app.addRecord(m, weight: 100, repetitions: 3);
    app.setUnit('lb');
    expect(m.records.single.weight, closeTo(100, 0.000001));
    expect((jsonDecode(app.exportBackup())['machines'] as List)
      .single['records'].single['weight'], closeTo(100, 0.000001));
    app.dispose();
  });

  test('backup v2 volta com séries e nunca perde registros após JSON inválido',
      () async {
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    await app.importBackup('{"schemaVersion":2,"machines":[],'
      '"cardio":{},"sessions":[],"favorites":[],"activeSessionId":null}');
    final m = app.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((x) => x.id == barbell.id));
    app.addRecord(m, weight: 80, repetitions: 12);
    app.completeSession();
    final goodBackup = app.exportBackup();
    final initialCount = m.records.length;
    await expectLater(app.importBackup(''), throwsFormatException);
    await expectLater(app.importBackup('{bad json}'), throwsFormatException);
    final incompatible = jsonDecode(goodBackup);
    incompatible['schemaVersion'] = 999;
    await expectLater(app.importBackup(jsonEncode(incompatible)),
      throwsFormatException);
    expect(m.records.length, initialCount);
    await app.importBackup(goodBackup);
    expect(app.machineById(barbell.id).records.single.weight, 80);
    expect(app.sessions, isNotEmpty);
    app.dispose();
  });

  testWidgets('vetores neutros para exercícios não verificados nos três perfis',
      (tester) async {
    final app = AppController(persistenceEnabled: false);
    addTearDown(app.dispose);
    for (final style in IllustrationStyle.values) {
      app.setIllustrationStyle(style);
      await tester.pumpWidget(AppScope(controller: app,
        child: MaterialApp(theme: AppTheme.dark,
          locale: const Locale('pt', 'BR'),
          home: Scaffold(body: Center(child: SizedBox(
            width: 230, height: 180,
            child: AdaptiveExerciseImage(machine: barbell))))));
      await tester.pumpAndSettle();
      expect(find.byType(UnverifiedExerciseIllustration), findsOneWidget);
      expect(find.text('Barra'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
