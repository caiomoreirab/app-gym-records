import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/services/analytics_service.dart';
import 'package:gymrecords/services/report_export_service.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/services/local_data_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('100 kg x 3 permanece idêntico no histórico e no CSV', () async {
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    await app.importBackup(
      '{"schemaVersion":2,"machines":[],"cardio":{},'
      '"sessions":[],"favorites":[],"activeSessionId":null}');
    final machine = app.ensureMachineAdded(buildExerciseCatalog()
      .firstWhere((m) => m.id == 'barbell_bench_press'));
    final first = app.addRecord(machine, weight: 100, repetitions: 3);
    final entries = ReportExportService.entries(
      machines: app.machines, cardioActivities: [],
      period: AnalyticsPeriod.all,
      now: DateTime.now().add(const Duration(days: 1)),
    );
    final csv = ReportExportService.toCsv(entries);
    expect(entries.length, 1);
    expect(entries.single.repetitions, 3);
    expect(entries.single.sessionId, first.sessionId);
    expect(entries.single.setNumber, 1);
    expect(csv, contains('"session_id"'));
    expect(csv, contains('"set_number"'));
    expect(csv, contains('"100.00","3"'));
    await app.flushPendingWrites();
    final other = AppController(persistenceEnabled: false, store: store);
    await other.loadPreferences();
    final loaded = other.machineById(machine.id).records.single;
    expect(loaded.repetitions, 3);
    expect(loaded.weight, 100);
    app.dispose();
    other.dispose();
  });

  test('PDF é gerado com cabeçalho válido', () async {
    final sample = ReportEntry(
      date: DateTime(2026, 11, 20),
      group: 'Peito', exercise: 'Supino reto com barra',
      type: 'strength', weight: 100, repetitions: 3,
      setNumber: 1, sessionId: 'Treino A', rpe: 8,
    );
    final bytes = await ReportExportService.buildPdf(
      entries: [sample], title: 'GymRecords',
      subtitle: 'Validação de série');
    expect(bytes.length, greaterThan(500));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
