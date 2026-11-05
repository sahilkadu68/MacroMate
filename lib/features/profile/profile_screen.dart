import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/validators/input_validators.dart';
import '../../providers/profile_provider.dart';
import '../../providers/tracking_provider.dart';
import '../../services/auth_service.dart';
import 'widgets/mifflin_calculator_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _budgetController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _waterController;

  late String _dietPreference;
  late String _activityLevel;
  late String _nutritionGoal;

  bool _initialized = false;

  Future<void> _changePassword() async {
    final auth = context.read<AuthController>();
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    String? error;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
              ),
              TextField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password (8+ characters)',
                ),
              ),
              TextField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (next.text.length < 8 || next.text != confirm.text) {
                  setDialogState(
                    () => error = next.text.length < 8
                        ? 'Use at least 8 characters.'
                        : 'Passwords do not match.',
                  );
                  return;
                }
                try {
                  await auth.changePassword(current.text, next.text);
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } on LocalAuthException catch (exception) {
                  setDialogState(() => error = exception.message);
                }
              },
              child: const Text('Update password'),
            ),
          ],
        ),
      ),
    );
    current.dispose();
    next.dispose();
    confirm.dispose();
    if (accepted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated on this device.')),
      );
    }
  }

  Future<void> _deleteLocalAccount() async {
    final auth = context.read<AuthController>();
    final password = TextEditingController();
    String? error;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete local account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently removes this account and its on-device meals, goals, recipes, and tracking records.',
              ),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () async {
                try {
                  await auth.deleteAccount(password.text);
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } on LocalAuthException catch (exception) {
                  setDialogState(() => error = exception.message);
                } catch (_) {
                  setDialogState(
                    () =>
                        error = 'The account could not be deleted. Try again.',
                  );
                }
              },
              child: const Text('Delete account'),
            ),
          ],
        ),
      ),
    );
    password.dispose();
    if (accepted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local account and its data were deleted.'),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final p = Provider.of<ProfileProvider>(context).profile;

      _nameController = TextEditingController(text: p.displayName);
      _budgetController = TextEditingController(
        text: p.dailyBudget.toInt().toString(),
      );
      _caloriesController = TextEditingController(
        text: p.calorieTarget.toInt().toString(),
      );
      _proteinController = TextEditingController(
        text: p.proteinTarget.toInt().toString(),
      );
      _carbsController = TextEditingController(
        text: p.carbohydrateTarget.toInt().toString(),
      );
      _fatController = TextEditingController(
        text: p.fatTarget.toInt().toString(),
      );
      _waterController = TextEditingController(
        text: p.waterTarget.toInt().toString(),
      );

      _dietPreference =
          AppConstants.dietaryPreferences.contains(p.dietaryPreference)
          ? p.dietaryPreference
          : AppConstants.dietAll;
      _activityLevel = p.activityLevel;
      _nutritionGoal = p.nutritionGoal;

      _initialized = true;
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _budgetController.dispose();
      _caloriesController.dispose();
      _proteinController.dispose();
      _carbsController.dispose();
      _fatController.dispose();
      _waterController.dispose();
    }
    super.dispose();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final current = provider.profile;

    final updated = current.copyWith(
      displayName: _nameController.text.trim(),
      dailyBudget: double.parse(_budgetController.text.trim()),
      calorieTarget: double.parse(_caloriesController.text.trim()),
      proteinTarget: double.parse(_proteinController.text.trim()),
      carbohydrateTarget: double.parse(_carbsController.text.trim()),
      fatTarget: double.parse(_fatController.text.trim()),
      waterTarget: double.parse(_waterController.text.trim()),
      dietaryPreference: _dietPreference,
      activityLevel: _activityLevel,
      nutritionGoal: _nutritionGoal,
    );

    await provider.updateProfile(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('Profile and daily targets updated successfully!'),
        ),
      );
    }
  }

  void _openMifflinDialog() {
    final profile = Provider.of<ProfileProvider>(
      context,
      listen: false,
    ).profile;
    showDialog(
      context: context,
      builder: (_) => MifflinCalculatorDialog(
        currentProfile: profile,
        onApply: (estimated) {
          setState(() {
            _caloriesController.text = estimated['calories']!
                .toInt()
                .toString();
            _proteinController.text = estimated['protein']!.toInt().toString();
            _carbsController.text = estimated['carbs']!.toInt().toString();
            _fatController.text = estimated['fat']!.toInt().toString();
            _waterController.text = estimated['water']!.toInt().toString();
          });
          _saveProfile();
        },
      ),
    );
  }

  void _showActivityDialog() {
    final tracking = Provider.of<TrackingProvider>(context, listen: false);
    String selectedType = 'Gym / Weightlifting';
    final durController = TextEditingController(text: '45');
    final calController = TextEditingController(text: '220');

    final types = [
      'Gym / Weightlifting',
      'Running / Jogging',
      'Brisk Walking',
      'Cricket / Sports',
      'Cycling',
      'Yoga / Stretching',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Log Physical Activity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Activity Type'),
                isExpanded: true,
                items: types
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() {
                      selectedType = val;
                      if (val.contains('Gym')) calController.text = '240';
                      if (val.contains('Running')) calController.text = '320';
                      if (val.contains('Walking')) calController.text = '140';
                      if (val.contains('Yoga')) calController.text = '100';
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: durController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (min)',
                        suffixText: 'm',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: calController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Calories (est)',
                        suffixText: 'kcal',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final d = int.tryParse(durController.text.trim()) ?? 30;
                final c = double.tryParse(calController.text.trim()) ?? 150.0;
                tracking.addActivity(
                  type: selectedType,
                  durationMinutes: d,
                  estimatedCalories: c,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logged $selectedType ($d mins)')),
                );
              },
              child: const Text('Save Activity'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final trackingProvider = Provider.of<TrackingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Nutrition Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary),
            tooltip: 'Save Profile',
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Identity Card
                    Card(
                      color: theme.colorScheme.primary.withAlpha(20),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: theme.colorScheme.primary,
                              child: const Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nameController.text.isEmpty
                                        ? 'Student Athlete'
                                        : _nameController.text,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Goal: $_nutritionGoal • Diet: $_dietPreference',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withAlpha(160),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Scientific Estimator Callout Button
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _openMifflinDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.indigo.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 22,
                              color: Colors.indigo,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estimate Targets with Science',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Use Mifflin-St Jeor formula & body stats to auto-calculate macros',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.indigo,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Personal Information
                    Text(
                      'Personal Details',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                      ),
                      validator: (val) =>
                          InputValidators.requiredField(val, 'Display Name'),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _dietPreference,
                            decoration: const InputDecoration(
                              labelText: 'Dietary Preference',
                            ),
                            items: AppConstants.dietaryPreferences.map((d) {
                              return DropdownMenuItem(
                                value: d,
                                child: Text(
                                  d,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _dietPreference = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _nutritionGoal,
                            decoration: const InputDecoration(
                              labelText: 'Fitness Objective',
                            ),
                            items: AppConstants.nutritionGoals.map((g) {
                              return DropdownMenuItem(
                                value: g,
                                child: Text(
                                  g,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _nutritionGoal = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Daily Targets
                    Text(
                      'Daily Nutritional & Budget Targets',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Budget & Calories
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _budgetController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Daily Budget *',
                              prefixText: '₹ ',
                            ),
                            validator: (v) => InputValidators.positiveNumber(
                              v,
                              'Daily budget',
                              allowZero: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _caloriesController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Calorie Target *',
                              suffixText: 'kcal',
                            ),
                            validator: (v) => InputValidators.positiveNumber(
                              v,
                              'Calorie target',
                              allowZero: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Protein & Water
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _proteinController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Protein Target *',
                              suffixText: 'g',
                            ),
                            validator: (v) => InputValidators.positiveNumber(
                              v,
                              'Protein target',
                              allowZero: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _waterController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Water Target *',
                              suffixText: 'ml',
                            ),
                            validator: (v) => InputValidators.positiveNumber(
                              v,
                              'Water target',
                              allowZero: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Carbs & Fat
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _carbsController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Carbs Target *',
                              suffixText: 'g',
                            ),
                            validator: (v) => InputValidators.positiveNumber(
                              v,
                              'Carbs target',
                              allowZero: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _fatController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Fat Target *',
                              suffixText: 'g',
                            ),
                            validator: (v) => InputValidators.positiveNumber(
                              v,
                              'Fat target',
                              allowZero: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Save Profile & Targets'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Physical Activity Logger Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.fitness_center,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Physical Activity',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: _showActivityDialog,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Log Workout'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (trackingProvider.activityLogs.isEmpty)
                              Text(
                                'No workouts logged today. Add gym, running, or walking sessions to track activity.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withAlpha(
                                    140,
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: trackingProvider.activityLogs.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (ctx, i) {
                                  final act = trackingProvider.activityLogs[i];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${act.activityType} (${act.durationMinutes} mins)',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '~${act.estimatedCalories.round()} kcal',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.calories,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    OutlinedButton.icon(
                      onPressed: () => context.read<AuthController>().signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Log out'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _changePassword,
                      icon: const Icon(Icons.password_outlined),
                      label: const Text('Change local password'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _deleteLocalAccount,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete local account and data'),
                    ),
                    const SizedBox(height: 16),

                    // Storage limitation note
                    Center(
                      child: Text(
                        'This local account is only for this device. Export or device backup is not available.',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
