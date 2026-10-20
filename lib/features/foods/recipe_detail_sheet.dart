import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/meal_entry.dart';
import '../../data/models/recipe.dart';
import '../../providers/meal_provider.dart';
import '../../providers/plan_provider.dart';
import '../../shared/widgets/confirm_dialog.dart';

class RecipeDetailSheet extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailSheet({super.key, required this.recipe});

  void _logServingToMeal(BuildContext context, String mealType) async {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    final entry = MealEntry(
      foodId: null,
      foodNameSnapshot: '${recipe.name} (1 Serving)',
      entryDate: mealProvider.selectedDate,
      mealType: mealType,
      quantity: 1.0,
      measurementUnit: 'serving',
      preparationBasis: 'Cooked Recipe',
      caloriesSnapshot: recipe.perServingCalories,
      proteinSnapshot: recipe.perServingProtein,
      carbsSnapshot: recipe.perServingCarbs,
      fatSnapshot: recipe.perServingFat,
      unitPriceSnapshot: recipe.perServingCost,
      costSnapshot: recipe.perServingCost,
    );

    await mealProvider.addMeal(entry);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('Logged 1 serving of "${recipe.name}" to $mealType!'),
        ),
      );
    }
  }

  void _showMealPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text('Log Serving to Which Meal?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ...AppConstants.mealTypes.map((type) {
                  return ListTile(
                    leading: const Icon(Icons.restaurant, color: AppColors.primary),
                    title: Text(type),
                    onTap: () {
                      Navigator.pop(ctx);
                      _logServingToMeal(context, type);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planProvider = Provider.of<PlanProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    recipe.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete Recipe',
                  onPressed: () async {
                    final confirmed = await ConfirmDialog.show(
                      context: context,
                      title: 'Delete Recipe',
                      message: 'Are you sure you want to delete "${recipe.name}"?',
                    );
                    if (confirmed && recipe.id != null) {
                      await planProvider.deleteRecipe(recipe.id!);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
            if (recipe.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(recipe.description, style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150), fontSize: 12)),
            ],
            const SizedBox(height: 14),

            // Per serving stat bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Protein / serve', '${recipe.perServingProtein.toStringAsFixed(1)}g', AppColors.protein),
                  _buildStat('Calories', '${recipe.perServingCalories.round()} kcal', AppColors.calories),
                  _buildStat('Cost / serve', Formatters.currency(recipe.perServingCost), AppColors.secondary),
                  _buildStat('Servings', '${recipe.servings}', AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text('Ingredients (${recipe.ingredients.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            ...recipe.ingredients.map((ing) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${ing.foodName} (${ing.quantity.toInt()}${ing.measurementUnit})', style: const TextStyle(fontSize: 13)),
                    Text(
                      '${ing.protein.toStringAsFixed(1)}g P · ${Formatters.currency(ing.cost)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Log 1 Serving'),
                    onPressed: () => _showMealPicker(context),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                  label: const Text('Add to List'),
                  onPressed: () async {
                    await planProvider.addRecipeToShoppingList(recipe);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primary,
                          content: Text('Added ingredients of "${recipe.name}" to Shopping List!'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }
}
