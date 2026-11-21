import 'package:material_ui/material_ui.dart';

import '../models/muscle_group.dart';
import '../models/machine.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_header.dart';
import '../widgets/gym_bottom_navigation.dart';
import '../widgets/machine_list_card.dart';
import '../widgets/page_body.dart';
import 'machine_screen.dart';

/// Full native catalog with the same images, typography, search and cards.
class ExerciseCatalogScreen extends StatefulWidget {
  /// Picker mode returns the chosen machine to the active workout Home.
  const ExerciseCatalogScreen({super.key, this.pickForWorkout = false});
  final bool pickForWorkout;

  @override
  State<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends State<ExerciseCatalogScreen> {
  String _query = '';
  MuscleGroup? _group;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final locale = Localizations.localeOf(context);
    final normalized = _query.trim().toLowerCase();
    final matches = app.availableMachines.where((m) {
      if (_group != null && m.group != _group) return false;
      if (normalized.isEmpty) return true;
      return m.localizedName(locale).toLowerCase().contains(normalized) ||
        m.group.localizedLabel(locale).toLowerCase().contains(normalized) ||
        m.aliases.any((x) => x.toLowerCase().contains(normalized));
    }).toList()..sort((a,b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      bottomNavigationBar: widget.pickForWorkout
        ? null : const GymBottomNavigation(index: 1),
      appBar: widget.pickForWorkout
        ? AppBar(title: const Text('Adicionar exercício'))
        : null,
      body: PageBody(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          if (!widget.pickForWorkout) ...[
            const BrandHeader(compact: true),
            const SizedBox(height: 18),
          ],
          Text(widget.pickForWorkout
              ? 'Escolha um aparelho' : 'Exercícios',
            style: Theme.of(context).textTheme.headlineMedium),
          if (widget.pickForWorkout) ...[
            const SizedBox(height: 5),
            const Text('Toque no exercício para adicionar ao treino atual.',
              style: TextStyle(color: AppTheme.iceBlue, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          TextField(
            key: const Key('catalog_search'),
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Buscar exercício ou aparelho',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: Row(children: [
              ChoiceChip(label: const Text('Todos'),
                selected: _group == null,
                onSelected: (_) => setState(() => _group = null)),
              const SizedBox(width: 8),
              for (final group in MuscleGroup.values) ...[
                ChoiceChip(
                  label: Text(group.localizedLabel(locale)),
                  selected: _group == group,
                  onSelected: (_) => setState(() => _group = group)),
                const SizedBox(width: 8),
              ],
            ]),
          ),
          const SizedBox(height: 10),
          Text('${matches.length} exercícios',
            style: const TextStyle(color: AppTheme.iceBlue)),
          const SizedBox(height: 8),
          Expanded(child: matches.isEmpty
            ? const Center(child: Text('Nenhum exercício encontrado.',
                style: TextStyle(color: AppTheme.iceBlue)))
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
                      if (app.activeSession != null) {
                        app.addExerciseToSession(saved);
                      }
                      if (widget.pickForWorkout) {
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
