import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/machine.dart';
import '../models/muscle_group.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/adaptive_illustration.dart';
import '../widgets/page_body.dart';
import '../widgets/primary_bottom_bar.dart';
import '../widgets/section_card.dart';

class CustomMachineScreen extends StatefulWidget {
  const CustomMachineScreen({super.key, required this.group});

  final MuscleGroup group;

  @override
  State<CustomMachineScreen> createState() => _CustomMachineScreenState();
}

class _CustomMachineScreenState extends State<CustomMachineScreen> {
  final TextEditingController _controller = TextEditingController();
  EquipmentType _equipment = EquipmentType.other;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(context.strings.customExercise),
      ),
      bottomNavigationBar: PrimaryBottomBar(
        label: context.strings.t('Criar exercício', 'Create exercise'),
        onPressed: _controller.text.trim().isEmpty
            ? null
            : () {
                AppScope.of(context).addCustomMachine(
                  name: _controller.text,
                  group: widget.group,
                  equipment: _equipment,
                );
                Navigator.of(context).pop(true);
              },
      ),
      body: PageBody(
        child: ListView(
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AdaptiveExerciseImage(
                      machine: Machine(
                        id: 'custom_preview',
                        name: _controller.text.trim().isEmpty ? context.strings.customExercise : _controller.text.trim(),
                        group: widget.group,
                        equipment: _equipment,
                        imageAsset: '',
                        isCustom: true,
                      ),
                      width: double.infinity,
                      height: 190,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.group.localizedLabel(locale),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.iceBlue),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 40,
                    decoration: InputDecoration(
                      labelText: context.strings.t('Nome do exercício', 'Exercise name'),
                      hintText: context.strings.t('Ex.: Variação da academia', 'E.g. Gym variation'),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(context.strings.equipmentType, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final type in EquipmentType.values)
                        ChoiceChip(
                          label: Text(type.label(locale)),
                          selected: _equipment == type,
                          onSelected: (_) => setState(() => _equipment = type),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
