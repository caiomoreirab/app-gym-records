import 'dart:async';

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

class AppController extends ChangeNotifier {
  AppController({this.persistenceEnabled = true})
      : _machines = buildInitialMachines(),
        _cardioActivities = buildInitialCardioActivities(),
        _preferences = persistenceEnabled ? SharedPreferencesAsync() : null;

  static const _nameKey = 'display_name';
  static const _illustrationStyleKey = 'illustration_style';
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _unitKey = 'weight_unit';
  static const _distanceUnitKey = 'distance_unit';
  static const _incrementKey = 'weight_increment';
  static const _proPreviewKey = 'pro_preview_enabled';
  static const _languageKey = 'language_code';

  final bool persistenceEnabled;
  final SharedPreferencesAsync? _preferences;
  bool _onboardingCompleted = false;

  String displayName = '';
  IllustrationStyle? illustrationStyle;
  String unit = 'kg';
  String distanceUnit = 'km';
  double increment = 2.5;
  bool isPro = true; // front-end preview; billing will replace this flag later
  String languageCode = 'system';

  final List<Machine> _machines;
  final List<CardioActivity> _cardioActivities;

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
    if (hasMachine(machine.id)) return machineById(machine.id);
    _machines.add(machine);
    notifyListeners();
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
    if (!persistenceEnabled || preferences == null) return;
    displayName = (await preferences.getString(_nameKey))?.trim() ?? '';
    illustrationStyle = illustrationStyleFromStorage(
      await preferences.getString(_illustrationStyleKey),
    );
    _onboardingCompleted =
        await preferences.getBool(_onboardingCompleteKey) ?? false;
    unit = await preferences.getString(_unitKey) ?? 'kg';
    distanceUnit = await preferences.getString(_distanceUnitKey) ?? 'km';
    increment = await preferences.getDouble(_incrementKey) ?? 2.5;
    isPro = await preferences.getBool(_proPreviewKey) ?? true;
    languageCode = await preferences.getString(_languageKey) ?? 'system';
    notifyListeners();
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
  }

  void renameMachine(Machine machine, String name) {
    machine.name = name.trim();
    machine.nameEn = machine.name;
    notifyListeners();
  }

  void deleteMachine(Machine machine) {
    _machines.remove(machine);
    notifyListeners();
  }

  void updateMachineNote(Machine machine, String note) {
    machine.note = note.trim();
    notifyListeners();
  }

  CardioAchievement? addCardioRecord(CardioActivity activity, CardioRecord record) {
    final hadPrevious = activity.records.isNotEmpty;
    final previousDistance = activity.longestDistanceKm;
    final previousDurationSeconds = activity.longestDuration.inSeconds.toDouble();
    final previousPace = activity.bestPaceMinutes;
    final previousSpeed = activity.fastestSpeedKmh;

    activity.records.add(record);
    notifyListeners();

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

  void addRecord(Machine machine, {double weight = 0, int? repetitions, int? durationSeconds}) {
    machine.records.add(
      WorkoutRecord(
        date: DateTime.now(),
        weight: weight,
        repetitions: repetitions,
        durationSeconds: durationSeconds,
      ),
    );
    notifyListeners();
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
