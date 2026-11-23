import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/models/muscle_group.dart';
import 'package:gymrecords/models/workout_record.dart';
import 'package:gymrecords/screens/pro_export_screen.dart';
import 'package:gymrecords/services/analytics_service.dart';
import 'package:gymrecords/services/illustration_assets.dart';
import 'package:gymrecords/services/local_data_store.dart';
import 'package:gymrecords/services/report_export_service.dart';
import 'package:gymrecords/services/strength_records.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/theme/app_theme.dart';
import 'package:gymrecords/widgets/unverified_exercise_illustration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exportação real filtra por grupo, período, datas e preserva séries', () async {
    final now = DateTime(2026, 11, 23, 16);
    final catalog = buildExerciseCatalog();
    final bench = catalog.firstWhere((m) => m.id == 'barbell_bench_press');
    final squat = catalog.firstWhere((m) => m.id == 'barbell_squat');
    bench.records.addAll([
      WorkoutRecord(id: 'chest1', sessionId: 'A',
        date: DateTime(2026, 11, 22, 12), weight: 100, repetitions: 3),
      WorkoutRecord(id: 'chest2', sessionId: 'A',
        date: DateTime(2026, 11, 22, 12, 5), weight: 90, repetitions: 8,
        note: 'Execução lenta'),
    ]);
    squat.records.add(WorkoutRecord(id: 'legs1', sessionId: 'B',
      date: DateTime(2026, 10, 10, 12), weight: 120, repetitions: 5));

    List<ReportEntry> select(AnalyticsPeriod period, MuscleGroup? group) =>
      ReportExportService.entries(
        machines: [bench, squat], cardioActivities: const [],
        period: period, now: now, group: group,
      );
    final all = select(AnalyticsPeriod.all, null);
    expect(all.length, 3);
    final chest = select(AnalyticsPeriod.all, MuscleGroup.chest);
    expect(chest.length, 2);
    expect(chest.every((x) => x.exercise == bench.name), isTrue);
    expect(chest.map((x) => x.setNumber).toSet(), {1, 2});
    final week = select(AnalyticsPeriod.week, null);
    expect(week.length, 2);
    expect(select(AnalyticsPeriod.week, MuscleGroup.legs), isEmpty);
    final csv = ReportExportService.toCsv(all);
    expect(csv, contains('"100.00","3"'));
    expect(csv, contains('"90.00","8"'));
    expect(csv, contains('"120.00","5"'));
    expect(csv, contains('Execução lenta'));
    expect(ReportExportService.toCsv(chest), isNot(contains('"120.00"')));
    final pdf = await ReportExportService.buildPdf(
      entries: all, title: 'GymRecords', subtitle: 'Histórico real');
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
    expect(pdf.length, greaterThan(700));
  });

  test('edição, remoção, desfazer e reabertura recalculam PR sem duplicar séries',
      () async {
    final store = MemoryLocalDataStore();
    final app = AppController(store: store, persistenceEnabled: false);
    await app.importBackup(
      '{"schemaVersion":2,"machines":[],"cardio":{},'
      '"sessions":[],"favorites":[],"activeSessionId":null}');
    final machine = app.ensureMachineAdded(buildExerciseCatalog()
      .firstWhere((m) => m.id == 'barbell_bench_press'));
    final a = app.addRecord(machine, weight: 80, repetitions: 8);
    final b = app.addRecord(machine, weight: 100, repetitions: 10);
    expect(StrengthRecords.maxWeight(machine.records), 100);
    app.replaceRecord(machine, b.copyWith(
      weight: 70, repetitions: 12, note: 'Corrigido'));
    expect(machine.records.length, 2);
    expect(machine.records.last.id, b.id);
    expect(StrengthRecords.maxWeight(machine.records), 80);
    expect(machine.records.last.note, 'Corrigido');
    final removed = app.removeRecord(machine, a.id);
    expect(StrengthRecords.maxWeight(machine.records), 70);
    app.restoreRecord(machine, removed);
    expect(StrengthRecords.maxWeight(machine.records), 80);
    await app.flushPendingWrites();
    final reopened = AppController(store: store, persistenceEnabled: false);
    await reopened.loadPreferences();
    final persisted = reopened.machineById(machine.id);
    expect(persisted.records.length, 2);
    expect(StrengthRecords.maxWeight(persisted.records), 80);
    expect(persisted.records.singleWhere((x) => x.id == b.id).weight, 70);
    expect(persisted.records.singleWhere((x) => x.id == b.id).note, 'Corrigido');
    app.dispose();
    reopened.dispose();
  });

  testWidgets('sem séries os botões CSV, compartilhar e baixar PDF desativam',
      (tester) async {
    final app = AppController(persistenceEnabled: false);
    addTearDown(app.dispose);
    await app.importBackup(
      '{"schemaVersion":2,"machines":[],"cardio":{},'
      '"sessions":[],"favorites":[],"activeSessionId":null}');
    app.isPro = true; // Preview Pro local, sem cobrança real.
    await tester.pumpWidget(AppScope(controller: app,
      child: MaterialApp(theme: AppTheme.dark,
        home: const ProExportScreen())));
    await tester.pumpAndSettle();
    final csv = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Copiar CSV'));
    expect(csv.onPressed, isNull);
    final pdf = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Gerar e compartilhar PDF'));
    expect(pdf.onPressed, isNull);
    final download = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Baixar PDF'));
    expect(download.onPressed, isNull);
    await tester.scrollUntilVisible(
      find.textContaining('Nenhum registro neste filtro'), 160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Nenhum registro neste filtro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('supino barra/halter recebem ilustração vetorial diferente de máquina',
      () {
    expect(UnverifiedExerciseIllustration.hasMovementSchematic(
      'barbell_bench_press'), isTrue);
    expect(UnverifiedExerciseIllustration.hasMovementSchematic(
      'dumbbell_bench_press'), isTrue);
    final bar = UnverifiedExerciseIllustration.benchPressSchematic(
      'barbell_bench_press');
    final dumbbell = UnverifiedExerciseIllustration.benchPressSchematic(
      'dumbbell_bench_press');
    expect(bar, isNot(dumbbell));
    for (final id in ['barbell_bench_press', 'dumbbell_bench_press']) {
      final item = buildExerciseCatalog().firstWhere((x) => x.id == id);
      expect(IllustrationAssets.hasVerifiedExecution(item), isFalse);
    }
  });
}
