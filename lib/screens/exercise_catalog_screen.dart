import 'package:material_ui/material_ui.dart';

import '../models/muscle_group.dart';
import '../models/machine.dart';
import '../state/app_controller.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_header.dart';
import '../widgets/gym_bottom_navigation.dart';
import '../widgets/machine_list_card.dart';
import '../widgets/page_body.dart';
import 'machine_screen.dart';

/// Full native catalog with the same images, typography, search and cards.
class ExerciseCatalogScreen extends StatefulWidget {
  /// Picker mode returns the chosen machine to the active workout Home.
  const ExerciseCatalogScreen({super.key, this.pickForWorkout = false,
    this.showBottomNav = true, this.preferredGroupIds = const []});
  final bool pickForWorkout;
  final bool showBottomNav;
  final List<String> preferredGroupIds;

  @override
  State<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends State<ExerciseCatalogScreen> {
  String _query = '';
  MuscleGroup? _group;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final locale = Localizations.localeOf(context);
    final normalized = _query.trim().toLowerCase();
    final matches = app.availableMachines.where((m) {
      if (_group != null && m.group != _group) return false;
      if (_group == null && widget.pickForWorkout && !_showAll &&
          widget.preferredGroupIds.isNotEmpty &&
          !widget.preferredGroupIds.contains(m.group.name)) return false;
      if (normalized.isEmpty) return true;
      return m.localizedName(locale).toLowerCase().contains(normalized) ||
        m.group.localizedLabel(locale).toLowerCase().contains(normalized) ||
        m.aliases.any((x) => x.toLowerCase().contains(normalized));
    }).toList()..sort((a,b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      bottomNavigationBar: widget.pickForWorkout || !widget.showBottomNav
        ? null : const GymBottomNavigation(index: 1),
      appBar: widget.pickForWorkout
        ? AppBar(title: Text(context.strings.t('Adicionar exercício',
            'Add exercise', 'Añadir ejercicio')))
        : null,
      body: PageBody(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          if (!widget.pickForWorkout) ...[
            const BrandHeader(compact: true),
            const SizedBox(height: 18),
          ],
          Text(widget.pickForWorkout
              ? context.strings.t('Escolha um exercício', 'Choose an exercise', 'Elige un ejercicio')
              : context.strings.t('Exercícios', 'Exercises', 'Ejercicios'),
            style: Theme.of(context).textTheme.headlineMedium),
          if (widget.pickForWorkout) ...[
            const SizedBox(height: 5),
            Text(context.strings.t('Toque no exercício para adicionar ao treino atual.',
              'Tap an exercise to add it to your workout.',
              'Toca un ejercicio para añadirlo al entrenamiento.'),
              style: const TextStyle(color: AppTheme.iceBlue, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          TextField(
            key: const Key('catalog_search'),
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: context.strings.t('Buscar exercício ou aparelho', 'Search exercise or equipment', 'Buscar ejercicio o equipo'),
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: Row(children: [
              if (widget.pickForWorkout && widget.preferredGroupIds.isNotEmpty) ...[
                ChoiceChip(
                  key: const Key('catalog_preferred_groups'),
                  label: Text(context.strings.t('Grupos do treino',
                    'Workout groups', 'Grupos del entrenamiento')),
                  selected: _group == null && !_showAll,
                  onSelected: (_) => setState(() {
                    _group = null; _showAll = false;
                  })),
                const SizedBox(width: 8),
              ],
              ChoiceChip(label: Text(context.strings.all),
                selected: _group == null && (_showAll ||
                  widget.preferredGroupIds.isEmpty || !widget.pickForWorkout),
                onSelected: (_) => setState(() {
                  _group = null; _showAll = true;
                })),
              const SizedBox(width: 8),
              for (final group in MuscleGroup.values) ...[
                ChoiceChip(
                  label: Text(group.localizedLabel(locale)),
                  selected: _group == group,
                  onSelected: (_) => setState(() {
                    _group = group; _showAll = false;
                  })),
                const SizedBox(width: 8),
              ],
            ]),
          ),
          const SizedBox(height: 10),
          Text('${matches.length} ${context.strings.t('exercícios', 'exercises', 'ejercicios')}',
            style: const TextStyle(color: AppTheme.iceBlue)),
          const SizedBox(height: 8),
          Expanded(child: matches.isEmpty
            ? Center(child: Text(context.strings.t('Nenhum exercício encontrado.', 'No exercises found.', 'No se encontraron ejercicios.'),
                style: const TextStyle(color: AppTheme.iceBlue)))
            : ListView.separated(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: matches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final machine = matches[i];
                  return MachineListCard(
                    machine: machine,
                    unit: app.unit,
                    onTap: () {
                      final saved = app.ensureMachineAdded(machine);
                      // Only picker mode means the user requested inclusion.
                      if (widget.pickForWorkout) {
                        if (app.activeSession != null) {
                          app.addExerciseToSession(saved);
                        }
                        Navigator.of(context).pop<Machine>(saved);
                        return;
                      }
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => MachineScreen(machineId: saved.id)));
                    },
                  );
                })),
        ],
      )),
    );
  }
}
