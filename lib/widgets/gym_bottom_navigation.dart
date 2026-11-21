import 'package:material_ui/material_ui.dart';

import '../screens/exercise_catalog_screen.dart';
import '../screens/home_screen.dart';
import '../screens/reports_hub_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/app_theme.dart';

/// Navigation only at top level. Exercise details retain their existing CTA.
class GymBottomNavigation extends StatelessWidget {
  const GymBottomNavigation({super.key, required this.index});
  final int index;

  static const _labels = ['Início', 'Exercícios', 'Relatórios', 'Perfil'];
  static const _icons = [
    Icons.home_rounded, Icons.fitness_center_rounded,
    Icons.insert_chart_outlined_rounded, Icons.person_rounded,
  ];

  void _open(BuildContext context, int destination) {
    if (destination == index) return;
    final Widget page = switch (destination) {
      0 => const HomeScreen(),
      1 => const ExerciseCatalogScreen(),
      2 => const ReportsHubScreen(),
      _ => const SettingsScreen(asMainTab: true),
    };
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => page), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
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
              label: _labels[i],
              button: true,
              selected: i == index,
              child: Tooltip(
                message: _labels[i],
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
                        Text(_labels[i], maxLines: 1,
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
