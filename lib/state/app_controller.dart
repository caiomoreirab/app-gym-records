import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_data.dart';
import '../models/cardio_activity.dart';
import '../models/cardio_achievement.dart';
import '../models/cardio_record.dart';
import '../models/machine.dart';
import '../models/muscle_group.dart';
import '../models/user_profile.dart';
import '../models/workout_record.dart';
import '../models/workout_session.dart';
import '../services/local_data_store.dart';
import '../services/workout_snapshot_codec.dart';
import '../services/usage_events.dart';
import '../services/local_usage_metrics.dart';

class AppController extends ChangeNotifier {
  AppController({
    this.persistenceEnabled = true,
    LocalDataStore? store,
    UsageEventSink? analyticsSink,
  })  : _machines = persistenceEnabled ? <Machine>[] : buildInitialMachines(),
        _cardioActivities = persistenceEnabled ? buildCardioActivities() : buildInitialCardioActivities(),
        _preferences = persistenceEnabled ? SharedPreferencesAsync() : null,
        _store = store ?? (persistenceEnabled ? LocalDataStore.production() : null),
        _analyticsSink = analyticsSink ?? const DisabledUsageEventSink();

  static const _phase1Preview = bool.fromEnvironment('GYM_PHASE1_PREVIEW');
  static String _preferenceKey(String key) =>
      _phase1Preview ? 'gymrecords_phase1_$key' : key;

  static const _nameKey = 'display_name';
  static const _illustrationStyleKey = 'illustration_style';
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _unitKey = 'weight_unit';
  static const _distanceUnitKey = 'distance_unit';
  static const _incrementKey = 'weight_increment';
  static const _proPreviewKey = 'pro_preview_enabled';
  static const _largeTextKey = 'accessibility_large_text';
  static const _bodyWeightKey = 'body_weight_kg';
  static const _languageKey = 'language_code';
  static const _analyticsConsentKey = 'analytics_consent_v2';

  final bool persistenceEnabled;
  final SharedPreferencesAsync? _preferences;
  final LocalDataStore? _store;
  final UsageEventSink _analyticsSink;
  Future<void> _writeQueue = Future<void>.value();
  bool analyticsConsent = false;
  String? persistenceError;
  bool _failedToReadStorage = false;

  /// A failed read is not a blank database. Never overwrite its contents
  /// accidentally with an empty state after a startup error.
  bool get storageRecoveryRequired => _failedToReadStorage;
  bool _onboardingCompleted = false;

  String displayName = '';
  IllustrationStyle? illustrationStyle;
  String unit = 'kg';
  String distanceUnit = 'km';
  double increment = 2.5;
  bool isPro = true; // front-end preview; billing will replace this flag later
  String languageCode = 'system';
  bool largeText = false;
  /// Optional local profile value; never inferred from workout weights.
  double? bodyWeightKg;

  final List<Machine> _machines;
  final List<CardioActivity> _cardioActivities;
  final Map<String, List<CardioRecord>> _preservedCardio = {};
  final List<WorkoutSession> _sessions = [];
  final Set<String> _favorites = {};
  final Map<String, dynamic> _rootSnapshotExtras = {};
  String? activeSessionId;
  int _recordSerial = 0;
  final LocalUsageMetrics localMetrics = LocalUsageMetrics();

  void markSetEntryStarted() => localMetrics.beginSet(DateTime.now());

  List<WorkoutSession> get sessions =>
      List<WorkoutSession>.unmodifiable(_sessions);
  Set<String> get favorites => Set<String>.unmodifiable(_favorites);
  bool isFavorite(String id) => _favorites.contains(id);
  WorkoutSession? get activeSession {
    for (final session in _sessions) {
      if (session.id == activeSessionId) return session;
    }
    return null;
  }
  List<WorkoutRecord> recordsForSession(String sessionId) =>
      [for (final machine in _machines)
        for (final record in machine.records)
          if (record.effectiveSessionId == sessionId) record]
        ..sort((a, b) => a.date.compareTo(b.date));

  List<Machine> get favoriteMachines =>
      availableMachines.where((m) => _favorites.contains(m.id)).toList();

  void toggleFavorite(String id) {
    if (!_favorites.add(id)) _favorites.remove(id);
    notifyListeners();
    _scheduleSave();
  }

  WorkoutSession startSession({String name = 'Treino de hoje'}) {
    final now = DateTime.now();
    final id = 'session_${now.microsecondsSinceEpoch}_${_recordSerial++}';
    final existing = activeSession;
    if (existing != null) {
      final index = _sessions.indexWhere((s) => s.id == existing.id);
      if (index >= 0) {
        _sessions[index] = existing.copyWith(completedAt: now);
      }
    }
    final session = WorkoutSession(
      id: id, startedAt: now, name: name.trim().isEmpty ? 'Treino' : name.trim());
    _sessions.add(session);
    activeSessionId = id;
    localMetrics.startedSession();
    notifyListeners();
    _scheduleSave();
    return session;
  }

  void addExerciseToSession(Machine machine) {
    final session = _ensureSession();
    if (session.exerciseIds.contains(machine.id)) return;
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index < 0) return;
    _sessions[index] = session.copyWith(
      exerciseIds: [...session.exerciseIds, machine.id]);
    notifyListeners();
    _scheduleSave();
  }

  /// Completes once and returns the exact saved session for the celebration.
  WorkoutSession? completeSession({DateTime? at}) {
    final id = activeSessionId;
    if (id == null) return null;
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index < 0) return null;
    final session = _sessions[index].copyWith(completedAt: at ?? DateTime.now());
    _sessions[index] = session;
    activeSessionId = null;
    notifyListeners();
    _scheduleSave();
    return session;
  }

  WorkoutSession _ensureSession() {
    final current = activeSession;
    if (current == null) return startSession();
    final today = DateTime.now();
    final started = current.startedAt;
    if (started.year == today.year &&
        started.month == today.month &&
        started.day == today.day) {
      return current;
    }
    completeSession();
    return startSession();
  }

  void replaceRecord(Machine machine, WorkoutRecord updated) {
    final index = machine.records.indexWhere((r) => r.id == updated.id);
    if (index < 0) throw StateError('Série não encontrada.');
    machine.records[index] = updated;
    notifyListeners();
    _scheduleSave();
  }

  WorkoutRecord removeRecord(Machine machine, String recordId) {
    final index = machine.records.indexWhere((r) => r.id == recordId);
    if (index < 0) throw StateError('Série não encontrada.');
    final removed = machine.records.removeAt(index);
    notifyListeners();
    _scheduleSave();
    return removed;
  }

  void restoreRecord(Machine machine, WorkoutRecord record) {
    if (machine.records.any((r) => r.id == record.id)) return;
    machine.records.add(record);
    notifyListeners();
    _scheduleSave();
  }


  bool get onboardingComplete =>
      _onboardingCompleted &&
      displayName.trim().isNotEmpty &&
      illustrationStyle != null;

  IllustrationStyle get effectiveIllustrationStyle =>
      illustrationStyle ?? IllustrationStyle.masculine;

  Locale? get appLocale => languageCode == 'system' ? null : Locale(languageCode);

  List<CardioActivity> get cardioActivities => List<CardioActivity>.unmodifiable(_cardioActivities);

  List<Machine> get machines => List<Machine>.unmodifiable(_machines);

  List<Machine> get availableMachines {
    final byId = <String, Machine>{
      for (final machine in _machines) machine.id: machine,
    };
    for (final group in MuscleGroup.values) {
      for (final machine in buildCatalogFor(group)) {
        byId.putIfAbsent(machine.id, () => machine);
      }
    }
    return List<Machine>.unmodifiable(byId.values);
  }

  Machine ensureMachineAdded(Machine machine) {
    trackUsage('exercise_opened', {
      'group': machine.group.name,
      'exercise': machine.isCustom ? 'custom' : machine.id,
    });
    if (hasMachine(machine.id)) return machineById(machine.id);
    _machines.add(machine);
    notifyListeners();
    _scheduleSave();
    return machine;
  }

  List<Machine> get recentlyUsedMachines {
    final result = _machines
        .where((machine) => machine.latestRecord != null)
        .toList(growable: false);
    result.sort(
      (a, b) => b.latestRecord!.date.compareTo(a.latestRecord!.date),
    );
    return result;
  }

  Future<void> loadPreferences() async {
    final preferences = _preferences;
    if (persistenceEnabled && preferences != null) {
      displayName = (await preferences.getString(_preferenceKey(_nameKey)))?.trim() ?? '';
      illustrationStyle = illustrationStyleFromStorage(
        await preferences.getString(_preferenceKey(_illustrationStyleKey)),
      );
      _onboardingCompleted =
          await preferences.getBool(_preferenceKey(_onboardingCompleteKey)) ?? false;
      unit = await preferences.getString(_preferenceKey(_unitKey)) ?? 'kg';
      distanceUnit = await preferences.getString(_preferenceKey(_distanceUnitKey)) ?? 'km';
      increment = await preferences.getDouble(_preferenceKey(_incrementKey)) ?? 2.5;
      isPro = await preferences.getBool(_preferenceKey(_proPreviewKey)) ?? true;
      languageCode = await preferences.getString(_preferenceKey(_languageKey)) ?? 'system';
      largeText = await preferences.getBool(_preferenceKey(_largeTextKey)) ?? false;
      final storedKg = await preferences.getDouble(_preferenceKey(_bodyWeightKey));
      bodyWeightKg = storedKg != null && storedKg.isFinite &&
          storedKg >= 20 && storedKg <= 400 ? storedKg : null;
      analyticsConsent = await preferences.getBool(_preferenceKey(_analyticsConsentKey)) ?? false;
    }
    final store = _store;
    if (store != null) {
      try {
        final snapshot = await store.load();
        if (snapshot != null) {
          final restored = WorkoutSnapshotCodec.decode(snapshot);
          _preservedCardio
            ..clear()
            ..addAll(restored.applyTo(_machines, _cardioActivities));
          _applyRestoredSessions(restored);
        }
        _failedToReadStorage = false;
        persistenceError = null;
      } catch (error) {
        // A broken database must not be overwritten with an empty snapshot.
        _failedToReadStorage = true;
        persistenceError = 'Não foi possível ler os dados locais: $error';
      }
    }
    final sink = _analyticsSink;
    if (sink is ConsentAwareUsageEventSink) {
      await sink.setEnabled(analyticsConsent);
    }
    localMetrics.opened(DateTime.now());
    notifyListeners();
    trackUsage('app_opened');
  }

  void _applyRestoredSessions(WorkoutRestoredState restored) {
    _sessions
      ..clear()
      ..addAll(restored.sessions);
    _favorites
      ..clear()
      ..addAll(restored.favorites);
    _rootSnapshotExtras
      ..clear()
      ..addAll(restored.rootExtras);
    localMetrics.load(_rootSnapshotExtras['localMetrics']);
    activeSessionId = restored.activeSessionId;
  }

  Map<String, dynamic> _snapshot() => WorkoutSnapshotCodec.encode(
    machines: _machines,
    cardioActivities: _cardioActivities,
    preservedCardio: _preservedCardio,
    sessions: _sessions,
    favorites: _favorites,
    activeSessionId: activeSessionId,
    rootExtras: {
      ..._rootSnapshotExtras,
      'localMetrics': localMetrics.toJson(),
    },
  );

  void _scheduleSave() {
    final store = _store;
    if (store == null || _failedToReadStorage) return;
    final snapshot = _snapshot();
    // Serializing the writes prevents a slow older save from overwriting a
    // newer record. Capture the snapshot before queuing it.
    _writeQueue = _writeQueue
        .then((_) => store.save(snapshot))
        .then((_) { persistenceError = null; })
        .catchError((Object error, StackTrace stack) {
          persistenceError = 'Falha ao salvar os treinos: $error';
          notifyListeners();
        });
  }

  Future<void> flushPendingWrites() => _writeQueue;

  /// Allows retry after a transient write failure (low disk space, I/O
  /// interruption). It deliberately refuses to overwrite an unreadable DB.
  Future<bool> retrySave() async {
    if (_failedToReadStorage) return false;
    _scheduleSave();
    await flushPendingWrites();
    return persistenceError == null;
  }

  String exportBackup() => const JsonEncoder.withIndent('  ').convert(_snapshot());

  Future<void> importBackup(String backup) async {
    final decoded = jsonDecode(backup);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup JSON inválido.');
    }
    final restored = WorkoutSnapshotCodec.decode(decoded);
    await flushPendingWrites();
    final store = _store;
    if (store != null) await store.save(decoded);
    _preservedCardio
      ..clear()
      ..addAll(restored.applyTo(_machines, _cardioActivities));
    _applyRestoredSessions(restored);
    _failedToReadStorage = false;
    persistenceError = null;
    notifyListeners();
  }

  void setAnalyticsConsent(bool value) {
    analyticsConsent = value;
    _saveBool(_analyticsConsentKey, value);
    final sink = _analyticsSink;
    if (sink is ConsentAwareUsageEventSink) {
      unawaited(sink.setEnabled(value).catchError((Object _) {}));
    }
    notifyListeners();
  }

  void trackUsage(String event, [Map<String, String> attributes = const {}]) {
    if (!analyticsConsent) return;
    // No name, weights, notes, medical or other personal content.
    unawaited(_analyticsSink.track(event, attributes).catchError((Object _) {}));
  }

  void _saveString(String key, String value) {
    final preferences = _preferences;
    if (!persistenceEnabled || preferences == null) return;
    unawaited(preferences.setString(_preferenceKey(key), value));
  }

  void _saveBool(String key, bool value) {
    final preferences = _preferences;
    if (!persistenceEnabled || preferences == null) return;
    unawaited(preferences.setBool(_preferenceKey(key), value));
  }

  void _saveDouble(String key, double value) {
    final preferences = _preferences;
    if (!persistenceEnabled || preferences == null) return;
    unawaited(preferences.setDouble(_preferenceKey(key), value));
  }

  List<Machine> machinesFor(MuscleGroup group) {
    final byId = <String, Machine>{
      for (final machine in buildCatalogFor(group)) machine.id: machine,
    };
    for (final machine in _machines.where((machine) => machine.group == group)) {
      byId[machine.id] = machine;
    }
    return byId.values.toList(growable: false);
  }

  Machine machineById(String id) {
    return _machines.firstWhere((machine) => machine.id == id);
  }

  bool hasMachine(String id) => _machines.any((machine) => machine.id == id);

  void setDisplayName(String value) {
    displayName = value.trim();
    notifyListeners();
    _saveString(_nameKey, displayName);
  }

  void setIllustrationStyle(IllustrationStyle value) {
    illustrationStyle = value;
    notifyListeners();
    _saveString(_illustrationStyleKey, value.storageValue);
  }

  void completeOnboarding() {
    _onboardingCompleted = true;
    notifyListeners();
    _saveBool(_onboardingCompleteKey, true);
    trackUsage('onboarding_completed');
  }

  void setUnit(String value) {
    unit = value;
    notifyListeners();
    _saveString(_unitKey, value);
  }

  void setDistanceUnit(String value) {
    distanceUnit = value;
    notifyListeners();
    _saveString(_distanceUnitKey, value);
  }

  void setIncrement(double value) {
    increment = value;
    notifyListeners();
    _saveDouble(_incrementKey, value);
  }

  void setLanguageCode(String value) {
    languageCode = value;
    notifyListeners();
    _saveString(_languageKey, value);
  }

  Future<void> setBodyWeightKg(double? value) async {
    if (value != null && (!value.isFinite || value < 20 || value > 400)) {
      throw const FormatException('Informe um peso entre 20 e 400 kg.');
    }
    bodyWeightKg = value;
    notifyListeners();
    final preferences = _preferences;
    if (!persistenceEnabled || preferences == null) return;
    if (value == null) {
      await preferences.remove(_preferenceKey(_bodyWeightKey));
    } else {
      await preferences.setDouble(_preferenceKey(_bodyWeightKey), value);
    }
  }

  void setLargeText(bool value) {
    largeText = value;
    _saveBool(_largeTextKey, value);
    notifyListeners();
  }

  void setProPreview(bool value) {
    isPro = value;
    notifyListeners();
    _saveBool(_proPreviewKey, value);
  }

  void addMachine(Machine machine) {
    if (hasMachine(machine.id)) return;
    _machines.add(machine);
    notifyListeners();
    _scheduleSave();
  }

  void addCustomMachine({required String name, required MuscleGroup group, EquipmentType equipment = EquipmentType.other}) {
    final id = 'custom_${DateTime.now().microsecondsSinceEpoch}';
    _machines.add(
      Machine(
        id: id,
        name: name.trim(),
        group: group,
        equipment: equipment,
        imageAsset: 'assets/illustrations/generic_machine.webp',
        isCustom: true,
      ),
    );
    notifyListeners();
    _scheduleSave();
    trackUsage('custom_exercise_created', {'group': group.name});
  }

  void renameMachine(Machine machine, String name) {
    machine.name = name.trim();
    machine.nameEn = machine.name;
    notifyListeners();
    _scheduleSave();
  }

  void deleteMachine(Machine machine) {
    _machines.remove(machine);
    notifyListeners();
    _scheduleSave();
  }

  void updateMachineNote(Machine machine, String note) {
    machine.note = note.trim();
    notifyListeners();
    _scheduleSave();
  }

  CardioAchievement? addCardioRecord(CardioActivity activity, CardioRecord record) {
    final hadPrevious = activity.records.isNotEmpty;
    final previousDistance = activity.longestDistanceKm;
    final previousDurationSeconds = activity.longestDuration.inSeconds.toDouble();
    final previousPace = activity.bestPaceMinutes;
    final previousSpeed = activity.fastestSpeedKmh;

    activity.records.add(record);
    notifyListeners();
    _scheduleSave();
    trackUsage('cardio_record_created', {'activity': activity.id});

    final metrics = <CardioAchievementMetric>[];
    final distance = record.distanceKm;
    final pace = activity.supportsPace && distance != null && distance > 0
        ? (record.duration.inSeconds / 60) / (distance / activity.paceDistanceKm)
        : null;
    final speed = record.averageSpeedKmh;

    // The first cardio entry establishes the user's first PR, matching strength
    // exercises. Later entries must actually improve a previous mark.
    if (!hadPrevious) {
      if (pace != null) {
        return CardioAchievement([
          CardioAchievementMetric(type: CardioAchievementType.pace, previousValue: 0, newValue: pace),
        ]);
      }
      if (distance != null && distance > 0) {
        return CardioAchievement([
          CardioAchievementMetric(type: CardioAchievementType.distance, previousValue: 0, newValue: distance),
        ]);
      }
      return CardioAchievement([
        CardioAchievementMetric(type: CardioAchievementType.duration, previousValue: 0, newValue: record.duration.inSeconds.toDouble()),
      ]);
    }

    // Priority is intentional: pace is the most meaningful PR for running/rowing,
    // then distance, speed and duration. The achievement screen uses the first.
    if (pace != null && previousPace != null && pace + 0.0001 < previousPace) {
      metrics.add(CardioAchievementMetric(
        type: CardioAchievementType.pace,
        previousValue: previousPace,
        newValue: pace,
      ));
    }
    if (distance != null && previousDistance > 0 && distance > previousDistance + 0.0001) {
      metrics.add(CardioAchievementMetric(
        type: CardioAchievementType.distance,
        previousValue: previousDistance,
        newValue: distance,
      ));
    }
    if (!activity.supportsPace && speed != null && previousSpeed != null && speed > previousSpeed + 0.0001) {
      metrics.add(CardioAchievementMetric(
        type: CardioAchievementType.speed,
        previousValue: previousSpeed,
        newValue: speed,
      ));
    }
    if (previousDurationSeconds > 0 && record.duration.inSeconds > previousDurationSeconds) {
      metrics.add(CardioAchievementMetric(
        type: CardioAchievementType.duration,
        previousValue: previousDurationSeconds,
        newValue: record.duration.inSeconds.toDouble(),
      ));
    }

    return metrics.isEmpty ? null : CardioAchievement(metrics);
  }

  WorkoutRecord addRecord(Machine machine, {
    double weight = 0,
    int? repetitions,
    int? durationSeconds,
    double? rpe,
    int? rir,
    int? restSeconds,
    String note = '',
    bool isWarmup = false,
    DateTime? when,
  }) {
    if (weight < 0 || !weight.isFinite ||
        (repetitions != null && (repetitions < 0 || repetitions > 1000)) ||
        (durationSeconds != null && durationSeconds < 0) ||
        (rpe != null && (!rpe.isFinite || rpe < 1 || rpe > 10)) ||
        (rir != null && (rir < 0 || rir > 10)) ||
        (restSeconds != null && (restSeconds < 0 || restSeconds > 36000)) ||
        note.length > 3000) {
      throw const FormatException('Valores de série inválidos.');
    }
    addExerciseToSession(machine);
    final session = _ensureSession();
    final now = when ?? DateTime.now();
    final record = WorkoutRecord(
      id: 'set_${now.microsecondsSinceEpoch}_${_recordSerial++}',
      sessionId: session.id,
      date: now,
      weight: weight,
      repetitions: repetitions,
      durationSeconds: durationSeconds,
      rpe: rpe,
      rir: rir,
      restSeconds: restSeconds,
      note: note.trim(),
      isWarmup: isWarmup,
    );
    machine.records.add(record);
    localMetrics.savedSet(now, repetitions);
    notifyListeners();
    _scheduleSave();
    trackUsage('strength_record_created', {
      'group': machine.group.name,
      'exercise': machine.isCustom ? 'custom' : machine.id,
    });
    return record;
  }

  @override
  void dispose() {
    final store = _store;
    if (store != null) {
      unawaited(_writeQueue.then((_) => store.close()));
    }
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado.');
    return scope!.notifier!;
  }
}
