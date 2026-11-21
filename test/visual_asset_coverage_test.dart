import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/models/muscle_group.dart';
import 'package:gymrecords/models/user_profile.dart';
import 'package:gymrecords/services/illustration_assets.dart';

void main() {
  test('biblioteca legada de imagens atende catalogo em todas as aparencias', () {
    final exercises = buildExerciseCatalog();
    expect(exercises.length, 124);
    for (final style in IllustrationStyle.values) {
      expect(File(IllustrationAssets.onboarding(style)).existsSync(), isTrue,
          reason: 'Onboarding sem recurso para ${style.name}');
      for (final group in MuscleGroup.values) {
        final path = IllustrationAssets.group(group, style);
        expect(File(path).existsSync(), isTrue, reason: path);
      }
      for (final exercise in exercises) {
        final execution = IllustrationAssets.exercise(exercise, style);
        final anatomy = IllustrationAssets.muscle(exercise, style);
        expect(File(execution).existsSync(), isTrue,
            reason: 'Imagem ausente para ${exercise.id}: $execution');
        expect(File(anatomy).existsSync(), isTrue,
            reason: 'Anatomia ausente para ${exercise.id}: $anatomy');
      }
    }
    expect(File('assets/branding/icon_blue.png').existsSync(), isTrue);
    expect(File('assets/branding/pro_mascot.webp').existsSync(), isTrue);
  });
}
