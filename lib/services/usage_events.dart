/// Categorical events used to understand feature adoption after explicit opt-in.
/// No network collection is enabled in the offline-first release. A Firebase
/// adapter may be installed later without changing the domain/controller APIs.
abstract class UsageEventSink {
  Future<void> track(String event, Map<String, String> attributes);
}

abstract class ConsentAwareUsageEventSink implements UsageEventSink {
  Future<void> setEnabled(bool enabled);
}

class DisabledUsageEventSink implements UsageEventSink {
  const DisabledUsageEventSink();

  @override
  Future<void> track(String event, Map<String, String> attributes) async {}
}

/// Development and automated tests only. Nothing is transmitted remotely.
class MemoryUsageEventSink implements UsageEventSink {
  final List<UsageEvent> events = <UsageEvent>[];

  @override
  Future<void> track(String event, Map<String, String> attributes) async {
    events.add(UsageEvent(event, Map<String, String>.unmodifiable(attributes)));
  }
}

class UsageEvent {
  const UsageEvent(this.name, this.attributes);
  final String name;
  final Map<String, String> attributes;
}

/// Events emitted by AppController:
/// app_opened, onboarding_completed, exercise_opened,
/// custom_exercise_created, strength_record_created, cardio_record_created.
///
/// No free-text notes, user identity, exact workout values, dates, or location
/// are included. Only activity or muscle-group identifiers are used.
