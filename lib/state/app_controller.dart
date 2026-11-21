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
import '../services/local_data_store.dart';
import '../services/workout_snapshot_codec.dart';
import '../services/usage_events.dart';

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

  static const _nameKey = 'display_name';
  static const _illustrationStyleKey = 'illustration_style';
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _unitKey = 'weight_unit';
  static const _distanceUnitKey = 'distance_unit';
  static const _incrementKey = 'weight_increment';
  static const _proPreviewKey = 'pro_preview_enabled';
  static const _languageKey = 'language_code';
  static const _largeTextKey = 'accessibility_large_text';
  static const _highContrastKey = 'accessibility_high_contrast';
  static const _analyticsConsentKey = 'analytics_consent_v2';
  static const _reviewBuild = bool.fromEnvironment('GYM_IS_REVIEW',
      defaultValue: false);
  static String _prefKey(String key) => _reviewBuild ? 'review_$key' : key;

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
  bool isPro = false; // opt-in preview only; not a paid subscription
  String languageCode = 'system';
  bool largeText = false;
  bool highContrast = false;

  final List<Machine> _machines;
  final List<CardioActivity> _cardioActivities;
  final Map<String, List<CardioRecord>> _preservedCardio = {};
  final Set<String> _favoriteMachineIds = {};
  String? activeSessionId;
  final Map<String, String> sessionNames = {};
  final Map<String, List<String>> sessionExercises = {};
  final Map<String, double> targetWeights = {};

  void setTargetWeight(String machineId, double? kg) {
    if (kg == null) {
      targetWeights.remove(machineId);
    } else if (kg.isFinite && kg > 0 && kg <= 10000) {
      targetWeights[machineId] = kg;
    } else {
      return;
    }
    notifyListeners();
    _scheduleSave();
  }

  bool get hasActiveSession => activeSessionId != null;
  String get currentSessionName => sessionNames[activeSessionId] ?? 'Treino livre';

  /// Unique IDs distinguish independent sessions on the same day.
  String startSession({String name = 'Treino livre'}) {
    if (activeSessionId != null) return activeSessionId!;
    final id = 'session_${DateTime.now().microsecondsSinceEpoch}';
    activeSessionId = id;
    sessionNames[id] = name.trim().isEmpty ? 'Treino livre' : name.trim();
    sessionExercises[id] = <String>[];
    notifyListeners();
    _scheduleSave();
    return id;
  }

  void addExerciseToSession(Machine machine) {
    final id = activeSessionId ?? startSession();
    final plan = sessionExercises.putIfAbsent(id, () => <String>[]);
    if (!plan.contains(machine.id)) plan.add(machine.id);
    ensureMachineAdded(machine);
    notifyListeners();
    _scheduleSave();
  }

  void finishSession() {
    if (activeSessionId == null) return;
    activeSessionId = null;
    notifyListeners();
    _scheduleSave();
  }

  List<Machine> get activeSessionMachines {
    final id = activeSessionId;
    if (id == null) return const <Machine>[];
    final planned = sessionExercises[id] ?? const <String>[];
    return _machines.where((m) =>
      planned.contains(m.id) || m.records.any((r) => r.sessionId == id)
    ).toList(growable: false);
  }

  Set<String> get favoriteMachineIds => Set<String>.unmodifiable(_favoriteMachineIds);

  bool isFavorite(String id) => _favoriteMachineIds.contains(id);

  void toggleFavorite(String id) {
    if (!_favoriteMachineIds.add(id)) _favoriteMachineIds.remove(id);
    notifyListeners();
    _scheduleSave();
  }

  List<Machine> get favoriteMachines =>
      availableMachines.where((m) => isFavorite(m.id)).toList(growable: false);

  List<Machine> get todaysMachines {
    final day = WorkoutRecord.dayKey(DateTime.now());
    return _machines.where((machine) => machine.records.any(
      (record) => WorkoutRecord.dayKey(record.date) == day,
    )).toList(growable: false);
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
      displayName = (await preferences.getString(_prefKey(_nameKey)))?.trim() ?? '';
      illustrationStyle = illustrationStyleFromStorage(
        await preferences.getString(_prefKey(_illustrationStyleKey)),
      );
      _onboardingCompleted =
          await preferences.getBool(_prefKey(_onboardingCompleteKey)) ?? false;
      unit = await preferences.getString(_prefKey(_unitKey)) ?? 'kg';
      distanceUnit = await preferences.getString(_prefKey(_distanceUnitKey)) ?? 'km';
      increment = await preferences.getDouble(_prefKey(_incrementKey)) ?? 2.5;
      isPro = await preferences.getBool(_prefKey(_proPreviewKey)) ?? false;
      languageCode = await preferences.getString(_prefKey(_languageKey)) ?? 'system';
      largeText = await preferences.getBool(_prefKey(_largeTextKey)) ?? false;
      highContrast = await preferences.getBool(_prefKey(_highContrastKey)) ?? false;
      analyticsConsent = await preferences.getBool(_prefKey(_analyticsConsentKey)) ?? false;
    }
    final store = _store;
    if (store != null) {
      try {
        final snapshot = await store.load();
        if (snapshot != null) {
          final restored = WorkoutSnapshotCodec.decode(snapshot);
          _favoriteMachineIds
            ..clear()
            ..addAll(restored.favorites);
          activeSessionId = restored.activeSessionId;
          sessionNames
            ..clear()
            ..addAll(restored.sessionNames);
          sessionExercises
            ..clear()
            ..addAll(restored.sessionExercises);
          targetWeights
            ..clear()
            ..addAll(restored.targetWeights);
          _preservedCardio
            ..clear()
            ..addAll(restored.applyTo(_machines, _cardioActivities));
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
    notifyListeners();
    trackUsage('app_opened');
  }

  void _scheduleSave() {
    final store = _store;
    if (store == null || _failedToReadStorage) return;
    final snapshot = WorkoutSnapshotCodec.encode(
      machines: _machines,
      cardioActivities: _cardioActivities,
      preservedCardio: _preservedCardio,
      favorites: _favoriteMachineIds,
      activeSessionId: activeSessionId,
      sessionNames: sessionNames,
      sessionExercises: sessionExercises,
      targetWeights: targetWeights,
    );
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

  String exportBackup() => const JsonEncoder.withIndent('  ').convert(
        WorkoutSnapshotCodec.encode(
          machines: _machines,
          cardioActivities: _cardioActivities,
          preservedCardio: _preservedCardio,
          favorites: _favoriteMachineIds,
          activeSessionId: activeSessionId,
          sessionNames: sessionNames,
          sessionExercises: sessionExercises,
          targetWeights: targetWeights,
        ),
      );

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
    _favoriteMachineIds
      ..clear()
      ..addAll(restored.favorites);
    activeSessionId = restored.activeSessionId;
    sessionNames
      ..clear()
      ..addAll(restored.sessionNames);
    sessionExercises
      ..clear()
      ..addAll(restored.sessionExercises);
    targetWeights
      ..clear()
      ..addAll(restored.targetWeights);
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
    unawaited(preferences.setString(_prefKey(key), value));
  }

  void _saveBool(String key, bool value) {
    final preferences = _preferences;
    if (!persistenceEnabled || preferences == null) return;
    unawaited(preferences.setBool(_prefKey(key), value));
  }

  void _saveDouble(String key, double value) {
    final preferences = _preferences;
    if (!persistenceEnabled || preferences == null) return;
    unawaited(preferences.setDouble(_prefKey(key), value));
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

  void setHighContrast(bool value) {
    highContrast = value;
    _saveBool(_highContrastKey, value);
    notifyListeners();
  }

  void setLargeText(bool value) {
    largeText = value;
    _saveBool(_largeTextKey, value);
    notifyListeners();
  }

  void setLanguageCode(String value) {
    languageCode = value;
    notifyListeners();
    _saveString(_languageKey, value);
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
    _favoriteMachineIds.remove(machine.id);
    _machines.remove(machine);
    notifyListeners();
    _scheduleSave();
  }

  void updateMachineAdjustments(Machine machine, Map<String, String> fields) {
    machine.adjustments
      ..clear()
      ..addAll(fields.map((key, value) => MapEntry(key, value.trim()))
          ..removeWhere((key, value) => value.isEmpty));
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

  static int _recordSequence = 0;

  WorkoutRecord addRecord(Machine machine, {
    double weight = 0, int? repetitions, int? durationSeconds,
    bool isWarmup = false, double? rpe, String note = '',
  }) {
    final now = DateTime.now();
    final record = WorkoutRecord(
      id: 'set_${now.microsecondsSinceEpoch}_${_recordSequence++}',
      sessionId: activeSessionId ?? WorkoutRecord.dayKey(now),
      date: now,
      weight: weight,
      repetitions: repetitions,
      durationSeconds: durationSeconds,
      isWarmup: isWarmup,
      rpe: rpe,
      note: note,
    );
    machine.records.add(record);
    if (activeSessionId != null) {
      final plan = sessionExercises.putIfAbsent(activeSessionId!, () => <String>[]);
      if (!plan.contains(machine.id)) plan.add(machine.id);
    }
    notifyListeners();
    _scheduleSave();
    trackUsage('strength_record_created', {
      'group': machine.group.name,
      'exercise': machine.isCustom ? 'custom' : machine.id,
    });
    return record;
  }

  bool updateRecord(Machine machine, WorkoutRecord original, WorkoutRecord updated) {
    final index = machine.records.indexOf(original);
    if (index < 0) return false;
    machine.records[index] = updated;
    notifyListeners();
    _scheduleSave();
    return true;
  }

  bool removeRecord(Machine machine, WorkoutRecord record) {
    final removed = machine.records.remove(record);
    if (removed) {
      notifyListeners();
      _scheduleSave();
    }
    return removed;
  }

  void restoreRecord(Machine machine, WorkoutRecord record) {
    if (machine.records.any((r) => identical(r, record) ||
        (r.id.isNotEmpty && r.id == record.id))) return;
    machine.records.add(record);
    notifyListeners();
    _scheduleSave();
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
