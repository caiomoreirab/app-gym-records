import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'usage_events.dart';

/// Firebase analytics is completely optional. No Firebase app is initialized
/// until all options exist AND the user opted in. Never put server secrets here.
///
/// Values are platform public app identifiers passed via --dart-define.
/// Real collection stays disabled in local/preview builds without these values.
class FirebaseUsageSink implements ConsentAwareUsageEventSink {
  static const apiKey = String.fromEnvironment('GYM_FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('GYM_FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment('GYM_FIREBASE_SENDER_ID');
  static const projectId = String.fromEnvironment('GYM_FIREBASE_PROJECT_ID');
  static const measurementId = String.fromEnvironment('GYM_FIREBASE_MEASUREMENT_ID');

  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      senderId.isNotEmpty &&
      projectId.isNotEmpty &&
      (!kIsWeb || measurementId.isNotEmpty);

  bool _initialized = false;
  bool _enabled = false;

  @override
  Future<void> setEnabled(bool value) async {
    if (!isConfigured) {
      _enabled = false;
      return;
    }
    try {
      if (!_initialized && !value) return;
      if (!_initialized) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            messagingSenderId: senderId,
            projectId: projectId,
            measurementId: measurementId.isEmpty ? null : measurementId,
          ),
        );
        _initialized = true;
      }
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(value);
      _enabled = value;
    } catch (error) {
      _enabled = false;
      debugPrint('GymRecords: analytics unavailable: $error');
    }
  }

  @override
  Future<void> track(String event, Map<String, String> attributes) async {
    if (!_enabled || !_initialized) return;
    // The caller supplies only a closed vocabulary of anonymous event names
    // and categorical parameters. No notes, weights or names are passed in.
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: event,
        parameters: <String, Object>{...attributes},
      );
    } catch (error) {
      debugPrint('GymRecords: failed to log analytics event: $error');
    }
  }
}
