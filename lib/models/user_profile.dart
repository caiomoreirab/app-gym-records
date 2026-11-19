import 'dart:ui';

enum IllustrationStyle { masculine, feminine, neutral }

extension IllustrationStyleX on IllustrationStyle {
  String get storageValue => name;

  String get assetFolder => switch (this) {
        IllustrationStyle.masculine => 'masculine',
        IllustrationStyle.feminine => 'feminine',
        IllustrationStyle.neutral => 'neutral',
      };

  String labelFor(Locale locale) {
    final lang = locale.languageCode;
    return switch (this) {
      IllustrationStyle.masculine => lang == 'en'
          ? 'Masculine appearance'
          : lang == 'es'
              ? 'Apariencia masculina'
              : 'Aparência masculina',
      IllustrationStyle.feminine => lang == 'en'
          ? 'Feminine appearance'
          : lang == 'es'
              ? 'Apariencia femenina'
              : 'Aparência feminina',
      IllustrationStyle.neutral => lang == 'en'
          ? 'Neutral illustrations'
          : lang == 'es'
              ? 'Ilustraciones neutras'
              : 'Ilustrações neutras',
    };
  }

  String descriptionFor(Locale locale) {
    final lang = locale.languageCode;
    return switch (this) {
      IllustrationStyle.masculine => lang == 'en'
          ? 'Illustrations with masculine body characteristics.'
          : lang == 'es'
              ? 'Ilustraciones con características corporales masculinas.'
              : 'Ilustrações com características corporais masculinas.',
      IllustrationStyle.feminine => lang == 'en'
          ? 'Illustrations with feminine body characteristics.'
          : lang == 'es'
              ? 'Ilustraciones con características corporales femeninas.'
              : 'Ilustrações com características corporais femininas.',
      IllustrationStyle.neutral => lang == 'en'
          ? 'Technical focus on movement and muscles.'
          : lang == 'es'
              ? 'Enfoque técnico en el movimiento y los músculos.'
              : 'Foco técnico no movimento e nos músculos.',
    };
  }
}

IllustrationStyle? illustrationStyleFromStorage(String? value) {
  if (value == null) return null;
  for (final style in IllustrationStyle.values) {
    if (style.storageValue == value) return style;
  }
  return null;
}
