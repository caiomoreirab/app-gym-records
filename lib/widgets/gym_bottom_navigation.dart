import 'package:material_ui/material_ui.dart';

import '../screens/main_tabs_shell.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

/// Navigation only at top level. Exercise details retain their existing CTA.
class GymBottomNavigation extends StatelessWidget {
  const GymBottomNavigation({super.key, required this.index,
    this.onDestinationSelected});
  final int index;
  final ValueChanged<int>? onDestinationSelected;

  static List<String> labelsFor(BuildContext context) => [
    context.strings.t('Início', 'Home', 'Inicio'),
    context.strings.t('Exercícios', 'Exercises', 'Ejercicios'),
    context.strings.t('Relatórios', 'Reports', 'Informes'),
    context.strings.t('Perfil', 'Profile', 'Perfil'),
  ];
  static const _icons = [
    Icons.home_rounded, Icons.fitness_center_rounded,
    Icons.insert_chart_outlined_rounded, Icons.person_rounded,
  ];

  void _open(BuildContext context, int destination) {
    if (destination == index) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (onDestinationSelected != null) {
      onDestinationSelected!(destination);
      return;
    }
    // Standalone entry points transition into a persistent four-tab shell.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) =>
        MainTabsShell(initialIndex: destination)), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final labels = labelsFor(context);
    return Material(
      color: AppTheme.surfaceNavy,
      child: SafeArea(top: false, child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.deepBlue)),
        ),
        padding: const EdgeInsets.fromLTRB(5, 7, 5, 7),
        height: 77 + ((scale - 1).clamp(0.0, 0.5) * 24),
        child: Row(children: [
          for (var i = 0; i < 4; i++)
            Expanded(child: Semantics(
              key: Key('main_nav_$i'),
              label: labels[i],
              button: true,
              selected: i == index,
              child: Tooltip(
                message: labels[i],
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _open(context, i),
                  child: ExcludeSemantics(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 55, height: 37,
                          decoration: BoxDecoration(
                            color: i == index
                              ? AppTheme.accentBlueSoft : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.center,
                          child: Icon(_icons[i], size: 28,
                            color: i == index
                              ? AppTheme.electricLime : AppTheme.iceBlue),
                        ),
                        const SizedBox(height: 3),
                        Text(labels[i], maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12,
                            fontWeight: i == index ? FontWeight.w600 : FontWeight.w400,
                            color: i == index
                              ? AppTheme.electricLime : AppTheme.iceBlue)),
                      ],
                    ),
                  ),
                ),
              ),
            )),
        ]),
      )),
    );
  }
}
