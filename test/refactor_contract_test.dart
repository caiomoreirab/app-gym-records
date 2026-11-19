import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/models/cardio_activity.dart';
import 'package:gymrecords/models/muscle_group.dart';
import 'package:gymrecords/models/user_profile.dart';
import 'package:gymrecords/services/analytics_service.dart';
import 'package:gymrecords/services/cardio_assets.dart';
import 'package:gymrecords/services/illustration_assets.dart';
import 'package:gymrecords/services/report_export_service.dart';
import 'package:gymrecords/widgets/two_view_image_pager.dart';
import 'package:gymrecords/state/app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every catalog exercise image is assigned exclusively to the selected profile', () async {
    final catalog = buildExerciseCatalog();
    expect(catalog.length, 124);
    for (final style in IllustrationStyle.values) {
      for (final exercise in catalog) {
        final execution = IllustrationAssets.exercise(exercise, style);
        final muscles = IllustrationAssets.muscle(exercise, style);
        expect(execution, contains('/${style.assetFolder}/'));
        expect(muscles, contains('/${style.assetFolder}/'));
        await rootBundle.load(execution);
        await rootBundle.load(muscles);
      }
    }
  });

  test('all cardio activities and muscle groups have execution and muscle assets for all profiles', () async {
    for (final style in IllustrationStyle.values) {
      await rootBundle.load(CardioAssets.group(style));
      for (final group in MuscleGroup.values) {
        await rootBundle.load(IllustrationAssets.group(group, style));
      }
      for (final kind in CardioKind.values) {
        final a = CardioAssets.execution(kind, style);
        final b = CardioAssets.activation(kind, style);
        expect(a, contains('/${style.assetFolder}/'));
        expect(b, contains('/${style.assetFolder}/'));
        await rootBundle.load(a);
        await rootBundle.load(b);
        expect(a, isNot(b));
      }
    }
  });

  test('analytics have no invented percentage without comparable logs', () {
    final empty = buildExerciseCatalog();
    final summary = AnalyticsService.summary(empty, period: AnalyticsPeriod.all, now: DateTime(2026, 11, 18));
    expect(summary.progressPercent, isNull);
    expect(summary.logs, 0);
    expect(summary.volumeKg, 0);
  });

  test('CSV header remains present for an empty export', () {
    final csv = ReportExportService.toCsv(const []);
    expect(csv, contains('date'));
    expect(csv, contains('group'));
  });

  test('bodyweight exercises can log reps and time independently', () {
    final app = AppController(persistenceEnabled: false);
    final plank = app.ensureMachineAdded(buildExerciseCatalog().firstWhere((m) => m.id == 'plank'));
    expect(plank.prefersBodyMetrics, isTrue);
    expect(plank.supportsDuration, isTrue);
    app.addRecord(plank, repetitions: 12);
    expect(plank.recordWeight, 0);
    expect(plank.bestRepetitions, 12);
    app.addRecord(plank, durationSeconds: 45);
    expect(plank.bestDurationSeconds, 45);
    expect(plank.latestRecord?.durationSeconds, 45);
  });

  test('v0.8.0: every strength muscle image has different bytes than its execution image', () async {
    for (final style in IllustrationStyle.values) {
      for (final exercise in buildExerciseCatalog()) {
        final execution = await rootBundle.load(IllustrationAssets.exercise(exercise, style));
        final anatomy = await rootBundle.load(IllustrationAssets.muscle(exercise, style));
        expect(execution.lengthInBytes, isNot(anatomy.lengthInBytes),
            reason: 'Execution and muscle art must be independent for ${exercise.id} / ${style.name}');
      }
    }
  });

  test('v0.8.0: cardio activation is a separate image, not the execution asset', () async {
    for (final style in IllustrationStyle.values) {
      for (final activity in CardioKind.values) {
        final execution = await rootBundle.load(CardioAssets.execution(activity, style));
        final anatomy = await rootBundle.load(CardioAssets.activation(activity, style));
        expect(execution.lengthInBytes, isNot(anatomy.lengthInBytes),
            reason: 'Cardio asset overlap: ${activity.name} / ${style.name}');
      }
    }
  });

  testWidgets('swiping alternates full-frame image instead of dragging PageView fractions', (tester) async {
    const first = 'assets/images/cardio/feminine/treadmill.webp';
    const second = 'assets/images/cardio_activation/feminine/treadmill.webp';
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(
        child: TwoViewImagePager(visualSetKey: 'treadmill:feminine', executionPath: first, musclePath: second, width: 320, height: 220, showLabel: true),
      )),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Execution'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    await tester.drag(find.byType(TwoViewImagePager), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(find.text('Muscles'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });
}
