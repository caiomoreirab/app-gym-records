import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/cardio_activity.dart';
import '../models/machine.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/cardio_visual_pager.dart';
import '../widgets/machine_list_card.dart';
import '../widgets/page_body.dart';

class WorkoutExerciseSelection {
  const WorkoutExerciseSelection({
    required this.exercises,
    required this.cardioIds,
  });
  final List<Machine> exercises;
  final List<String> cardioIds;
}

/// Step two: multi-select catalog. No records or sessions are created here.
class WorkoutExerciseSelectionScreen extends StatefulWidget {
  const WorkoutExerciseSelectionScreen({
    super.key,
    required this.selectedGroupIds,
  });
  final List<String> selectedGroupIds;

  @override
  State<WorkoutExerciseSelectionScreen> createState() =>
      _WorkoutExerciseSelectionScreenState();
}

class _WorkoutExerciseSelectionScreenState
    extends State<WorkoutExerciseSelectionScreen> {
  final Set<String> _selectedExercises = {};
  final Set<String> _selectedCardio = {};
  bool _showAll = false;
  String _query = '';

  void _toggle(Set<String> target, String id) {
    setState(() {
      if (!target.add(id)) target.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final locale = Localizations.localeOf(context);
    final allMachines = app.availableMachines;
    final allCardio = app.cardioActivities;
    final query = _query.trim().toLowerCase();
    final allowed = widget.selectedGroupIds.toSet();
    final unrestricted = allowed.isEmpty || _showAll;
    final exercises = allMachines.where((item) =>
      (unrestricted || allowed.contains(item.group.name)) &&
      (query.isEmpty ||
        item.localizedName(locale).toLowerCase().contains(query) ||
        item.aliases.any((a) => a.toLowerCase().contains(query)) ||
        item.group.localizedLabel(locale).toLowerCase().contains(query))
    ).toList()..sort((a, b) =>
      a.localizedName(locale).compareTo(b.localizedName(locale)));
    final showCardio = unrestricted || allowed.contains('cardio');
    final List<CardioActivity> cardio = showCardio
      ? allCardio.where((a) => query.isEmpty ||
          a.localizedName(locale).toLowerCase().contains(query)).toList()
      : <CardioActivity>[];
    final count = _selectedExercises.length + _selectedCardio.length;

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(title: Text(context.strings.t(
        'Escolher exercícios', 'Choose exercises', 'Elegir ejercicios'))),
      body: PageBody(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.strings.t(
            'Monte seu treino', 'Build your workout', 'Arma tu entrenamiento'),
            style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(context.strings.t(
            'Marque os exercícios que fará. Você também pode adicioná-los durante o treino.',
            'Select your exercises. You can add more during your workout.',
            'Elige ejercicios. Puedes añadir más durante el entrenamiento.'),
            style: const TextStyle(color: AppTheme.iceBlue)),
          const SizedBox(height: 12),
          if (allowed.isNotEmpty) ...[
            Wrap(spacing: 8, runSpacing: 6, children: [
                ChoiceChip(
                  key: const Key('workout_exercises_filter_selected'),
                  label: Text(context.strings.t(
                    'Meus grupos', 'My groups', 'Mis grupos')),
                  selected: !_showAll,
                  onSelected: (_) => setState(() => _showAll = false)),
                ChoiceChip(
                  key: const Key('workout_exercises_filter_all'),
                  label: Text(context.strings.t('Todos', 'All', 'Todos')),
                  selected: _showAll,
                  onSelected: (_) => setState(() => _showAll = true)),
              ]),
            const SizedBox(height: 10),
          ],
          TextField(
            key: const Key('workout_exercises_search'),
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: context.strings.t('Buscar exercícios ou cardio',
                'Search exercises or cardio',
                'Buscar ejercicios o cardio'),
              prefixIcon: const Icon(Icons.search_rounded)),
          ),
          const SizedBox(height: 8),
          Text(context.strings.t(
            '$count atividades selecionadas',
            '$count activities selected',
            '$count actividades seleccionadas'),
            key: const Key('workout_exercises_selected_count'),
            style: const TextStyle(color: AppTheme.electricLime)),
          const SizedBox(height: 8),
          Expanded(child: ListView.builder(
            key: const Key('workout_exercises_list'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: exercises.length + (showCardio ? 1 + cardio.length : 0),
            itemBuilder: (context, i) {
              if (i < exercises.length) {
                final item = exercises[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MachineListCard(
                    key: Key('workout_pick_${item.id}'),
                    machine: item, unit: app.unit,
                    selectable: true,
                    selected: _selectedExercises.contains(item.id),
                    onTap: () => _toggle(_selectedExercises, item.id),
                  ),
                );
              }
              if (i == exercises.length) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                  child: Text(context.strings.t(
                    'Atividades de cardio', 'Cardio activities',
                    'Actividades de cardio'),
                    style: Theme.of(context).textTheme.titleLarge),
                );
              }
              final activity = cardio[i - exercises.length - 1];
              final selected = _selectedCardio.contains(activity.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: AppTheme.surfaceNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    side: BorderSide(
                      color: selected ? AppTheme.electricLime : AppTheme.deepBlue,
                      width: selected ? 2 : 1)),
                  clipBehavior: Clip.antiAlias,
                  child: Semantics(
                    selected: selected, button: true,
                    child: InkWell(
                      key: Key('workout_pick_cardio_${activity.id}'),
                      onTap: () => _toggle(_selectedCardio, activity.id),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          CardioVisualPager(
                            activity: activity, width: 68, height: 68,
                            fit: BoxFit.contain, compact: true),
                          const SizedBox(width: 12),
                          Expanded(child: Text(activity.localizedName(locale),
                            style: Theme.of(context).textTheme.titleMedium)),
                          Icon(selected ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                            color: selected ? AppTheme.electricLime
                              : AppTheme.iceBlue),
                        ]),
                      ),
                    ),
                  ),
                ),
              );
            },
          )),
        ],
      )),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          color: AppTheme.surfaceNavy,
          child: FilledButton.icon(
            key: const Key('workout_exercises_finish'),
            onPressed: () => Navigator.of(context).pop<WorkoutExerciseSelection>(
              WorkoutExerciseSelection(
                exercises: [for (final item in allMachines)
                  if (_selectedExercises.contains(item.id)) item],
                cardioIds: [for (final activity in allCardio)
                  if (_selectedCardio.contains(activity.id)) activity.id],
              )),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(count == 0
              ? context.strings.t('Começar sem exercícios',
                'Start without exercises', 'Comenzar sin ejercicios')
              : context.strings.t('Começar treino ($count)',
                'Start workout ($count)', 'Comenzar entrenamiento ($count)')),
          ),
        ),
      ),
    );
  }
}
