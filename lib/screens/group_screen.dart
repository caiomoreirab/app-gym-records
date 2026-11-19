import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/machine.dart';
import '../models/muscle_group.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_header.dart';
import '../widgets/machine_list_card.dart';
import '../widgets/page_body.dart';
import '../widgets/primary_bottom_bar.dart';
import 'add_machine_screen.dart';
import 'machine_screen.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key, required this.group});

  final MuscleGroup group;

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  String _query = '';
  EquipmentType? _equipment;
  String? _subgroup;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final locale = Localizations.localeOf(context);
    final allMachines = controller.machinesFor(widget.group);
    final subgroupOptions = allMachines
        .map((m) => m.localizedSubgroup(locale))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final normalizedQuery = _query.trim().toLowerCase();
    final machines = allMachines.where((machine) {
      final nameMatches = normalizedQuery.isEmpty ||
          machine.localizedName(locale).toLowerCase().contains(normalizedQuery) ||
          machine.equipment.label(locale).toLowerCase().contains(normalizedQuery) ||
          machine.aliases.any((alias) => alias.toLowerCase().contains(normalizedQuery));
      final equipmentMatches = _equipment == null || machine.equipment == _equipment;
      final subgroupMatches = _subgroup == null || machine.localizedSubgroup(locale) == _subgroup;
      return nameMatches && equipmentMatches && subgroupMatches;
    }).toList(growable: false);

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(widget.group.localizedLabel(locale)),
      ),
      bottomNavigationBar: PrimaryBottomBar(
        label: context.strings.addEquipment,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => AddMachineScreen(group: widget.group)),
        ),
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 18),
          children: [
            const BrandHeader(compact: true),
            const SizedBox(height: 18),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: context.strings.searchExercise,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Chip(
                    label: context.strings.all,
                    selected: _equipment == null,
                    onTap: () => setState(() => _equipment = null),
                  ),
                  for (final type in const [
                    EquipmentType.machine,
                    EquipmentType.barbell,
                    EquipmentType.dumbbell,
                    EquipmentType.cable,
                    EquipmentType.smith,
                    EquipmentType.bodyweight,
                  ]) ...[
                    const SizedBox(width: 8),
                    _Chip(
                      label: type.label(locale),
                      selected: _equipment == type,
                      onTap: () => setState(() => _equipment = type),
                    ),
                  ],
                ],
              ),
            ),
            if (subgroupOptions.isNotEmpty) ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _Chip(
                      label: context.strings.t('Todos os músculos', 'All muscles'),
                      selected: _subgroup == null,
                      subtle: true,
                      onTap: () => setState(() => _subgroup = null),
                    ),
                    for (final subgroup in subgroupOptions) ...[
                      const SizedBox(width: 8),
                      _Chip(
                        label: subgroup,
                        selected: _subgroup == subgroup,
                        subtle: true,
                        onTap: () => setState(() => _subgroup = subgroup),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              context.strings.t('${machines.length} exercícios', '${machines.length} exercises'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (machines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 54),
                child: Column(
                  children: [
                    const Icon(Icons.search_off_rounded, size: 44),
                    const SizedBox(height: 12),
                    Text(context.strings.noExerciseFound, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              )
            else
              for (var index = 0; index < machines.length; index++) ...[
                MachineListCard(
                  machine: machines[index],
                  unit: controller.unit,
                  onTap: () => _openMachine(context, machines[index]),
                ),
                if (index != machines.length - 1) const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }

  void _openMachine(BuildContext context, Machine machine) {
    final registered = AppScope.of(context).ensureMachineAdded(machine);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MachineScreen(machineId: registered.id)),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap, this.subtle = false});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool subtle;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? (subtle ? AppTheme.accentBlueSoft : AppTheme.royalBlue) : AppTheme.surfaceNavy,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppTheme.electricLime : AppTheme.deepBlue),
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
