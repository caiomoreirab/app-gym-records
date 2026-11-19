import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  bool get isEnglish => locale.languageCode.toLowerCase() == 'en';
  bool get isSpanish => locale.languageCode.toLowerCase() == 'es';

  static const Map<String, String> _spanishFallback = {
    'Usuário': 'Usuario',
    'Registre sua execução': 'Registra tu entrenamiento',
    'Procure por grupo muscular, aparelho ou exercício': 'Busca por grupo muscular, máquina o ejercicio',
    'Todos': 'Todos',
    'Já registrados': 'Ya registrados',
    'Sem registros': 'Sin registros',
    'Acesso rápido': 'Acceso rápido',
    'Seus últimos exercícios registrados': 'Tus últimos ejercicios registrados',
    'Recentes': 'Recientes',
    'Grupos musculares': 'Grupos musculares',
    'Explore os exercícios por região': 'Explora los ejercicios por región',
    'Exercícios e aparelhos': 'Ejercicios y máquinas',
    'Corrida, caminhada, bike, remo e mais': 'Carrera, caminata, bici, remo y más',
    'Configurações': 'Configuración',
    'Continuar →': 'Continuar →',
    'Seja bem-vindo!': '¡Bienvenido!',
    'Adicionar exercício': 'Añadir ejercicio',
    'Atualizado em': 'Actualizado',
    'Buscar exercício ou aparelho...': 'Buscar ejercicio o máquina...',
    'Nenhum exercício encontrado': 'No se encontró ningún ejercicio',
    'Equipamento': 'Equipo',
    'Idioma': 'Idioma',
    'Sistema': 'Sistema',
    'Atividades de cardio': 'Actividades de cardio',
    'Registrar cardio': 'Registrar cardio',
    'Distância': 'Distancia',
    'Tempo': 'Tiempo',
    'Velocidade média': 'Velocidad media',
    'Frequência cardíaca': 'Frecuencia cardíaca',
    'Calorias': 'Calorías',
    'Inclinação': 'Inclinación',
    'Resistência / nível': 'Resistencia / nivel',
    'Observações': 'Observaciones',
    'Salvar registro': 'Guardar registro',
    'opcional': 'opcional',
    'Melhores marcas': 'Mejores marcas',
    'Maior distância': 'Mayor distancia',
    'Melhor pace': 'Mejor ritmo',
    'Maior duração': 'Mayor duración',
    'Ainda sem registros. Faça sua primeira atividade.': 'Aún no hay registros. Registra tu primera actividad.',
    'Exercício personalizado': 'Ejercicio personalizado',
    'Criar exercício personalizado': 'Crear ejercicio personalizado',
    'Seu nome ou apelido': 'Tu nombre o apodo',
    'Como você quer ser chamado?': '¿Cómo quieres que te llamemos?',
    'Informe seu nome ou apelido para personalizar sua experiência.': 'Indica tu nombre o apodo para personalizar tu experiencia.',
    'como você prefere visualizar os exercícios?': '¿cómo prefieres visualizar los ejercicios?',
    'Escolha o estilo das ilustrações. Você poderá alterar isso depois.': 'Elige el estilo de las ilustraciones. Podrás cambiarlo después.',
    'Aparência masculina': 'Apariencia masculina',
    'Aparência feminina': 'Apariencia femenina',
    'Ilustrações neutras': 'Ilustraciones neutras',
    'Ilustrações com características corporais masculinas.': 'Ilustraciones con características corporales masculinas.',
    'Ilustrações com características corporais femininas.': 'Ilustraciones con características corporales femeninas.',
    'Foco técnico no movimento e nos músculos.': 'Enfoque técnico en el movimiento y los músculos.',
    'Histórico': 'Historial',
    'Métricas opcionais': 'Métricas opcionales',
    'Minutos': 'Minutos',
    'Segundos': 'Segundos',
    'Cardio registrado.': 'Cardio registrado.',
    'Sessão cardiovascular': 'Sesión cardiovascular',
    'Buscar atividade...': 'Buscar actividad...',
    '9 atividades': '9 actividades',
    'Aplicar filtros': 'Aplicar filtros',
    'Maior recorde': 'Mayor récord',
    'Como você quer ser chamado': 'Cómo quieres que te llamemos',
    'Editar nome': 'Editar nombre',
    'Estilo das ilustrações': 'Estilo de las ilustraciones',
    'Altere como os exercícios são apresentados no app.': 'Cambia cómo se muestran los ejercicios en la app.',
    'O app pode seguir o idioma do sistema ou usar uma preferência fixa.': 'La app puede seguir el idioma del sistema o usar una preferencia fija.',
    'Unidade de peso': 'Unidad de peso',
    'Unidade de distância': 'Unidad de distancia',
    'Incremento padrão': 'Incremento predeterminado',
    'Dados e exportação': 'Datos y exportación',
    'Execução': 'Ejecución',
    'Músculos': 'Músculos',
    'Novo recorde!': '¡Nuevo récord!',
    'Compartilhe sua conquista': 'Comparte tu logro',
    'Compartilhar no WhatsApp': 'Compartir en WhatsApp',
    'Copiar link': 'Copiar enlace',
    'Agora não': 'Ahora no',
  };

  String t(String pt, String en, [String? es]) {
    if (isEnglish) return en;
    if (isSpanish) return es ?? _spanishFallback[pt] ?? pt;
    return pt;
  }

  String get user => t('Usuário', 'User', 'Usuario');
  String get registerExecution => t('Registre sua execução', 'Log your workout', 'Registra tu entrenamiento');
  String get searchHint => t(
        'Procure por grupo muscular, aparelho ou exercício',
        'Search muscle group, equipment or exercise',
        'Busca por grupo muscular, máquina o ejercicio',
      );
  String get all => t('Todos', 'All', 'Todos');
  String get recorded => t('Já registrados', 'Logged', 'Ya registrados');
  String get unrecorded => t('Sem registros', 'Not logged', 'Sin registros');
  String get quickAccess => t('Acesso rápido', 'Quick access', 'Acceso rápido');
  String get recentExercises => t(
        'Seus últimos exercícios registrados',
        'Your latest logged exercises',
        'Tus últimos ejercicios registrados',
      );
  String get recent => t('Recentes', 'Recent', 'Recientes');
  String get muscleGroups => t('Grupos musculares', 'Muscle groups', 'Grupos musculares');
  String get exploreByRegion => t(
        'Explore os exercícios por região',
        'Explore exercises by body region',
        'Explora los ejercicios por región',
      );
  String get exercisesAndEquipment => t('Exercícios e aparelhos', 'Exercises & equipment', 'Ejercicios y máquinas');
  String get cardio => 'Cardio';
  String get cardioSubtitle => t(
        'Corrida, caminhada, bike, remo e mais',
        'Running, walking, cycling, rowing and more',
        'Carrera, caminata, bici, remo y más',
      );
  String get settings => t('Configurações', 'Settings', 'Configuración');
  String get continueLabel => t('Continuar →', 'Continue →', 'Continuar →');
  String get welcome => t('Seja bem-vindo!', 'Welcome!', '¡Bienvenido!');
  String get addEquipment => t('Adicionar exercício', 'Add exercise', 'Añadir ejercicio');
  String get noRecords => t('Sem registros', 'No records', 'Sin registros');
  String get updatedOn => t('Atualizado em', 'Updated', 'Actualizado');
  String get searchExercise => t('Buscar exercício ou aparelho...', 'Search exercise or equipment...', 'Buscar ejercicio o máquina...');
  String get noExerciseFound => t('Nenhum exercício encontrado', 'No exercise found', 'No se encontró ningún ejercicio');
  String get equipmentType => t('Equipamento', 'Equipment', 'Equipo');
  String get language => t('Idioma', 'Language', 'Idioma');
  String get systemLanguage => t('Sistema', 'System', 'Sistema');
  String get portuguese => 'Português (Brasil)';
  String get english => 'English (US)';
  String get spanish => 'Español (España)';
  String get cardioActivities => t('Atividades de cardio', 'Cardio activities', 'Actividades de cardio');
  String get registerCardio => t('Registrar cardio', 'Log cardio', 'Registrar cardio');
  String get distance => t('Distância', 'Distance', 'Distancia');
  String get duration => t('Tempo', 'Duration', 'Tiempo');
  String get pace => isSpanish ? 'Ritmo' : 'Pace';
  String get avgSpeed => t('Velocidade média', 'Average speed', 'Velocidad media');
  String get heartRate => t('Frequência cardíaca', 'Heart rate', 'Frecuencia cardíaca');
  String get calories => t('Calorias', 'Calories', 'Calorías');
  String get incline => t('Inclinação', 'Incline', 'Inclinación');
  String get resistance => t('Resistência / nível', 'Resistance / level', 'Resistencia / nivel');
  String get notes => t('Observações', 'Notes', 'Observaciones');
  String get saveRecord => t('Salvar registro', 'Save record', 'Guardar registro');
  String get optional => t('opcional', 'optional', 'opcional');
  String get bestMarks => t('Melhores marcas', 'Personal bests', 'Mejores marcas');
  String get longestDistance => t('Maior distância', 'Longest distance', 'Mayor distancia');
  String get bestPace => t('Melhor pace', 'Best pace', 'Mejor ritmo');
  String get longestDuration => t('Maior duração', 'Longest duration', 'Mayor duración');
  String get noCardioYet => t(
        'Ainda sem registros. Faça sua primeira atividade.',
        'No records yet. Log your first activity.',
        'Aún no hay registros. Registra tu primera actividad.',
      );
  String get customExercise => t('Exercício personalizado', 'Custom exercise', 'Ejercicio personalizado');
  String get createCustomExercise => t('Criar exercício personalizado', 'Create custom exercise', 'Crear ejercicio personalizado');
  String get nameOrNickname => t('Seu nome ou apelido', 'Your name or nickname', 'Tu nombre o apodo');
  String get howCalled => t('Como você quer ser chamado?', 'What should we call you?', '¿Cómo quieres que te llamemos?');
  String get nameSubtitle => t(
        'Informe seu nome ou apelido para personalizar sua experiência.',
        'Enter your name or nickname to personalize your experience.',
        'Indica tu nombre o apodo para personalizar tu experiencia.',
      );
  String get illustrationPreference => t(
        'como você prefere visualizar os exercícios?',
        'how do you prefer to view exercises?',
        '¿cómo prefieres visualizar los ejercicios?',
      );
  String get illustrationSubtitle => t(
        'Escolha o estilo das ilustrações. Você poderá alterar isso depois.',
        'Choose the illustration style. You can change this later.',
        'Elige el estilo de las ilustraciones. Podrás cambiarlo después.',
      );
  String get masculine => t('Aparência masculina', 'Masculine appearance', 'Apariencia masculina');
  String get feminine => t('Aparência feminina', 'Feminine appearance', 'Apariencia femenina');
  String get neutral => t('Ilustrações neutras', 'Neutral illustrations', 'Ilustraciones neutras');
  String get masculineDesc => t(
        'Ilustrações com características corporais masculinas.',
        'Illustrations with masculine body characteristics.',
        'Ilustraciones con características corporales masculinas.',
      );
  String get feminineDesc => t(
        'Ilustrações com características corporais femininas.',
        'Illustrations with feminine body characteristics.',
        'Ilustraciones con características corporales femeninas.',
      );
  String get neutralDesc => t(
        'Foco técnico no movimento e nos músculos.',
        'Technical focus on movement and muscles.',
        'Enfoque técnico en el movimiento y los músculos.',
      );
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings(Localizations.localeOf(this));
}
