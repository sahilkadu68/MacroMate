import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/recommendation.dart';
import '../../providers/food_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/protein_finder_provider.dart';
import '../../services/nutrition_service.dart';
import '../../shared/widgets/empty_state_view.dart';
import 'widgets/recommendation_card.dart';

class ProteinFinderScreen extends StatefulWidget {
  const ProteinFinderScreen({super.key});

  @override
  State<ProteinFinderScreen> createState() => _ProteinFinderScreenState();
}

class _ProteinFinderScreenState extends State<ProteinFinderScreen> {
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();

  late String _dietPreference;
  int _maxItems = 2;
  bool _initializedWithDefaults = false;

  @override
  void initState() {
    super.initState();
    _dietPreference = AppConstants.dietVeg;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final foodProvider = Provider.of<FoodProvider>(context);
    if (!_initializedWithDefaults && foodProvider.allFoods.isNotEmpty) {
      final profile = Provider.of<ProfileProvider>(context, listen: false).profile;
      final mealSummary = Provider.of<MealProvider>(context, listen: false).dailyTotals;
      final remaining = NutritionService.calculateRemainingTargets(
        profile: profile,
        consumed: mealSummary,
      );

      final pTarget = remaining.remainingProtein > 5.0
          ? remaining.remainingProtein
          : 40.0;
      final bTarget = remaining.remainingBudget > 10.0
          ? remaining.remainingBudget
          : 50.0;

      _proteinController.text = pTarget.round().toString();
      _budgetController.text = bTarget.round().toString();
      _dietPreference = profile.dietaryPreference;
      _initializedWithDefaults = true;

      // Automatically generate initial recommendations once foods are available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _triggerSearch();
      });
    }
  }

  @override
  void dispose() {
    _proteinController.dispose();
    _budgetController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    final finderProvider = Provider.of<ProteinFinderProvider>(
      context,
      listen: false,
    );

    final p = double.tryParse(_proteinController.text.trim()) ?? 35.0;
    final b = double.tryParse(_budgetController.text.trim()) ?? 50.0;
    final c = double.tryParse(_caloriesController.text.trim());

    finderProvider.findCombos(
      allFoods: foodProvider.allFoods,
      remainingProtein: p,
      remainingBudget: b,
      maxCalories: c,
      dietaryPreference: _dietPreference,
      maxItems: _maxItems,
    );
  }

  void _handleAddToDiary(RecommendationPlan plan, String mealType) async {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    final finderProvider = Provider.of<ProteinFinderProvider>(
      context,
      listen: false,
    );

    try {
      await finderProvider.addPlanToDiary(
        plan: plan,
        mealProvider: mealProvider,
        mealType: mealType,
        date: mealProvider.selectedDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'Added ${plan.items.length} items to $mealType diary!',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to add to diary: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finderProvider = Provider.of<ProteinFinderProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Protein Finder')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optimizer Config Card
            Card(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.tune,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Configure Optimization Targets',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Protein target & Budget target
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _proteinController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Protein Needed',
                              suffixText: 'g',
                            ),
                            onSubmitted: (_) => _triggerSearch(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _budgetController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Max Budget',
                              prefixText: '₹ ',
                            ),
                            onSubmitted: (_) => _triggerSearch(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Optional Max Calories & Diet Preference
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _caloriesController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Max Calories',
                              hintText: 'Optional',
                              suffixText: 'kcal',
                            ),
                            onSubmitted: (_) => _triggerSearch(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _dietPreference,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Diet Type',
                            ),
                            items: AppConstants.dietaryPreferences.map((d) {
                              return DropdownMenuItem(
                                value: d,
                                child: Text(
                                  d,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _dietPreference = val);
                                _triggerSearch();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Combination size chips (1, 2, or 3 items)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          'Combo Size:',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                        ...[1, 2, 3].map((count) {
                          final selected = _maxItems == count;
                          return ChoiceChip(
                            label: Text('$count item${count > 1 ? "s" : ""}'),
                            selected: selected,
                            visualDensity: VisualDensity.compact,
                            onSelected: (val) {
                              if (val) {
                                setState(() => _maxItems = count);
                                _triggerSearch();
                              }
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _triggerSearch,
                      icon: const Icon(Icons.bolt, size: 18),
                      label: const Text('Find Budget Combinations'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Results Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recommended Combinations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (finderProvider.recommendations.isNotEmpty)
                  Text(
                    '${finderProvider.recommendations.length} options',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Loading / Empty / Results List
            if (finderProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (finderProvider.recommendations.isEmpty)
              EmptyStateView(
                icon: Icons.search_off,
                title: 'No Matching Combinations',
                message:
                    'No combination met your exact constraints. Try increasing your budget or allowing a higher calorie ceiling.',
                actionLabel: 'Try Relaxed Settings',
                onAction: () {
                  _budgetController.text = '100';
                  _triggerSearch();
                },
              )
            else
              ...finderProvider.recommendations.map((plan) {
                return RecommendationCard(
                  plan: plan,
                  onAddToDiary: _handleAddToDiary,
                );
              }),
          ],
        ),
      ),
    );
  }
}
