/// Reads user-provided CSV locally, without server calls. Supports columns
/// used by GymRecords and common Hevy/Strong CSV export labels.
class CsvWorkoutEntry {
  const CsvWorkoutEntry({required this.exercise, required this.date,
    required this.weight, required this.repetitions, required this.rowNumber});
  final String exercise;
  final DateTime date;
  final double weight;
  final int repetitions;
  final int rowNumber;
}
class CsvHistoryImportService {
  const CsvHistoryImportService._();

  static List<CsvWorkoutEntry> parse(String source) {
    if (source.length > 2000000) {
      throw const FormatException('CSV excede o limite de 2 MB.');
    }
    final normalized = source.replaceFirst('\uFEFF', '');
    final firstLine = normalized.split(RegExp(r'\r?\n')).first;
    final delimiter = firstLine.contains(';') ? ';' : ',';
    final rows = _parseRows(normalized, delimiter);
    if (rows.isEmpty) throw const FormatException('CSV vazio.');
    if (rows.length > 10001) throw const FormatException('Mais de 10 mil linhas.');
    final header = rows.first.map((x) => x.trim().toLowerCase()).toList();
    int column(List<String> candidates) {
      for (final key in candidates) {
        final index = header.indexOf(key);
        if (index >= 0) return index;
      }
      return -1;
    }
    final exerciseCol = column([
      'exercise', 'exercise title', 'exercise name', 'exercise_name',
      'exercício', 'exercicio', 'name',
    ]);
    final dateCol = column(['date','start time','start_time','data','datetime']);
    final weightCol = column(['weight','weight (kg)','weight_kg','peso','carga']);
    final repsCol = column(['repetitions','reps','repetições','repeticoes']);
    if (exerciseCol < 0 || dateCol < 0 || weightCol < 0 || repsCol < 0) {
      throw const FormatException(
        'Colunas obrigatórias: exercise, date, weight, repetitions (ou equivalentes).');
    }
    final result = <CsvWorkoutEntry>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      String field(int index) => index < row.length ? row[index].trim() : '';
      final name = field(exerciseCol);
      final rawDate = field(dateCol);
      final parsedDate = DateTime.tryParse(rawDate.replaceFirst(' ', 'T'));
      final rawWeight = field(weightCol).replaceAll('kg','').trim().replaceAll(',', '.');
      final weight = double.tryParse(rawWeight);
      final reps = int.tryParse(field(repsCol));
      if (name.isEmpty || parsedDate == null || weight == null ||
          !weight.isFinite || weight < 0 || weight > 10000 ||
          reps == null || reps <= 0 || reps > 1000) continue;
      result.add(CsvWorkoutEntry(
        exercise: name, date: parsedDate, weight: weight,
        repetitions: reps, rowNumber: i));
    }
    return result;
  }

  static List<List<String>> _parseRows(String input, String delimiter) {
    final rows = <List<String>>[];
    var row = <String>[];
    var buffer = StringBuffer();
    var quoted = false;
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '"') {
        if (quoted && i + 1 < input.length && input[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (!quoted && char == delimiter) {
        row.add(buffer.toString()); buffer = StringBuffer();
      } else if (!quoted && (char == '\n' || char == '\r')) {
        if (char == '\r' && i + 1 < input.length && input[i+1] == '\n') i++;
        row.add(buffer.toString());
        if (row.any((e) => e.trim().isNotEmpty)) rows.add(row);
        row = <String>[];
        buffer = StringBuffer();
      } else {
        buffer.write(char);
      }
    }
    if (quoted) throw const FormatException('CSV possui aspas sem fechamento.');
    row.add(buffer.toString());
    if (row.any((e) => e.trim().isNotEmpty)) rows.add(row);
    return rows;
  }
}
