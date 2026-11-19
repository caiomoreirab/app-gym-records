import 'package:material_ui/material_ui.dart';

import '../data/mock_data.dart';
import '../l10n/app_strings.dart';
import '../models/machine.dart';
import '../models/muscle_group.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/adaptive_illustration.dart';
import '../widgets/page_body.dart';
import '../widgets/primary_bottom_bar.dart';
import 'custom_machine_screen.dart';

class AddMachineScreen extends StatefulWidget {
  const AddMachineScreen({super.key, required this.group});

  final MuscleGroup group;

  @override
  State<AddMachineScreen> createState() => _AddMachineScreenState();
}

class _AddMachineScreenState extends State<AddMachineScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final catalog = buildCatalogFor(widget.group);

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(context.strings.t('Adicionar exercício', 'Add exercise')),
      ),
      bottomNavigationBar: PrimaryBottomBar(
        label: context.strings.t('Adicionar', 'Add'),
        onPressed: _selectedId == null
            ? null
            : () {
                final selected = catalog.firstWhere(
                  (machine) => machine.id == _selectedId,
                );
                controller.addMachine(
                  Machine(
                    id: selected.id,
                    name: selected.name,
                    nameEn: selected.nameEn,
                    group: selected.group,
                    equipment: selected.equipment,
                    subgroup: selected.subgroup,
                    subgroupEn: selected.subgroupEn,
                    visualAssetId: selected.visualAssetId,
                    aliases: selected.aliases,
                    imageAsset: selected.imageAsset,
                  ),
                );
                Navigator.of(context).pop();
              },
        secondary: OutlinedButton(
          onPressed: () async {
            final created = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => CustomMachineScreen(group: widget.group),
              ),
            );
            if (created == true && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Text(context.strings.createCustomExercise),
        ),
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Text(
              widget.group.localizedLabel(Localizations.localeOf(context)),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.iceBlue,
                  ),
            ),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: catalog.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final machine = catalog[index];
                final added = controller.hasMachine(machine.id);
                final selected = _selectedId == machine.id;
                return _CatalogCard(
                  machine: machine,
                  added: added,
                  selected: selected,
                  onTap: added
                      ? null
                      : () => setState(() => _selectedId = machine.id),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.machine,
    required this.added,
    required this.selected,
    required this.onTap,
  });

  final Machine machine;
  final bool added;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: added ? 0.55 : 1,
      child: Material(
        color: AppTheme.surfaceNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: BorderSide(
            color: selected ? AppTheme.electricLime : AppTheme.deepBlue,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AdaptiveExerciseImage(machine: machine, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machine.localizedName(Localizations.localeOf(context)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (added) ...[
                      const SizedBox(height: 4),
                      Text(
                        context.strings.t('Adicionado', 'Added'),
                        style: TextStyle(color: AppTheme.iceBlue, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
