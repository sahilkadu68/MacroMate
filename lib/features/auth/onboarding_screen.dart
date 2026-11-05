import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../data/database/database_helper.dart';
import '../../services/auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.auth});
  final AuthController auth;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  final _budget = TextEditingController(text: '150');
  String _diet = AppConstants.dietVeg;
  String _goal = AppConstants.goalMaintain;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final budget = double.tryParse(_budget.text.trim());
    if (_name.text.trim().isEmpty ||
        budget == null ||
        !budget.isFinite ||
        budget <= 0) {
      setState(() => _error = 'Enter a name and a budget greater than ₹0.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final database = DatabaseHelper.instance;
      final profile = await database.getUserProfile();
      await database.updateUserProfile(
        profile.copyWith(
          displayName: _name.text.trim(),
          dietaryPreference: _diet,
          nutritionGoal: _goal,
          dailyBudget: budget,
        ),
      );
      await widget.auth.completeOnboarding();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Profile could not be saved. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Set up your plan'),
      actions: [
        TextButton(
          onPressed: _busy ? null : widget.auth.signOut,
          child: const Text('Log out'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'A few details make your suggestions more useful.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Your profile is stored locally on this device. Nutrition targets are estimates for general wellness.',
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _diet,
          decoration: const InputDecoration(labelText: 'Diet'),
          items: AppConstants.dietaryPreferences
              .where((value) => value != AppConstants.dietAll)
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) => setState(() => _diet = value ?? _diet),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _goal,
          decoration: const InputDecoration(labelText: 'Goal'),
          items: AppConstants.nutritionGoals
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) => setState(() => _goal = value ?? _goal),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _budget,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Daily food budget (₹)'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save profile and continue'),
        ),
      ],
    ),
  );
}
