import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/machine.dart';
import '../models/muscle_group.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../services/weight_units.dart';
import '../widgets/adaptive_illustration.dart';
import '../widgets/brand_header.dart';
import '../widgets/cardio_group_card.dart';
import '../widgets/machine_list_card.dart';
import '../widgets/muscle_group_card.dart';
import '../widgets/section_card.dart';
import '../widgets/gym_bottom_navigation.dart';
import '../widgets/page_body.dart';
import 'group_screen.dart';
import 'machine_screen.dart';
import 'settings_screen.dart';
import 'data_privacy_screen.dart';
import 'cardio_screen.dart';
import 'pro_overview_screen.dart';
import 'workout_completed_screen.dart';
import 'exercise_catalog_screen.dart';
import 'workout_live_screen.dart';

enum _RecordFilter { all, recorded, unrecorded }

enum _HomeSort { recent, alphabeticalAsc, alphabeticalDesc, recordDesc, muscleGroup }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _RecordFilter _recordFilter = _RecordFilter.all;
  _HomeSort _sort = _HomeSort.recent;
  bool _showAllExercises = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final allMachines = controller.availableMachines;
    final filteredMachines = _applyFilterAndSort(allMachines);
    final displayedMachines = (_showAllExercises || _hasCustomFilters)
        ? filteredMachines
        : filteredMachines.take(10).toList(growable: false);
    final recentMachines = controller.recentlyUsedMachines.take(4).toList();
    final searching = _query.trim().isNotEmpty;
    final matchedGroups = searching ? _matchingGroups() : <MuscleGroup>[];
    final searchResults = searching
        ? _applyFilterAndSort(
            allMachines.where(_matchesSearch).toList(growable: false),
          )
        : <Machine>[];
    final showCardioSearch = searching && _matchesCardioSearch();

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      bottomNavigationBar: const GymBottomNavigation(index: 0),
      body: PageBody(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            const SizedBox(height: 12),
            BrandHeader(
              compact: true,
              showPro: controller.isPro,
              trailing: IconButton(
                tooltip: context.strings.settings,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            if (controller.persistenceError != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceNavy,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orangeAccent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Problema no armazenamento local',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(context.strings.t(
                      'Não conseguimos garantir que seus registros estejam salvos. '
                      'Não limpe os dados do aplicativo.',
                      'Your workout history may not be saved. Do not clear app data.',
                      'No podemos garantizar que tus registros estén guardados. '
                      'No borres los datos de la aplicación.',
                    )),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DataPrivacyScreen(),
                        ),
                      ),
                      child: Text(context.strings.t(
                        'Abrir recuperação de dados',
                        'Open data recovery',
                        'Abrir recuperación de datos',
                      )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              controller.displayName.isEmpty ? context.strings.user : controller.displayName,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text(
              context.strings.registerExecution,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.iceBlue,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 18),
            TextField(
              key: const Key('globalExerciseSearch'),
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.strings.searchHint,
                hintStyle: const TextStyle(
                  color: AppTheme.iceBlue,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIconConstraints: const BoxConstraints(minWidth: 52),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_query.isNotEmpty)
                      IconButton(
                        tooltip: context.strings.t('Limpar busca', 'Clear search'),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          key: const Key('homeFilterButton'),
                          tooltip: context.strings.t('Filtrar e ordenar', 'Filter and sort'),
                          onPressed: _openFilters,
                          icon: const Icon(Icons.tune_rounded),
                        ),
                        if (_hasCustomFilters)
                          const Positioned(
                            right: 8,
                            top: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppTheme.electricLime,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox(width: 8, height: 8),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: context.strings.all,
                    selected: _recordFilter == _RecordFilter.all,
                    onTap: () => setState(() => _recordFilter = _RecordFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: context.strings.recorded,
                    selected: _recordFilter == _RecordFilter.recorded,
                    onTap: () => setState(
                      () => _recordFilter = _RecordFilter.recorded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: context.strings.unrecorded,
                    selected: _recordFilter == _RecordFilter.unrecorded,
                    onTap: () => setState(
                      () => _recordFilter = _RecordFilter.unrecorded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SortChip(
                    label: _sortLabel(context, _sort),
                    onTap: _openFilters,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            if (searching)
              _SearchContent(
                groups: matchedGroups,
                machines: searchResults,
                unit: controller.unit,
                onOpenGroup: (group) => _openGroup(context, group),
                onOpenMachine: (machine) {
                  if (controller.activeSession != null) {
                    final ready = controller.ensureMachineAdded(machine);
                    controller.addExerciseToSession(ready);
                  }
                  _openMachine(context, machine);
                },
                showCardio: showCardioSearch,
                onOpenCardio: () => _openCardio(context),
              )
            else ...[
              _TodayWorkoutCard(
                app: controller,
                onComplete: () => _finishWorkout(controller),
                onAddExercise: _addExerciseToWorkout,
                onStart: _startWorkout,
                onTrack: _openActiveWorkout,
                onOpenMachine: (machine) => _openMachine(context, machine),
              ),
              const SizedBox(height: 22),
              if (controller.favoriteMachines.isNotEmpty) ...[
                _SectionHeading(
                  title: 'Favoritos',
                  subtitle: 'Seus exercícios marcados',
                ),
                const SizedBox(height: 12),
                SizedBox(height: 194,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.favoriteMachines.take(8).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final machine = controller.favoriteMachines[index];
                      return _QuickMachineCard(
                        machine: machine,
                        unit: controller.unit,
                        onTap: () => _openMachine(context, machine));
                    },
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (recentMachines.isNotEmpty) ...[
                _SectionHeading(
                  title: context.strings.quickAccess,
                  subtitle: context.strings.recentExercises,
                  trailing: TextButton(
                    onPressed: () => setState(
                      () => _sort = _HomeSort.recent,
                    ),
                    child: Text(context.strings.recent),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 194,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recentMachines.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final machine = recentMachines[index];
                      return _QuickMachineCard(
                        machine: machine,
                        unit: controller.unit,
                        onTap: () => _openMachine(context, machine),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
              ],
              _HomeProCard(
                enabled: controller.isPro,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProOverviewScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _SectionHeading(
                title: context.strings.muscleGroups,
                subtitle: context.strings.exploreByRegion,
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.86,
                children: [
                  for (final group in MuscleGroup.values)
                    MuscleGroupCard(
                      group: group,
                      onTap: () => _openGroup(context, group),
                    ),
                  CardioGroupCard(onTap: () => _openCardio(context)),
                ],
              ),
              const SizedBox(height: 30),
              _SectionHeading(
                title: context.strings.exercisesAndEquipment,
                subtitle: _exerciseSectionSubtitle(filteredMachines.length),
              ),
              const SizedBox(height: 14),
              if (filteredMachines.isEmpty)
                const _EmptyMachineResults()
              else ...[
                for (var index = 0; index < displayedMachines.length; index++) ...[
                  MachineListCard(
                    machine: displayedMachines[index],
                    unit: controller.unit,
                    onTap: () => _openMachine(context, displayedMachines[index]),
                  ),
                  if (index != displayedMachines.length - 1) const SizedBox(height: 12),
                ],
                if (!_hasCustomFilters && filteredMachines.length > 10) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _showAllExercises = !_showAllExercises),
                    icon: Icon(_showAllExercises ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                    label: Text(_showAllExercises
                        ? context.strings.t('Mostrar menos', 'Show less')
                        : context.strings.t('Ver catálogo completo (${filteredMachines.length})', 'View full catalog (${filteredMachines.length})')),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _startWorkout() {
    final app = AppScope.of(context);
    app.startSession();
    _openActiveWorkout();
  }

  void _openActiveWorkout() {
    Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => const WorkoutLiveScreen(),
    ));
  }

  Future<void> _addExerciseToWorkout() async {
    final controller = AppScope.of(context);
    if (controller.activeSession == null) return;
    final chosen = await Navigator.of(context).push<Machine>(
      MaterialPageRoute<Machine>(
        builder: (_) => const ExerciseCatalogScreen(pickForWorkout: true),
      ),
    );
    if (!mounted || chosen == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.strings.t('${chosen.name} adicionado ao treino.', '${chosen.localizedName(Localizations.localeOf(context))} added to workout.', '${chosen.localizedName(Localizations.localeOf(context))} añadido al entrenamiento.')),
      action: SnackBarAction(
        label: context.strings.t('Registrar', 'Log', 'Registrar'),
        onPressed: () => _openMachine(context, chosen),
      ),
    ));
  }

  Future<void> _finishWorkout(AppController app) async {
    final session = app.completeSession();
    if (session == null) return;
    await app.flushPendingWrites();
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => WorkoutCompletedScreen(sessionId: session.id)));
  }

  bool get _hasCustomFilters =>
      _recordFilter != _RecordFilter.all || _sort != _HomeSort.recent;

  String _exerciseSectionSubtitle(int count) {
    final noun = context.strings.t(count == 1 ? 'item' : 'itens', count == 1 ? 'item' : 'items');
    return '$count $noun • ${_sortLabel(context, _sort)}';
  }

  List<MuscleGroup> _matchingGroups() {
    final query = _normalize(_query);
    return MuscleGroup.values
        .where((group) => _normalize(group.localizedLabel(Localizations.localeOf(context))).contains(query))
        .toList(growable: false);
  }

  bool _matchesSearch(Machine machine) {
    final query = _normalize(_query);
    final locale = Localizations.localeOf(context);
    return _normalize(machine.localizedName(locale)).contains(query) ||
        _normalize(machine.group.localizedLabel(locale)).contains(query) ||
        _normalize(machine.equipment.label(locale)).contains(query) ||
        machine.aliases.any((alias) => _normalize(alias).contains(query));
  }

  List<Machine> _applyFilterAndSort(List<Machine> source) {
    var result = source.where((machine) {
      switch (_recordFilter) {
        case _RecordFilter.all:
          return true;
        case _RecordFilter.recorded:
          return machine.records.isNotEmpty;
        case _RecordFilter.unrecorded:
          return machine.records.isEmpty;
      }
    }).toList(growable: false);

    result = [...result];
    switch (_sort) {
      case _HomeSort.recent:
        result.sort((a, b) {
          final aDate = a.latestRecord?.date;
          final bDate = b.latestRecord?.date;
          if (aDate == null && bDate == null) {
            return _normalize(a.localizedName(Localizations.localeOf(context))).compareTo(_normalize(b.localizedName(Localizations.localeOf(context))));
          }
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
        break;
      case _HomeSort.alphabeticalAsc:
        result.sort(
          (a, b) => _normalize(a.localizedName(Localizations.localeOf(context))).compareTo(_normalize(b.localizedName(Localizations.localeOf(context)))),
        );
        break;
      case _HomeSort.alphabeticalDesc:
        result.sort(
          (a, b) => _normalize(b.localizedName(Localizations.localeOf(context))).compareTo(_normalize(a.localizedName(Localizations.localeOf(context)))),
        );
        break;
      case _HomeSort.recordDesc:
        result.sort((a, b) {
          final recordComparison = b.recordWeight.compareTo(a.recordWeight);
          if (recordComparison != 0) return recordComparison;
          return _normalize(a.localizedName(Localizations.localeOf(context))).compareTo(_normalize(b.localizedName(Localizations.localeOf(context))));
        });
        break;
      case _HomeSort.muscleGroup:
        result.sort((a, b) {
          final groupComparison =
              _normalize(a.group.localizedLabel(Localizations.localeOf(context))).compareTo(_normalize(b.group.localizedLabel(Localizations.localeOf(context))));
          if (groupComparison != 0) return groupComparison;
          return _normalize(a.localizedName(Localizations.localeOf(context))).compareTo(_normalize(b.localizedName(Localizations.localeOf(context))));
        });
        break;
    }
    return result;
  }

  Future<void> _openFilters() async {
    var tempFilter = _recordFilter;
    var tempSort = _sort;

    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.deepBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.strings.t('Filtrar e organizar', 'Filter and sort'),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                tempFilter = _RecordFilter.all;
                                tempSort = _HomeSort.recent;
                              });
                            },
                            child: Text(context.strings.t('Limpar', 'Reset')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.strings.t('Exibir', 'Show'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      _ChoiceRow<_RecordFilter>(
                        value: _RecordFilter.all,
                        groupValue: tempFilter,
                        title: context.strings.all,
                        subtitle: context.strings.t('Todos os exercícios e aparelhos', 'All exercises and equipment'),
                        onTap: (value) => setSheetState(() => tempFilter = value),
                      ),
                      _ChoiceRow<_RecordFilter>(
                        value: _RecordFilter.recorded,
                        groupValue: tempFilter,
                        title: context.strings.recorded,
                        subtitle: context.strings.t('Somente os que já têm histórico', 'Only exercises with history'),
                        onTap: (value) => setSheetState(() => tempFilter = value),
                      ),
                      _ChoiceRow<_RecordFilter>(
                        value: _RecordFilter.unrecorded,
                        groupValue: tempFilter,
                        title: context.strings.unrecorded,
                        subtitle: context.strings.t('Exercícios ainda não registrados', 'Exercises not logged yet'),
                        onTap: (value) => setSheetState(() => tempFilter = value),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        context.strings.t('Ordenar por', 'Sort by'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      for (final sort in _HomeSort.values)
                        _ChoiceRow<_HomeSort>(
                          value: sort,
                          groupValue: tempSort,
                          title: _sortLabel(context, sort),
                          onTap: (value) => setSheetState(() => tempSort = value),
                        ),
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(
                          _FilterResult(filter: tempFilter, sort: tempSort),
                        ),
                        child: Text(context.strings.t('Aplicar filtros', 'Apply filters')),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _recordFilter = result.filter;
        _sort = result.sort;
      });
    }
  }

  bool _matchesCardioSearch() {
    final query = _normalize(_query);
    final languageCode = Localizations.localeOf(context).languageCode;
    final terms = languageCode == 'en'
        ? const ['cardio', 'run', 'running', 'walk', 'treadmill', 'bike', 'cycling', 'rowing', 'elliptical']
        : languageCode == 'es'
            ? const ['cardio', 'carrera', 'correr', 'caminata', 'cinta', 'bicicleta', 'ciclismo', 'remo', 'elíptica', 'escaladora']
            : const ['cardio', 'corrida', 'correr', 'caminhada', 'esteira', 'bicicleta', 'ciclismo', 'remo', 'elíptico', 'escada'];
    return terms.any((term) => _normalize(term).contains(query) || query.contains(_normalize(term)));
  }

  void _openCardio(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CardioScreen()));
  }

  void _openGroup(BuildContext context, MuscleGroup group) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GroupScreen(group: group)),
    );
  }

  void _openMachine(BuildContext context, Machine machine) {
    final registeredMachine = AppScope.of(context).ensureMachineAdded(machine);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MachineScreen(machineId: registeredMachine.id),
      ),
    );
  }
}


/// Compact workout section using the pre-existing home theme and spacing.
class _TodayWorkoutCard extends StatelessWidget {
  const _TodayWorkoutCard({
    required this.app,
    required this.onOpenMachine,
    required this.onComplete,
    required this.onAddExercise,
    required this.onStart,
    required this.onTrack,
  });
  final AppController app;
  final ValueChanged<Machine> onOpenMachine;
  final VoidCallback onComplete;
  final VoidCallback onAddExercise;
  final VoidCallback onStart;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    final session = app.activeSession;
    final available = {for (final m in app.availableMachines) m.id: m};
    final selected = session == null ? <Machine>[] :
      [for (final id in session.exerciseIds)
        if (available[id] case final Machine m) m];
    final records = session == null
      ? const <dynamic>[] : app.recordsForSession(session.id);
    return SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.fitness_center_rounded,
            color: AppTheme.electricLime),
          const SizedBox(width: 10),
          Expanded(child: Text(context.strings.t('Treino de hoje', 'Today’s workout', 'Entrenamiento de hoy'),
            style: Theme.of(context).textTheme.titleLarge)),
          if (session != null) TextButton(
            key: const Key('finish_workout'),
            onPressed: onComplete,
            child: Text(context.strings.t('Concluir', 'Finish', 'Finalizar'))),
        ]),
        const SizedBox(height: 8),
        if (session == null) ...[
          Text(context.strings.t('Organize suas séries sem perder o histórico.', 'Keep your sets organized without losing history.', 'Organiza tus series sin perder el historial.'),
            style: TextStyle(color: AppTheme.iceBlue)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('start_workout_session'),
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(context.strings.t('Iniciar treino', 'Start workout', 'Iniciar entrenamiento')),
          ),
        ] else ...[
          Text('${selected.length} ${context.strings.t('exercícios', 'exercises', 'ejercicios')} · ${records.length} ${context.strings.t('séries', 'sets', 'series')}',
            style: const TextStyle(color: AppTheme.iceBlue)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('track_active_workout'),
            onPressed: onTrack,
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: Text(context.strings.t('Acompanhar treino',
              'Track workout', 'Seguir entrenamiento')),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            key: const Key('add_exercise_to_session'),
            onPressed: onAddExercise,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: Text(context.strings.addEquipment),
          ),
          if (selected.isEmpty) ...[
            const SizedBox(height: 12),
            Text(context.strings.t('Seu treino ainda está vazio. Adicione um exercício para começar a registrar as séries.', 'Your workout is empty. Add an exercise to start logging sets.', 'Tu entrenamiento está vacío. Añade un ejercicio para comenzar a registrar series.'),
              style: TextStyle(color: AppTheme.iceBlue, fontSize: 13)),
          ] else ...[
            const SizedBox(height: 10),
            for (final machine in selected)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fitness_center_outlined,
                  size: 20, color: AppTheme.electricLime),
                title: Text(machine.name, maxLines: 1,
                  overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${machine.records.where((r) => r.effectiveSessionId == session.id).length} ${context.strings.t('séries', 'sets', 'series')}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onOpenMachine(machine),
              ),
          ],
        ],
      ]),
    );
  }
}

class _HomeProCard extends StatelessWidget {
  const _HomeProCard({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Container(
          height: 126,
          decoration: BoxDecoration(
            color: AppTheme.surfaceNavy,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppTheme.electricLime.withValues(alpha: .75)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.electricLime.withValues(alpha: .06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -4,
                bottom: -8,
                child: Image.asset(
                  'assets/branding/pro_mascot.webp',
                  width: 126,
                  height: 116,
                  fit: BoxFit.contain,
                  opacity: const AlwaysStoppedAnimation(.94),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 126, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium_outlined, color: AppTheme.electricLime, size: 20),
                        const SizedBox(width: 7),
                        Expanded(child: Text(
                          'GymRecords Pro',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.polarWhite,
                                fontWeight: FontWeight.w600,
                              ),
                        )),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlueSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            enabled ? 'ATIVO' : 'PRO',
                            style: const TextStyle(
                              color: AppTheme.electricLime,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      enabled ? 'Sua evolução, com inteligência.' : 'Descubra seu próximo recorde.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      enabled
                          ? 'Próximo objetivo, mapa muscular e relatórios.'
                          : 'Conheça os relatórios e próximos objetivos.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.25),
                    ),
                  ],
                ),
              ),
              const Positioned(
                right: 12,
                top: 12,
                child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.electricLime),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchContent extends StatelessWidget {
  const _SearchContent({
    required this.groups,
    required this.machines,
    required this.unit,
    required this.onOpenGroup,
    required this.onOpenMachine,
    required this.showCardio,
    required this.onOpenCardio,
  });

  final List<MuscleGroup> groups;
  final List<Machine> machines;
  final String unit;
  final ValueChanged<MuscleGroup> onOpenGroup;
  final ValueChanged<Machine> onOpenMachine;
  final bool showCardio;
  final VoidCallback onOpenCardio;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty && machines.isEmpty && !showCardio) {
      return const _EmptyMachineResults(searchMode: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: context.strings.t('Resultados', 'Results'),
          subtitle: context.strings.t('Abra um exercício diretamente ou explore um grupo', 'Open an exercise directly or explore a group'),
        ),
        if (groups.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final group in groups)
                ActionChip(
                  avatar: const Icon(
                    Icons.accessibility_new_rounded,
                    size: 18,
                    color: AppTheme.electricLime,
                  ),
                  label: Text(group.localizedLabel(Localizations.localeOf(context))),
                  onPressed: () => onOpenGroup(group),
                  backgroundColor: AppTheme.surfaceNavy,
                  side: const BorderSide(color: AppTheme.deepBlue),
                ),
            ],
          ),
        ],
        if (showCardio) ...[
          const SizedBox(height: 14),
          _CardioSearchResult(onTap: onOpenCardio),
        ],
        if (machines.isNotEmpty) ...[
          const SizedBox(height: 18),
          for (var index = 0; index < machines.length; index++) ...[
            MachineListCard(
              machine: machines[index],
              unit: unit,
              onTap: () => onOpenMachine(machines[index]),
            ),
            if (index != machines.length - 1) const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _QuickMachineCard extends StatelessWidget {
  const _QuickMachineCard({
    required this.machine,
    required this.unit,
    required this.onTap,
  });

  final Machine machine;
  final String unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latest = machine.latestRecord;
    return SizedBox(
      width: 174,
      child: Material(
        color: AppTheme.surfaceNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: const BorderSide(color: AppTheme.deepBlue),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 103,
                child: AdaptiveExerciseImage(
                  machine: machine,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        machine.localizedName(Localizations.localeOf(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          if (machine.recordWeight > 0) ...[
                            const Icon(
                              Icons.emoji_events_outlined,
                              color: AppTheme.electricLime,
                              size: 17,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '${WeightUnits.format(machine.recordWeight, unit, Localizations.localeOf(context))} $unit',
                                style: const TextStyle(
                                  color: AppTheme.electricLime,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                          if (latest != null)
                            Text(
                              formatShortDate(latest.date, Localizations.localeOf(context)),
                              style: const TextStyle(
                                color: AppTheme.iceBlue,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.royalBlue : AppTheme.surfaceNavy,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.royalBlue : AppTheme.deepBlue,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.polarWhite : AppTheme.iceBlue,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceNavy,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.deepBlue),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded, size: 17),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.iceBlue,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final T value;
  final T groupValue;
  final String title;
  final String? subtitle;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppTheme.royalBlue.withValues(alpha: 0.18)
            : AppTheme.deepNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: selected ? AppTheme.royalBlue : AppTheme.deepBlue,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onTap(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.polarWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppTheme.iceBlue,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.electricLime
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppTheme.electricLime
                          : AppTheme.iceBlue,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 17,
                          color: AppTheme.deepNavy,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyMachineResults extends StatelessWidget {
  const _EmptyMachineResults({this.searchMode = false});

  final bool searchMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 42),
      decoration: BoxDecoration(
        color: AppTheme.surfaceNavy,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.deepBlue),
      ),
      child: Column(
        children: [
          Icon(
            searchMode ? Icons.search_off_rounded : Icons.filter_alt_off_rounded,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            searchMode
                ? context.strings.t('Nenhum resultado encontrado', 'No results found')
                : context.strings.t('Nenhum exercício neste filtro', 'No exercises in this filter'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            searchMode
                ? context.strings.t('Tente buscar pelo nome do exercício, aparelho ou grupo muscular.', 'Try searching by exercise, equipment or muscle group.')
                : context.strings.t('Altere os filtros para visualizar outros exercícios.', 'Change the filters to view other exercises.'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}


class _CardioSearchResult extends StatelessWidget {
  const _CardioSearchResult({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppTheme.surfaceNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: const BorderSide(color: AppTheme.electricLime),
        ),
        child: ListTile(
          onTap: onTap,
          leading: const Icon(Icons.directions_run_rounded, color: AppTheme.electricLime),
          title: Text(context.strings.cardio),
          subtitle: Text(context.strings.cardioSubtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      );
}

class _FilterResult {
  const _FilterResult({required this.filter, required this.sort});

  final _RecordFilter filter;
  final _HomeSort sort;
}

String _sortLabel(BuildContext context, _HomeSort sort) {
  switch (sort) {
    case _HomeSort.recent:
      return context.strings.t('Mais recentes', 'Most recent');
    case _HomeSort.alphabeticalAsc:
      return 'A–Z';
    case _HomeSort.alphabeticalDesc:
      return 'Z–A';
    case _HomeSort.recordDesc:
      return context.strings.t('Maior recorde', 'Highest record');
    case _HomeSort.muscleGroup:
      return context.strings.t('Grupo muscular', 'Muscle group');
  }
}

String _normalize(String value) {
  const withAccents = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const withoutAccents = 'aaaaaeeeeiiiiooooouuuuc';
  var result = value.toLowerCase();
  for (var index = 0; index < withAccents.length; index++) {
    result = result.replaceAll(withAccents[index], withoutAccents[index]);
  }
  return result.trim();
}
