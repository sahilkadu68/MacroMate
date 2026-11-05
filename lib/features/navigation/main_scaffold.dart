import 'package:flutter/material.dart';
import '../../data/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../dashboard/dashboard_screen.dart';
import '../foods/food_catalogue_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/progress_screen.dart';
import '../planning/plan_hub_screen.dart';
import '../meal_logging/meal_log_screen.dart';

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
    PlanHubScreen(),
    MealLogScreen(),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 680;

    final content = Scaffold(
      body: Column(
        children: [
          if (DatabaseHelper.instance.isFallbackMode)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF3CD),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFF7A4B00)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Temporary browser storage is active. Changes may be lost when this tab closes or reloads.',
                      style: TextStyle(color: Color(0xFF563500)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
        ],
      ),
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
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note, color: AppColors.primaryDark),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(
              Icons.receipt_long,
              color: AppColors.primaryDark,
            ),
            label: 'Logs',
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

    if (isDesktop) {
      return Container(
        color: const Color(
          0xFFF1F5F9,
        ), // modern cool slate background for desktop
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 640),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRect(child: content),
          ),
        ),
      );
    }

    return content;
  }
}
