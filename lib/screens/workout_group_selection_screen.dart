import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/machine.dart';
import '../models/muscle_group.dart';
import '../theme/app_theme.dart';
import '../widgets/cardio_group_card.dart';
import '../widgets/muscle_group_card.dart';
import '../widgets/page_body.dart';
import 'workout_exercise_selection_screen.dart';

/// An optional, reversible first step for a workout.
class WorkoutSetupResult {
  const WorkoutSetupResult({
    required this.groupIds,
    required this.exercises,
    required this.cardioIds,
  });
  final List<String> groupIds;
  final List<Machine> exercises;
  final List<String> cardioIds;
}

class WorkoutGroupSelectionScreen extends StatefulWidget {
  const WorkoutGroupSelectionScreen({
    super.key,
    this.initialGroupIds = const [],
    this.editing = false,
  });

  final List<String> initialGroupIds;
  final bool editing;

  @override
  State<WorkoutGroupSelectionScreen> createState() =>
      _WorkoutGroupSelectionScreenState();
}

class _WorkoutGroupSelectionScreenState
    extends State<WorkoutGroupSelectionScreen> {
  late final Set<String> _selected;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialGroupIds};
  }

  void _toggle(String id) {
    if (_navigating) return;
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  Future<void> _continue({bool skip = false}) async {
    if (_navigating) return;
    if (skip) setState(_selected.clear);
    final groups = [
      for (final group in MuscleGroup.values)
        if (_selected.contains(group.name)) group.name,
      if (_selected.contains('cardio')) 'cardio',
    ];
    if (widget.editing) {
      Navigator.of(context).pop<List<String>>(groups);
      return;
    }
    setState(() => _navigating = true);
    try {
      final result = await Navigator.of(context).push<WorkoutExerciseSelection>(
        MaterialPageRoute(
          builder: (_) => WorkoutExerciseSelectionScreen(selectedGroupIds: groups),
        ),
      );
      if (!mounted || result == null) return;
      Navigator.of(context).pop<WorkoutSetupResult>(WorkoutSetupResult(
        groupIds: groups,
        exercises: result.exercises,
        cardioIds: result.cardioIds,
      ));
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: Text(widget.editing
        ? context.strings.t('Grupos do treino', 'Workout groups',
            'Grupos del entrenamiento')
        : context.strings.t('Preparar treino', 'Plan workout',
            'Preparar entrenamiento'))),
      body: PageBody(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.editing
            ? context.strings.t('Quais grupos deseja treinar?',
              'Which groups do you want to train?', '¿Qué grupos vas a entrenar?')
            : context.strings.t('O que vamos treinar hoje?',
              'What are we training today?', '¿Qué entrenaremos hoy?'),
            style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 7),
          Text(context.strings.t(
            'Selecione um ou mais grupos. Você poderá alterar durante o treino.',
            'Choose one or more groups. You can change them during the workout.',
            'Elige uno o más grupos. Puedes cambiarlos durante el entrenamiento.'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.iceBlue, height: 1.3)),
          const SizedBox(height: 12),
          Text(context.strings.t(
            '${_selected.length} ${_selected.length == 1 ? 'grupo selecionado' : 'grupos selecionados'}',
            '${_selected.length} ${_selected.length == 1 ? 'group selected' : 'groups selected'}',
            '${_selected.length} ${_selected.length == 1 ? 'grupo seleccionado' : 'grupos seleccionados'}'),
            key: const Key('workout_group_count'),
            style: const TextStyle(color: AppTheme.electricLime,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(child: GridView.count(
            key: const Key('workout_group_grid'),
            crossAxisCount: 2,
            childAspectRatio: .88,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              for (final group in MuscleGroup.values)
                MuscleGroupCard(
                  key: Key('workout_group_${group.name}'),
                  group: group,
                  selected: _selected.contains(group.name),
                  onTap: () => _toggle(group.name),
                ),
              CardioGroupCard(
                key: const Key('workout_group_cardio'),
                selected: _selected.contains('cardio'),
                onTap: () => _toggle('cardio'),
              ),
            ],
          )),
        ],
      )),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: AppTheme.surfaceNavy,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FilledButton.icon(
              key: const Key('workout_groups_continue'),
              onPressed: _navigating || (!widget.editing && _selected.isEmpty)
                ? null : _continue,
              icon: Icon(widget.editing
                ? Icons.check_rounded : Icons.arrow_forward_rounded),
              label: Text(widget.editing
                ? context.strings.t('Salvar grupos', 'Save groups',
                  'Guardar grupos')
                : context.strings.t('Continuar', 'Continue', 'Continuar')),
            ),
            const SizedBox(height: 4),
            TextButton(
              key: const Key('workout_groups_skip'),
              onPressed: _navigating ? null : () => _continue(skip: true),
              child: Text(widget.editing
                ? context.strings.t('Mostrar todos os grupos',
                  'Show all groups', 'Mostrar todos los grupos')
                : context.strings.t('Seguir sem escolher grupos',
                  'Continue without choosing groups',
                  'Seguir sin elegir grupos')),
            ),
          ]),
        ),
      ),
    );
  }
}
