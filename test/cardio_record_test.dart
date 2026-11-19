import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/models/cardio_achievement.dart';
import 'package:gymrecords/models/cardio_record.dart';
import 'package:gymrecords/state/app_controller.dart';

void main() {
  test('primeiro cardio estabelece um PR', () {
    final controller = AppController(persistenceEnabled: false);
    final jumpRope = controller.cardioActivities.firstWhere((a) => a.id == 'jump_rope');

    final achievement = controller.addCardioRecord(
      jumpRope,
      CardioRecord(date: DateTime(2026, 11, 17), duration: const Duration(minutes: 12)),
    );

    expect(achievement, isNotNull);
    expect(achievement!.primary.type, CardioAchievementType.duration);
  });

  test('pace menor dispara recorde de corrida', () {
    final controller = AppController(persistenceEnabled: false);
    final run = controller.cardioActivities.firstWhere((a) => a.id == 'outdoor_run');

    final achievement = controller.addCardioRecord(
      run,
      CardioRecord(
        date: DateTime(2026, 11, 17),
        duration: const Duration(minutes: 25),
        distanceKm: 5,
      ),
    );

    expect(achievement, isNotNull);
    expect(achievement!.metrics.any((m) => m.type == CardioAchievementType.pace), isTrue);
  });

  test('registro sem melhora não dispara conquista', () {
    final controller = AppController(persistenceEnabled: false);
    final run = controller.cardioActivities.firstWhere((a) => a.id == 'outdoor_run');

    final achievement = controller.addCardioRecord(
      run,
      CardioRecord(
        date: DateTime(2026, 11, 17),
        duration: const Duration(minutes: 28),
        distanceKm: 5,
      ),
    );

    expect(achievement, isNull);
  });
}
