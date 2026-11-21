import 'dart:typed_data';
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
  const ReportEntry({required this.date, required this.group,
    required this.exercise, required this.type, this.weight = 0,
    this.repetitions, this.durationSeconds, this.distanceKm,
    this.sessionId = '', this.setNumber, this.rpe, this.isWarmup = false,
    this.restSeconds, this.note = ''});
  final DateTime date;
  final String group;
  final String exercise;
  final String type;
  final double weight;
  final int? repetitions;
  final int? durationSeconds;
  final double? distanceKm;
  final String sessionId;
  final int? setNumber;
  final double? rpe;
  final bool isWarmup;
  final int? restSeconds;
  final String note;
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
      final ordered = [...machine.records]
        ..sort((a, b) => a.date.compareTo(b.date));
      final counters = <String, int>{};
      for (final record in ordered) {
        final sessionId = record.effectiveSessionId;
        final setNumber = (counters[sessionId] ?? 0) + 1;
        counters[sessionId] = setNumber;
        if (record.date.isBefore(lower) || record.date.isAfter(now)) continue;
        all.add(ReportEntry(
          date: record.date, group: machine.group.label,
          exercise: machine.name, type: 'strength', weight: record.weight,
          repetitions: record.repetitions, durationSeconds: record.durationSeconds,
          sessionId: sessionId, setNumber: setNumber, rpe: record.rpe,
          isWarmup: record.isWarmup, restSeconds: record.restSeconds,
          note: record.note,
        ));
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
      ['date', 'session_id', 'set_number', 'group', 'exercise', 'type', 'weight', 'repetitions', 'duration_seconds', 'distance_km', 'rpe', 'warmup', 'rest_seconds', 'note'],
      for (final entry in entries)
        [
          '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}',
          entry.sessionId,
          entry.setNumber?.toString() ?? '',
          entry.group,
          entry.exercise,
          entry.type,
          entry.weight > 0 ? entry.weight.toStringAsFixed(2) : '',
          entry.repetitions?.toString() ?? '',
          entry.durationSeconds?.toString() ?? '',
          entry.distanceKm?.toStringAsFixed(3) ?? '',
          entry.rpe?.toStringAsFixed(1) ?? '',
          entry.isWarmup ? 'true' : 'false',
          entry.restSeconds?.toString() ?? '',
          entry.note,
        ],
    ];
    return rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n');
  }

  static String _escapeCsv(String cell) {
    // Prevent spreadsheet formula interpretation for user-supplied names.
    final safe = cell.isNotEmpty && '=+-@'.contains(cell[0]) ? String.fromCharCode(39) + cell : cell;
    return '"' + safe.replaceAll('"', '""') + '"';
  }

  static Future<Uint8List> buildPdf({
    required List<ReportEntry> entries,
    required String title,
    required String subtitle,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/Barlow-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final document = pw.Document();
    final data = entries.map((r) => [
      '${r.date.day}/${r.date.month}/${r.date.year}',
      r.sessionId.isEmpty ? '—' : r.sessionId,
      r.exercise,
      r.setNumber?.toString() ?? '—',
      [
        if (r.weight > 0) '${r.weight.toStringAsFixed(1)} kg',
        if (r.repetitions != null) '× ${r.repetitions} rep',
        if (r.distanceKm != null) '${r.distanceKm!.toStringAsFixed(2)} km',
        if (r.durationSeconds != null)
          '${(r.durationSeconds! / 60).toStringAsFixed(1)} min',
        if (r.isWarmup) '(aquec.)',
      ].join(' '),
      r.rpe?.toStringAsFixed(1) ?? '—',
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
            headers: ['Data', 'Sessao', 'Exercicio', 'Serie', 'Carga e reps', 'RPE'],
            data: data,
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(5),
            columnWidths: {
              0: const pw.FixedColumnWidth(54),
              1: const pw.FixedColumnWidth(58),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FixedColumnWidth(26),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FixedColumnWidth(28),
            },
          ),
      ],
    ));
    return document.save();
  }

  static Future<void> sharePdf({
    required List<ReportEntry> entries,
    required String title,
    required String subtitle,
  }) async {
    final bytes = await buildPdf(
      entries: entries, title: title, subtitle: subtitle);
    await Printing.sharePdf(bytes: bytes, filename: 'gymrecords_relatorio.pdf');
  }
}
