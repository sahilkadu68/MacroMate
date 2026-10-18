import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/validators/input_validators.dart';
import '../../../data/models/user_profile.dart';
import '../../../services/nutrition_service.dart';

class MifflinCalculatorDialog extends StatefulWidget {
  final UserProfile currentProfile;
  final Function(Map<String, double> estimatedGoals) onApply;

  const MifflinCalculatorDialog({
    super.key,
    required this.currentProfile,
    required this.onApply,
  });

  @override
  State<MifflinCalculatorDialog> createState() =>
      _MifflinCalculatorDialogState();
}

class _MifflinCalculatorDialogState extends State<MifflinCalculatorDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;

  late String _selectedGender;
  late String _selectedActivity;
  late String _selectedGoal;

  Map<String, double>? _calculationResult;

  @override
  void initState() {
    super.initState();
    final p = widget.currentProfile;

    _weightController = TextEditingController(
      text: p.currentWeight.toStringAsFixed(1),
    );
    _heightController = TextEditingController(
      text: p.height.toStringAsFixed(0),
    );
    _ageController = TextEditingController(text: p.age?.toString() ?? '21');

    _selectedGender = p.gender;
    _selectedActivity = p.activityLevel;
    _selectedGoal = p.nutritionGoal;

    _recalculate();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final w = double.tryParse(_weightController.text.trim());
    final h = double.tryParse(_heightController.text.trim());
    final a = int.tryParse(_ageController.text.trim());

    if (w != null && h != null && a != null && w > 20 && h > 50 && a > 10) {
      final bmr = NutritionService.calculateMifflinStJeorBmr(
        weightKg: w,
        heightCm: h,
        age: a,
        gender: _selectedGender,
      );
      final tdee = NutritionService.calculateTdee(
        bmr: bmr,
        activityLevel: _selectedActivity,
      );
      final cals = NutritionService.calculateGoalCalories(
        tdee: tdee,
        goal: _selectedGoal,
      );
      final macros = NutritionService.estimateMacroTargets(
        weightKg: w,
        calorieTarget: cals,
        goal: _selectedGoal,
      );
      final water = NutritionService.estimateWaterTarget(w);

      setState(() {
        _calculationResult = {
          'bmr': bmr.roundToDouble(),
          'tdee': tdee.roundToDouble(),
          'calories': macros['calories']!,
          'protein': macros['protein']!,
          'carbs': macros['carbs']!,
          'fat': macros['fat']!,
          'water': water.roundToDouble(),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calculate, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Energy & Macro Estimator',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Based on the validated Mifflin-St Jeor equation. Labeled strictly as an estimate; not medical advice.',
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                  ),
                ),
                const SizedBox(height: 16),

                // Gender selector
                Row(
                  children: [
                    const Text(
                      'Biological Sex:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'male', label: Text('Male')),
                        ButtonSegment(value: 'female', label: Text('Female')),
                      ],
                      selected: {_selectedGender},
                      onSelectionChanged: (val) {
                        setState(() => _selectedGender = val.first);
                        _recalculate();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Weight, Height, Age
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Weight',
                          suffixText: 'kg',
                        ),
                        validator: (v) => InputValidators.realisticWeight(v),
                        onChanged: (_) => _recalculate(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Height',
                          suffixText: 'cm',
                        ),
                        validator: (v) => InputValidators.realisticHeight(v),
                        onChanged: (_) => _recalculate(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          suffixText: 'yrs',
                        ),
                        validator: (v) => InputValidators.realisticAge(v),
                        onChanged: (_) => _recalculate(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Activity Level Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedActivity,
                  decoration: const InputDecoration(
                    labelText: 'Activity Level',
                  ),
                  isExpanded: true,
                  items: AppConstants.activityLevels.map((act) {
                    return DropdownMenuItem(
                      value: act,
                      child: Text(act, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedActivity = val);
                      _recalculate();
                    }
                  },
                ),
                const SizedBox(height: 14),

                // Nutrition Goal Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedGoal,
                  decoration: const InputDecoration(
                    labelText: 'Fitness Objective',
                  ),
                  items: AppConstants.nutritionGoals.map((g) {
                    return DropdownMenuItem(value: g, child: Text(g));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedGoal = val);
                      _recalculate();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Calculation Result Preview
                if (_calculationResult != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withAlpha(50),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'BMR: ${_calculationResult!["bmr"]!.round()} kcal',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'TDEE: ${_calculationResult!["tdee"]!.round()} kcal',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStat(
                              'Target Calories',
                              '${_calculationResult!["calories"]!.round()} kcal',
                              AppColors.calories,
                            ),
                            _buildStat(
                              'Protein',
                              '${_calculationResult!["protein"]!.round()}g',
                              AppColors.protein,
                            ),
                            _buildStat(
                              'Carbs',
                              '${_calculationResult!["carbs"]!.round()}g',
                              AppColors.carbs,
                            ),
                            _buildStat(
                              'Fat',
                              '${_calculationResult!["fat"]!.round()}g',
                              AppColors.fat,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() &&
                        _calculationResult != null) {
                      widget.onApply(_calculationResult!);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Apply Calculated Targets to Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
