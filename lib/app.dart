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
    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        final account = auth.account;
        final app = MaterialApp(
          key: ValueKey(
            'session_${account?.id}_${account?.onboardingComplete}',
          ),
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: AuthGate(auth: auth),
        );
        if (account == null || !account.onboardingComplete) return app;
        return AccountScope(key: ValueKey(account.id), auth: auth, child: app);
      },
    );
  }
}
