import 'package:flutter/material.dart';
import 'features/auth/auth_gate.dart';
import 'services/auth_service.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

class MacroMateApp extends StatelessWidget {
  const MacroMateApp({super.key, required this.auth});
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: AuthGate(auth: auth),
    );
  }
}
