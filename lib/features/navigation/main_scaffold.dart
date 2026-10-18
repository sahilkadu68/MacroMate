import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../dashboard/dashboard_screen.dart';
import '../foods/food_catalogue_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/progress_screen.dart';
import '../protein_finder/protein_finder_screen.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;

  const MainScaffold({super.key, this.initialIndex = 0});

  static MainScaffoldState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainScaffoldState>();
  }

  @override
  State<MainScaffold> createState() => MainScaffoldState();
}

class MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    DashboardScreen(),
    FoodCatalogueScreen(),
    ProteinFinderScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: switchTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primaryDark),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(
              Icons.restaurant_menu,
              color: AppColors.primaryDark,
            ),
            label: 'Foods',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt, color: AppColors.secondary),
            label: 'Protein Finder',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights, color: AppColors.primaryDark),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primaryDark),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
