import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/models/cardio_record.dart';
import 'package:gymrecords/models/muscle_group.dart';
import 'package:gymrecords/services/local_data_store.dart';
import 'package:gymrecords/services/usage_events.dart';
import 'package:gymrecords/state/app_controller.dart';

void main() {
  test('registros de musculação e cardio sobrevivem a uma nova sessão', () async {
    final store = MemoryLocalDataStore();
    final first = AppController(persistenceEnabled: false, store: store);
    await first.loadPreferences();

    final exercise = first.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((item) => item.id == 'barbell_bench_press'),
    );
    first.addRecord(exercise, weight: 75, repetitions: 8);
    first.updateMachineNote(exercise, 'Pausa de dois segundos');
    first.addCustomMachine(name: 'Minha máquina', group: MuscleGroup.chest);
    final cardio = first.cardioActivities.firstWhere((item) => item.id == 'jump_rope');
    first.addCardioRecord(cardio, CardioRecord(
      date: DateTime(2026, 11, 19),
      duration: const Duration(minutes: 14),
    ));
    await first.flushPendingWrites();

    final second = AppController(persistenceEnabled: false, store: store);
    await second.loadPreferences();
    final loaded = second.machineById('barbell_bench_press');
    expect(loaded.records.last.weight, 75);
    expect(loaded.records.last.repetitions, 8);
    expect(loaded.note, 'Pausa de dois segundos');
    expect(second.machines.any((machine) => machine.isCustom && machine.name == 'Minha máquina'), isTrue);
    expect(second.cardioActivities.firstWhere((item) => item.id == 'jump_rope').records.last.duration.inMinutes, 14);
    first.dispose();
    second.dispose();
  });

  test('backup JSON é restaurável e backup inválido não apaga os treinos', () async {
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    await app.loadPreferences();
    final machine = app.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((item) => item.id == 'barbell_bench_press'),
    );
    app.addRecord(machine, weight: 82.5, repetitions: 5);
    await app.flushPendingWrites();
    final json = app.exportBackup();

    await expectLater(app.importBackup('{"schemaVersion":999,"machines":[],"cardio":{}}'),
        throwsA(isA<FormatException>()));
    expect(app.machineById('barbell_bench_press').records.last.weight, 82.5);

    final newApp = AppController(persistenceEnabled: false, store: MemoryLocalDataStore());
    await newApp.importBackup(json);
    expect(newApp.machineById('barbell_bench_press').records.last.weight, 82.5);
    app.dispose();
    newApp.dispose();
  });

  test('eventos anônimos só são registrados após consentimento', () async {
    final sink = MemoryUsageEventSink();
    final app = AppController(persistenceEnabled: false, analyticsSink: sink);
    app.trackUsage('app_opened');
    await Future<void>.delayed(Duration.zero);
    expect(sink.events, isEmpty);

    app.setAnalyticsConsent(true);
    app.trackUsage('app_opened');
    await Future<void>.delayed(Duration.zero);
    expect(sink.events.single.name, 'app_opened');
    expect(sink.events.single.attributes, isEmpty);
    app.dispose();
  });
}
