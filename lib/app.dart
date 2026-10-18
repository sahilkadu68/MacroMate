import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/main_scaffold.dart';
import 'providers/food_provider.dart';
import 'providers/meal_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/protein_finder_provider.dart';
import 'providers/tracking_provider.dart';

class MacroMateApp extends StatelessWidget {
  const MacroMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => FoodProvider()),
        ChangeNotifierProvider(create: (_) => MealProvider()),
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
        ChangeNotifierProvider(create: (_) => ProteinFinderProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MainScaffold(),
      ),
    );
  }
}
