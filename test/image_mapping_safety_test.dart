import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/models/user_profile.dart';
import 'package:gymrecords/services/illustration_assets.dart';

void main() {
  final catalog = {for (final e in buildExerciseCatalog()) e.id: e};

  test('treinos livres não exibem máquina errada como execução validada', () {
    for (final id in [
      'barbell_squat',
      'front_squat',
      'goblet_squat',
      'romanian_deadlift',
      'stiff_leg_deadlift',
      'deadlift',
      'barbell_bench_press',
      'barbell_row',
    ]) {
      expect(IllustrationAssets.needsExecutionArtworkReview(catalog[id]!),
          isTrue, reason: 'Imagem compartilhada incorreta: $id');
    }
  });

  test('prancha e variações sem desenho exato estão sinalizadas', () {
    for (final id in [
      'side_plank',
      'ab_wheel',
      'captain_chair_raise',
      'hanging_knee_raise',
      'dead_bug',
    ]) {
      expect(IllustrationAssets.needsExecutionArtworkReview(catalog[id]!),
          isTrue, reason: id);
    }
    for (final id in ['crunch', 'reverse_crunch', 'hanging_leg_raise', 'plank']) {
      expect(IllustrationAssets.needsExecutionArtworkReview(catalog[id]!),
          isFalse, reason: id);
    }
  });

  test('execução e anatomia preservam perfil sem trocar de pessoa', () {
    for (final style in IllustrationStyle.values) {
      for (final exercise in buildExerciseCatalog()) {
        final execution = IllustrationAssets.exercise(exercise, style);
        final anatomy = IllustrationAssets.muscle(exercise, style);
        expect(execution, contains('/${style.assetFolder}/'));
        expect(anatomy, contains('/${style.assetFolder}/'));
        expect(execution, isNot(anatomy));
      }
    }
  });
}
