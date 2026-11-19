import 'dart:ui';

enum MuscleGroup {
  chest('Peito', 'Chest', 'Pecho', 'chest', 17),
  back('Costas', 'Back', 'Espalda', 'back', 18),
  legs('Pernas', 'Legs', 'Piernas', 'legs', 34),
  shoulders('Ombros', 'Shoulders', 'Hombros', 'shoulders', 15),
  biceps('Bíceps', 'Biceps', 'Bíceps', 'biceps', 13),
  triceps('Tríceps', 'Triceps', 'Tríceps', 'triceps', 13),
  abs('Abdômen', 'Core', 'Core', 'abs', 14);

  const MuscleGroup(this.label, this.labelEn, this.labelEs, this.assetKey, this.catalogCount);

  final String label;
  final String labelEn;
  final String labelEs;
  final String assetKey;
  final int catalogCount;

  String localizedLabel(Locale locale) => switch (locale.languageCode) {
        'en' => labelEn,
        'es' => labelEs,
        _ => label,
      };
}
