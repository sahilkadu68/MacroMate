import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/food_item.dart';
import '../../data/models/meal_entry.dart';
import '../../data/models/shopping_item.dart';
import '../../providers/food_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/auth_service.dart';
import '../../services/daily_meal_planner_service.dart';
import '../../services/nutrition_service.dart';
import '../../services/recipe_cost_service.dart';
import '../foods/shopping_list_screen.dart';

class DailyMealPlannerScreen extends StatefulWidget {
  const DailyMealPlannerScreen({super.key});

  @override
  State<DailyMealPlannerScreen> createState() => _DailyMealPlannerScreenState();
}

class _DailyMealPlannerScreenState extends State<DailyMealPlannerScreen> {
  List<PlannedMeal> _meals = [];
  int _mealCount = 4;
  bool _loading = true;
  bool _working = false;
  String? _message;
  Set<int>? _availableFoods;

  Future<void> _chooseAvailableFoods() async {
    final foods = context.read<FoodProvider>().allFoods;
    final chosen = {...?_availableFoods};
    bool restrict = _availableFoods != null;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Cook with what you have'),
          content: SizedBox(
            width: double.maxFinite,
            height: 360,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Use only checked foods'),
                  value: restrict,
                  onChanged: (value) => update(() => restrict = value),
                ),
                Expanded(
                  child: ListView(
                    children: foods
                        .where((food) => food.id != null)
                        .map(
                          (food) => CheckboxListTile(
                            title: Text(food.name),
                            value: chosen.contains(food.id),
                            onChanged: !restrict
                                ? null
                                : (value) => update(() {
                                    if (value == true) {
                                      chosen.add(food.id!);
                                    } else {
                                      chosen.remove(food.id);
                                    }
                                  }),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true && mounted) {
      setState(() => _availableFoods = restrict ? chosen : null);
      await _persist();
    }
  }

  final _exclusions = TextEditingController();
  List<String> get _excludedIngredients => _exclusions.text
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  @override
  void dispose() {
    _exclusions.dispose();
    super.dispose();
  }

  DailyNutritionSummary _consumed = const DailyNutritionSummary();

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String get _planKey {
    final accountId = context.read<AuthController>().account!.id;
    return 'daily_plan_${accountId}_${_today.toIso8601String().substring(0, 10)}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlan());
  }

  Future<void> _loadPlan() async {
    await context.read<FoodProvider>().loadFoods();
    if (!mounted) return;
    await context.read<PlanProvider>().loadAll();
    if (!mounted) return;
    final consumed = await _todayTotals();
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_planKey);
    if (!mounted) return;
    if (encoded == null) {
      setState(() {
        _consumed = consumed;
        _loading = false;
      });
      return;
    }
    try {
      final foods = _planningFoods();
      final ids = {for (final food in foods) food.id: food};
      final data = jsonDecode(encoded) as Map<String, dynamic>;
      _availableFoods = (data['availableFoods'] as List<dynamic>?)
          ?.cast<int>()
          .toSet();
      _exclusions.text = data['excludedIngredients'] as String? ?? '';
      final meals = (data['meals'] as List<dynamic>)
          .map((raw) {
            final row = raw as Map<String, dynamic>;
            final food = ids[row['foodId'] as int];
            if (food == null) return null;
            return PlannedMeal(
              mealType: row['mealType'] as String,
              food: food,
              quantity: (row['quantity'] as num).toDouble(),
              status: row['status'] as String? ?? 'planned',
            );
          })
          .whereType<PlannedMeal>()
          .toList();
      setState(() {
        _consumed = consumed;
        _meals = meals;
        _mealCount = (data['mealCount'] as int?) ?? _mealCount;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _message = 'The saved plan could not be read. Generate a fresh plan.';
      });
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _planKey,
      jsonEncode({
        'mealCount': _mealCount,
        'plannedCost': _meals
            .where((meal) => meal.status != 'skipped')
            .fold<double>(0, (sum, meal) => sum + meal.cost),
        'availableFoods': _availableFoods?.toList(),
        'excludedIngredients': _exclusions.text,
        'meals': _meals
            .where((meal) => meal.food.id != null)
            .map(
              (meal) => {
                'mealType': meal.mealType,
                'foodId': meal.food.id,
                'quantity': meal.quantity,
                'status': meal.status,
              },
            )
            .toList(),
      }),
    );
  }

  List<FoodItem> _planningFoods() {
    final foods = context.read<FoodProvider>().allFoods;
    final recipes = context.read<PlanProvider>().recipes.where(
      (recipe) =>
          recipe.id != null &&
          recipe.servings > 0 &&
          recipe.ingredients.isNotEmpty &&
          recipe.ingredients.every(
            (ingredient) => foods.any(
              (food) =>
                  food.id == ingredient.foodId &&
                  food.measurementUnit == ingredient.measurementUnit,
            ),
          ),
    );
    return [
      ...foods.where(
        (food) => _availableFoods == null || _availableFoods!.contains(food.id),
      ),
      ...recipes
          .where(
            (recipe) =>
                _availableFoods == null ||
                recipe.ingredients.every(
                  (ingredient) => _availableFoods!.contains(ingredient.foodId),
                ),
          )
          .map((recipe) => RecipeCostService.asPlannableFood(recipe, foods)),
    ];
  }

  List<String> _slotsForCount(int count) => switch (count) {
    3 => const ['Breakfast', 'Lunch', 'Dinner'],
    4 => const ['Breakfast', 'Lunch', 'Snack', 'Dinner'],
    5 => const ['Breakfast', 'Pre-workout', 'Lunch', 'Post-workout', 'Dinner'],
    _ => const [
      'Breakfast',
      'Pre-workout',
      'Lunch',
      'Snack',
      'Post-workout',
      'Dinner',
    ],
  };

  Future<DailyNutritionSummary> _todayTotals() async {
    final entries = await DatabaseHelper.instance.getMealEntriesForDate(_today);
    return NutritionService.calculateDailyTotals(entries);
  }

  Future<void> _generate({bool adapt = false}) async {
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      final profile = context.read<ProfileProvider>().profile;
      final foods = _planningFoods();
      final consumed = await _todayTotals();
      _consumed = consumed;
      final targets = NutritionService.calculateRemainingTargets(
        profile: profile,
        consumed: consumed,
      );
      final pendingSlots = adapt
          ? _meals
                .where((meal) => meal.status == 'planned')
                .map((meal) => meal.mealType)
                .toList()
          : _slotsForCount(_mealCount);
      if (adapt && pendingSlots.isEmpty) {
        setState(
          () => _message = 'There are no remaining planned meals to adapt.',
        );
        return;
      }
      final generated = DailyMealPlannerService.generate(
        foods: foods,
        calorieTarget: targets.remainingCalories,
        proteinTarget: targets.remainingProtein,
        budget: targets.remainingBudget,
        dietaryPreference: profile.dietaryPreference,
        mealSlots: pendingSlots,
        excludedIngredients: _excludedIngredients,
      );
      if (adapt) {
        if (!mounted) return;
        final proposedCost = generated.fold<double>(
          0,
          (sum, meal) => sum + meal.cost,
        );
        final proposedProtein = generated.fold<double>(
          0,
          (sum, meal) => sum + meal.protein,
        );
        final proposedCalories = generated.fold<double>(
          0,
          (sum, meal) => sum + meal.calories,
        );
        final accepted = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Review your adapted day'),
            content: SingleChildScrollView(
              child: Text(
                '${generated.length} remaining meals · ${proposedCalories.round()} kcal · ${proposedProtein.round()} g protein · ${Formatters.currency(proposedCost)}\n\n'
                '${generated.map((meal) => '${meal.mealType}: ${meal.food.name} (${Formatters.currency(meal.cost)})').join('\n')}\n\n'
                'Remaining budget after these meals: ${Formatters.currency(targets.remainingBudget - proposedCost)}',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep current plan'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Accept changes'),
              ),
            ],
          ),
        );
        if (accepted != true || !mounted) return;
        _meals = [
          ..._meals.where((meal) => meal.status != 'planned'),
          ...generated,
        ];
      } else {
        _meals = generated;
      }
      await _persist();
      if (_meals.isEmpty) {
        _message =
            'No plan fits the remaining target and budget. Review your food prices or adjust your targets.';
      } else if (generated.length < pendingSlots.length) {
        _message =
            'Only ${generated.length} of ${pendingSlots.length} meal slots fit the current budget and food options.';
      }
    } catch (_) {
      _message =
          'Could not create the plan. Check the local food catalogue and try again.';
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _setStatus(int index, String status) async {
    final meal = _meals[index];
    try {
      if (status == 'logged') {
        final entry = MealEntry.fromFoodItem(
          food: meal.food,
          entryDate: _today,
          mealType: meal.mealType,
          quantity: meal.quantity,
          linkToCatalogue: meal.food.entryType != 'Recipe',
        );
        await context.read<MealProvider>().addMeal(entry);
        _consumed = await _todayTotals();
      }
      setState(() => _meals[index] = meal.copyWith(status: status));
      await _persist();
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Meal could not be saved. It remains in your plan.',
        );
      }
    }
  }

  Future<void> _adjustQuantity(int index, double factor) async {
    final meal = _meals[index];
    final step = meal.food.measurementUnit == 'serving'
        ? 0.25
        : meal.food.measurementUnit == AppConstants.unitPiece
        ? 1.0
        : 25.0;
    final next = (meal.quantity + step * factor).clamp(step, 2000).toDouble();
    setState(() => _meals[index] = meal.copyWith(quantity: next));
    await _persist();
  }

  Future<void> _chooseSubstitution(int index) async {
    final current = _meals[index];
    final profile = context.read<ProfileProvider>().profile;
    final alternatives = DailyMealPlannerService.substitutions(
      current: current.food,
      foods: _planningFoods(),
      dietaryPreference: profile.dietaryPreference,
      excludedIngredients: _excludedIngredients,
    );
    if (alternatives.isEmpty) {
      setState(
        () => _message =
            'No lower-cost foods with similar nutrition match your current diet filter.',
      );
      return;
    }
    final selected = await showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Lower-cost alternatives'),
              subtitle: Text(
                'Similar protein, comparable calories, diet matched.',
              ),
            ),
            ...alternatives.map(
              (food) => ListTile(
                title: Text(food.name),
                subtitle: Text(
                  '${food.proteinPerServing.toStringAsFixed(1)} g protein · ${Formatters.currency(food.costPerServing)} / serving · ${food.priceConfidence}',
                ),
                onTap: () => Navigator.pop(sheetContext, food),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(
      () => _meals[index] = current.copyWith(
        food: selected,
        quantity: selected.servingSize,
      ),
    );
    await _persist();
  }

  Future<void> _addPendingToShoppingList() async {
    final batch = <ShoppingItem>[];
    final quantities = <String, ({double quantity, String unit})>{};
    for (final meal in _meals.where((meal) => meal.status == 'planned')) {
      final key = '${meal.food.id}|${meal.food.measurementUnit}';
      final existing = quantities[key];
      quantities[key] = (
        quantity: (existing?.quantity ?? 0) + meal.quantity,
        unit: meal.food.measurementUnit,
      );
    }
    try {
      for (final meal in _meals.where((meal) => meal.status == 'planned')) {
        final key = '${meal.food.id}|${meal.food.measurementUnit}';
        final aggregate = quantities.remove(key);
        if (aggregate != null) {
          if (meal.food.entryType == 'Recipe') {
            final recipe = context.read<PlanProvider>().recipes.firstWhere(
              (recipe) => recipe.id == -meal.food.id!,
            );
            for (final ingredient in recipe.ingredients) {
              batch.add(
                ShoppingItem(
                  name: ingredient.foodName,
                  quantity:
                      ingredient.quantity *
                      aggregate.quantity /
                      recipe.servings,
                  unit: ingredient.measurementUnit,
                ),
              );
            }
            continue;
          }
          batch.add(
            ShoppingItem(
              name: meal.food.name,
              quantity: aggregate.quantity,
              unit: aggregate.unit,
            ),
          );
        }
      }
      final requestKey =
          '$_planKey:${jsonEncode(batch.map((item) => [item.name, item.quantity, item.unit]).toList())}';
      await DatabaseHelper.instance.addShoppingBatch(requestKey, batch);
      if (!mounted) return;
      await context.read<PlanProvider>().loadAll();
      if (mounted) {
        setState(
          () => _message =
              'Shopping list saved. Repeating the same plan does not add duplicates.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'The shopping list could not be updated. Try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final pending = _meals.where((meal) => meal.status == 'planned').toList();
    final calories = pending.fold<double>(
      0,
      (sum, meal) => sum + meal.calories,
    );
    final protein = pending.fold<double>(0, (sum, meal) => sum + meal.protein);
    final cost = pending.fold<double>(0, (sum, meal) => sum + meal.cost);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's meal plan"),
        actions: [
          IconButton(
            tooltip: 'Shopping list',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ShoppingListScreen(),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                TextField(
                  controller: _exclusions,
                  enabled: !_working,
                  decoration: const InputDecoration(
                    labelText: 'Ingredients to avoid',
                    hintText: 'For example: peanut, egg, onion',
                    helperText:
                        'Comma-separated names. Applies to new suggestions; ingredient lists may be incomplete.',
                    helperMaxLines: 3,
                  ),
                  onChanged: (_) => _persist(),
                ),
                OutlinedButton.icon(
                  onPressed: _working ? null : _chooseAvailableFoods,
                  icon: const Icon(Icons.kitchen_outlined),
                  label: Text(
                    _availableFoods == null
                        ? 'Choose available foods'
                        : '${_availableFoods!.length} available foods selected',
                  ),
                ),
                const Text(
                  'Saved recipes use ingredient-based costs and expand into groceries. Pantry changes apply when generating, adapting or substituting meals.',
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Targets for ${profile.displayName}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${profile.dietaryPreference} · ${Formatters.currency(profile.dailyBudget)} daily budget',
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Food and price values are estimates; review local prices before relying on a plan.',
                        ),
                      ],
                    ),
                  ),
                ),
                if (_meals.isEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _mealCount,
                    decoration: const InputDecoration(
                      labelText: 'Meals for today',
                    ),
                    items: [3, 4, 5, 6]
                        .map(
                          (count) => DropdownMenuItem(
                            value: count,
                            child: Text('$count meals'),
                          ),
                        )
                        .toList(),
                    onChanged: _working
                        ? null
                        : (value) => setState(() => _mealCount = value ?? 4),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _working ? null : () => _generate(),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: Text(
                      _working ? 'Planning…' : 'Generate today’s plan',
                    ),
                  ),
                ] else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        alignment: WrapAlignment.spaceAround,
                        runSpacing: 12,
                        children: [
                          _PlanTotal(
                            label: 'Calories',
                            value: '${calories.round()} kcal',
                          ),
                          _PlanTotal(
                            label: 'Protein',
                            value: '${protein.round()} g',
                          ),
                          _PlanTotal(
                            label: 'Planned cost',
                            value: Formatters.currency(cost),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated remaining after plan',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${((profile.calorieTarget - _consumed.totalCalories - calories).clamp(0, double.infinity)).round()} kcal · '
                            '${((profile.proteinTarget - _consumed.totalProtein - protein).clamp(0, double.infinity)).round()} g protein · '
                            '${Formatters.currency((profile.dailyBudget - _consumed.totalCost - cost).clamp(0, double.infinity))} budget',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var index = 0; index < _meals.length; index++)
                    _mealCard(context, index),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _working ? null : () => _generate(adapt: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Adapt remaining meals'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _addPendingToShoppingList,
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Add remaining foods to shopping list'),
                  ),
                  TextButton.icon(
                    onPressed: _working ? null : () => _generate(),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Replace today’s plan'),
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _mealCard(BuildContext context, int index) {
    final meal = _meals[index];
    final done = meal.status != 'planned';
    final quantityLabel =
        meal.food.measurementUnit == AppConstants.unitPiece ||
            meal.quantity == meal.quantity.roundToDouble()
        ? meal.quantity.toStringAsFixed(0)
        : meal.quantity.toStringAsFixed(1);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meal.mealType,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (done)
                  Chip(
                    label: Text(meal.status == 'logged' ? 'Logged' : 'Skipped'),
                  ),
              ],
            ),
            Text(
              meal.food.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '$quantityLabel ${meal.food.measurementUnit} · ${meal.calories.round()} kcal · ${meal.protein.toStringAsFixed(1)} g protein',
            ),
            Text(
              '${Formatters.currency(meal.cost)} estimated · ${meal.food.priceRegion}',
            ),
            if (!done) ...[
              Row(
                children: [
                  IconButton(
                    onPressed: () => _adjustQuantity(index, -1),
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Reduce portion',
                  ),
                  IconButton(
                    onPressed: () => _adjustQuantity(index, 1),
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Increase portion',
                  ),
                  TextButton.icon(
                    onPressed: () => _chooseSubstitution(index),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Swap'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _setStatus(index, 'skipped'),
                    child: const Text('Skip meal'),
                  ),
                  FilledButton(
                    onPressed: () => _setStatus(index, 'logged'),
                    child: const Text('Log meal'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanTotal extends StatelessWidget {
  const _PlanTotal({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 3),
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}
