import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/food_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/protein_finder_provider.dart';
import '../../providers/tracking_provider.dart';
import '../../services/auth_service.dart';
import '../navigation/main_scaffold.dart';
import 'auth_screen.dart';
import 'onboarding_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.auth});
  final AuthController auth;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    if (widget.auth.loading) widget.auth.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.auth,
      builder: (context, _) {
        if (widget.auth.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final account = widget.auth.account;
        if (account == null) return AuthScreen(auth: widget.auth);
        if (!account.onboardingComplete) {
          return OnboardingScreen(auth: widget.auth);
        }
        final profile = context.watch<ProfileProvider>();
        if (profile.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (profile.errorMessage != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load your saved profile.'),
                  FilledButton(
                    onPressed: profile.loadProfile,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }
        return const MainScaffold();
      },
    );
  }
}

class AccountScope extends StatelessWidget {
  const AccountScope({super.key, required this.auth, required this.child});
  final AuthController auth;
  final Widget child;
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => FoodProvider()),
      ChangeNotifierProvider(create: (_) => MealProvider()),
      ChangeNotifierProvider(create: (_) => TrackingProvider()),
      ChangeNotifierProvider(create: (_) => ProteinFinderProvider()),
      ChangeNotifierProvider(create: (_) => PlanProvider()),
    ],
    child: child,
  );
}
