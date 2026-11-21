/// Privacy-preserving aggregate metrics stored only in the JSON snapshot.
/// No user identifiers, notes, exercise names, weights or network calls.
class LocalUsageMetrics {
  DateTime? firstOpenedAt;
  DateTime? firstSavedAt;
  int seriesSaved = 0;
  int seriesWithRepetitions = 0;
  int sessionsStarted = 0;
  int timedSeries = 0;
  int totalSeriesSeconds = 0;
  int recordShares = 0;
  DateTime? _entryStartedAt;

  LocalUsageMetrics();

  void load(Object? source) {
    if (source is! Map) return;
    firstOpenedAt = _parse(source['firstOpenedAt']);
    firstSavedAt = _parse(source['firstSavedAt']);
    seriesSaved = _nonNegative(source['seriesSaved']);
    seriesWithRepetitions = _nonNegative(source['seriesWithRepetitions']);
    sessionsStarted = _nonNegative(source['sessionsStarted']);
    timedSeries = _nonNegative(source['timedSeries']);
    totalSeriesSeconds = _nonNegative(source['totalSeriesSeconds']);
    recordShares = _nonNegative(source['recordShares']);
  }

  void opened(DateTime now) => firstOpenedAt ??= now;
  void beginSet(DateTime now) => _entryStartedAt = now;

  void savedSet(DateTime now, int? repetitions) {
    firstSavedAt ??= now;
    seriesSaved++;
    if (repetitions != null && repetitions > 0) {
      seriesWithRepetitions++;
    }
    if (_entryStartedAt != null) {
      final seconds = now.difference(_entryStartedAt!).inSeconds;
      if (seconds >= 0 && seconds <= 3600) {
        timedSeries++;
        totalSeriesSeconds += seconds;
      }
    }
    _entryStartedAt = null;
  }

  void startedSession() => sessionsStarted++;
  void sharedRecord() => recordShares++;

  double? get averageSeriesSeconds =>
      timedSeries == 0 ? null : totalSeriesSeconds / timedSeries;

  double? get repetitionsFillRate =>
      seriesSaved == 0 ? null : seriesWithRepetitions / seriesSaved;

  int? get firstSaveSeconds {
    if (firstOpenedAt == null || firstSavedAt == null) return null;
    final seconds = firstSavedAt!.difference(firstOpenedAt!).inSeconds;
    return seconds >= 0 ? seconds : null;
  }

  Map<String, dynamic> toJson() => {
    'firstOpenedAt': firstOpenedAt?.toUtc().toIso8601String(),
    'firstSavedAt': firstSavedAt?.toUtc().toIso8601String(),
    'seriesSaved': seriesSaved,
    'seriesWithRepetitions': seriesWithRepetitions,
    'sessionsStarted': sessionsStarted,
    'timedSeries': timedSeries,
    'totalSeriesSeconds': totalSeriesSeconds,
    'recordShares': recordShares,
  };

  static DateTime? _parse(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;

  static int _nonNegative(Object? raw) =>
      raw is int && raw >= 0 ? raw : 0;
}
