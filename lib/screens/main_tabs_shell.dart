import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../widgets/gym_bottom_navigation.dart';
import 'home_screen.dart';
import 'exercise_catalog_screen.dart';
import 'reports_hub_screen.dart';
import 'settings_screen.dart';

/// Keeps all four primary destinations mounted while the user navigates.
/// Search, filters and scroll state survive tab switches without changing
/// any page's brand identity or standalone route compatibility.
class MainTabsShell extends StatefulWidget {
  const MainTabsShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainTabsShell> createState() => _MainTabsShellState();
}

class _MainTabsShellState extends State<MainTabsShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.deepNavy,
    body: IndexedStack(
      index: _index,
      children: const [
        HomeScreen(showBottomNav: false),
        ExerciseCatalogScreen(showBottomNav: false),
        ReportsHubScreen(showBottomNav: false),
        SettingsScreen(asMainTab: true, showBottomNav: false),
      ],
    ),
    bottomNavigationBar: GymBottomNavigation(
      index: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
    ),
  );
}
