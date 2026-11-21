import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cardio_activity.dart';
import '../models/machine.dart';
import '../models/muscle_group.dart';
import '../models/workout_record.dart';
import 'analytics_service.dart';

class ReportEntry {
  const ReportEntry({required this.date, required this.group, required this.exercise, required this.type, this.weight = 0, this.repetitions, this.durationSeconds, this.distanceKm, this.sessionId = '', this.isWarmup = false, this.rpe});
  final DateTime date;
  final String group;
  final String exercise;
  final String type;
  final double weight;
  final int? repetitions;
  final int? durationSeconds;
  final double? distanceKm;
  final String sessionId;
  final bool isWarmup;
  final double? rpe;
}

abstract final class ReportExportService {
  static List<ReportEntry> entries({
    required Iterable<Machine> machines,
    required Iterable<CardioActivity> cardioActivities,
    required AnalyticsPeriod period,
    required DateTime now,
    MuscleGroup? group,
  }) {
    final all = <ReportEntry>[];
    final records = <WorkoutRecord>[for (final machine in machines) ...machine.records];
    final lower = period.lowerBound(now, records);
    for (final machine in machines) {
      if (group != null && machine.group != group) continue;
      for (final record in machine.records) {
        if (record.date.isBefore(lower) || record.date.isAfter(now)) continue;
        all.add(ReportEntry(date: record.date, group: machine.group.label, exercise: machine.name, type: 'strength', weight: record.weight, repetitions: record.repetitions, durationSeconds: record.durationSeconds, sessionId: record.sessionId.isEmpty ? WorkoutRecord.dayKey(record.date) : record.sessionId, isWarmup: record.isWarmup, rpe: record.rpe));
      }
    }
    if (group == null) {
      for (final activity in cardioActivities) {
        for (final record in activity.records) {
          if (record.date.isBefore(lower) || record.date.isAfter(now)) continue;
          all.add(ReportEntry(date: record.date, group: 'Cardio', exercise: activity.name, type: 'cardio', durationSeconds: record.duration.inSeconds, distanceKm: record.distanceKm));
        }
      }
    }
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  static String toCsv(List<ReportEntry> entries) {
    final rows = <List<String>>[
      ['date', 'session_id', 'group', 'exercise', 'type', 'weight', 'repetitions', 'warmup', 'rpe', 'duration_seconds', 'distance_km'],
      for (final entry in entries)
        [
          '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}',
          entry.sessionId,
          entry.group,
          entry.exercise,
          entry.type,
          entry.weight > 0 ? entry.weight.toStringAsFixed(2) : '',
          entry.repetitions?.toString() ?? '',
          entry.isWarmup ? 'yes' : 'no',
          entry.rpe?.toStringAsFixed(1) ?? '',
          entry.durationSeconds?.toString() ?? '',
          entry.distanceKm?.toStringAsFixed(3) ?? '',
        ],
    ];
    return rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n');
  }

  static String _escapeCsv(String cell) {
    // Prevent spreadsheet formula interpretation for user-supplied names.
    final safe = cell.isNotEmpty && '=+-@'.contains(cell[0]) ? String.fromCharCode(39) + cell : cell;
    return '"' + safe.replaceAll('"', '""') + '"';
  }

  static Future<void> sharePdf({required List<ReportEntry> entries, required String title, required String subtitle}) async {
    final fontData = await rootBundle.load('assets/fonts/Barlow-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final document = pw.Document();
    final data = entries.map((r) => [
      '${r.date.day}/${r.date.month}/${r.date.year}',
      r.group,
      r.exercise,
      r.weight > 0 ? '${r.weight.toStringAsFixed(1)} kg' : r.distanceKm != null ? '${r.distanceKm!.toStringAsFixed(2)} km' : '—',
      r.repetitions?.toString() ?? '—',
      r.isWarmup ? 'Sim' : 'Não',
      r.durationSeconds != null ? '${(r.durationSeconds! / 60).toStringAsFixed(1)} min' : '—',
    ]).toList();

    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(26),
      theme: pw.ThemeData.withFont(base: font, bold: font),
      build: (context) => [
        pw.Text(title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text(subtitle, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 18),
        pw.Text('${entries.length} registros', style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 12),
        if (data.isEmpty)
          pw.Text('Nenhum registro para este periodo.')
        else
          pw.Table.fromTextArray(
            headers: ['Data', 'Grupo', 'Exercício', 'Carga', 'Reps', 'Aquec.', 'Duração'],
            data: data,
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(5),
            columnWidths: {0: const pw.FixedColumnWidth(51), 1: const pw.FixedColumnWidth(51), 2: const pw.FlexColumnWidth(2), 3: const pw.FixedColumnWidth(62), 4: const pw.FixedColumnWidth(33), 5: const pw.FixedColumnWidth(38), 6: const pw.FixedColumnWidth(47)},
          ),
      ],
    ));
    await Printing.sharePdf(bytes: await document.save(), filename: 'gymrecords_relatorio.pdf');
  }
}
