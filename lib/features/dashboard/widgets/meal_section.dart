import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/meal_entry.dart';
import '../../../shared/widgets/confirm_dialog.dart';

class MealSection extends StatelessWidget {
  final String mealType;
  final List<MealEntry> entries;
  final Function(String mealType) onAddFood;
  final Function(MealEntry entry) onEditMeal;
  final Function(int id) onDeleteMeal;

  const MealSection({
    super.key,
    required this.mealType,
    required this.entries,
    required this.onAddFood,
    required this.onEditMeal,
    required this.onDeleteMeal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCalories = entries.fold(
      0.0,
      (sum, e) => sum + e.caloriesSnapshot,
    );
    final totalProtein = entries.fold(0.0, (sum, e) => sum + e.proteinSnapshot);
    final totalCost = entries.fold(0.0, (sum, e) => sum + e.costSnapshot);

    IconData icon;
    switch (mealType) {
      case AppConstants.mealBreakfast:
        icon = Icons.wb_sunny_outlined;
        break;
      case AppConstants.mealLunch:
        icon = Icons.lunch_dining_outlined;
        break;
      case AppConstants.mealDinner:
        icon = Icons.nights_stay_outlined;
        break;
      default:
        icon = Icons.cookie_outlined;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      mealType,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (entries.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${Formatters.calories(totalCalories)} • ${Formatters.grams(totalProtein)} P • ${Formatters.currency(totalCost)})',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => onAddFood(mealType),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Add',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No food logged for $mealType yet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withAlpha(120),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _buildMealTile(context, entry);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTile(BuildContext context, MealEntry entry) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.foodNameSnapshot,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${entry.quantity.toInt()}${entry.measurementUnit} (${entry.preparationBasis})',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${entry.caloriesSnapshot.round()} kcal',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.calories,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.proteinSnapshot.toStringAsFixed(1)}g P',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.protein,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.carbsSnapshot.toStringAsFixed(1)}g C',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.carbs,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.fatSnapshot.toStringAsFixed(1)}g F',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.fat,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Formatters.currency(entry.costSnapshot),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (val) async {
              if (val == 'edit') {
                onEditMeal(entry);
              } else if (val == 'delete') {
                final confirmed = await ConfirmDialog.show(
                  context: context,
                  title: 'Delete Meal Entry',
                  message:
                      'Are you sure you want to remove "${entry.foodNameSnapshot}" from $mealType?',
                );
                if (confirmed && entry.id != null) {
                  onDeleteMeal(entry.id!);
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit Quantity'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
