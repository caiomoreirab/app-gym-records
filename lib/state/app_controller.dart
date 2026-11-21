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
  bool isPro = false; // Only a preview, never a real subscription.
  String languageCode = 'system';

  final List<Machine> _machines;
  final List<CardioActivity> _cardioActivities;
  final Map<String, List<CardioRecord>> _preservedCardio = {};
  final Set<String> _favoriteIds = <String>{};
  int _sequence = 0;

  bool get onboardingComplete =>
      _onboardingCompleted &&
      displayName.trim().isNotEmpty &&
      illustrationStyle != null;

  IllustrationStyle get effectiveIllustrationStyle =>
      illustrationStyle ?? IllustrationStyle.masculine;

  Locale? get appLocale => languageCode == 'system' ? null : Locale(languageCode);

  List<CardioActivity> get cardioActivities => List<CardioActivity>.unmodifiable(_cardioActivities);

  List<Machine> get machines => List<Machine>.unmodifiable(_machines);

  bool isFavorite(String id) => _favoriteIds.contains(id);
  Set<String> get favoriteIds => Set<String>.unmodifiable(_favoriteIds);
  List<Machine> get favoriteMachines => availableMachines
      .where((machine) => _favoriteIds.contains(machine.id)).toList();

  void toggleFavorite(String id) {
    if (!_favoriteIds.add(id)) _favoriteIds.remove(id);
    notifyListeners();
    _scheduleSave();
  }

  List<WorkoutRecord> todaysSets(Machine machine, {DateTime? today}) {
    final current = today ?? DateTime.now();
    final key = WorkoutRecord.sessionForDay(current);
    return machine.records.where((r) => r.effectiveSessionId == key).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Machine> get todaysMachines => _machines
      .where((m) => todaysSets(m).isNotEmpty).toList(growable: false);

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
      displayName = (await preferences.getString(_nameKey))?.trim() ?? '';
      illustrationStyle = illustrationStyleFromStorage(
        await preferences.getString(_illustrationStyleKey),
      );
      _onboardingCompleted =
          await preferences.getBool(_onboardingCompleteKey) ?? false;
      unit = await preferences.getString(_unitKey) ?? 'kg';
      distanceUnit = await preferences.getString(_distanceUnitKey) ?? 'km';
      increment = await preferences.getDouble(_incrementKey) ?? 2.5;
      isPro = await preferences.getBool(_proPreviewKey) ?? false;
      languageCode = await preferences.getString(_languageKey) ?? 'system';
      analyticsConsent = await preferences.getBool(_analyticsConsentKey) ?? false;
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
          _favoriteIds
            ..clear()
            ..addAll(restored.favorites);
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
      favorites: _favoriteIds,
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
          favorites: _favoriteIds,
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
    _favoriteIds
      ..clear()
      ..addAll(restored.favorites);
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
    unawaited(preferences.setString(key, value));
  }

  void _saveBool(String key, bool value) {
    final preferences = _preferences;
    if (!persistenceEnabled || preferences == null) return;
    unawaited(preferences.setBool(key, value));
  }

  void _saveDouble(String key, double value) {
    final preferences = _preferences;
    if (!persistenceEnabled || preferences == null) return;
    unawaited(preferences.setDouble(key, value));
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

  WorkoutRecord addRecord(
    Machine machine, {
    double weight = 0,
    int? repetitions,
    int? durationSeconds,
    bool isWarmup = false,
    int? rpe,
    String note = '',
    DateTime? at,
  }) {
    if (!weight.isFinite || weight < 0 || (repetitions != null && repetitions < 0) ||
        (durationSeconds != null && durationSeconds < 0) ||
        (rpe != null && (rpe < 1 || rpe > 10))) {
      throw ArgumentError('Valores de série inválidos.');
    }
    final now = at ?? DateTime.now();
    final record = WorkoutRecord(
      id: 'set-${now.microsecondsSinceEpoch}-${_sequence++}',
      sessionId: WorkoutRecord.sessionForDay(now),
      date: now,
      weight: weight,
      repetitions: repetitions,
      durationSeconds: durationSeconds,
      isWarmup: isWarmup,
      rpe: rpe,
      note: note,
    );
    machine.records.add(record);
    notifyListeners();
    _scheduleSave();
    trackUsage('strength_record_created', {
      'group': machine.group.name,
      'exercise': machine.isCustom ? 'custom' : machine.id,
    });
    return record;
  }

  /// All modifications use the same queue and snapshot-based local storage.
  /// A legacy record may lack an ID, so in-memory identity is used too.
  void editRecord(Machine machine, WorkoutRecord original, WorkoutRecord updated) {
    final index = machine.records.indexOf(original);
    if (index < 0) throw StateError('Série não encontrada.');
    machine.records[index] = updated;
    notifyListeners();
    _scheduleSave();
  }

  int deleteRecord(Machine machine, WorkoutRecord record) {
    final index = machine.records.indexOf(record);
    if (index < 0) throw StateError('Série não encontrada.');
    machine.records.removeAt(index);
    notifyListeners();
    _scheduleSave();
    return index;
  }

  void restoreRecord(Machine machine, WorkoutRecord record, int index) {
    if (machine.records.any((r) => identical(r, record) ||
        (r.id != null && r.id == record.id))) return;
    machine.records.insert(index.clamp(0, machine.records.length), record);
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
