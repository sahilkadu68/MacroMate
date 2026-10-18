import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/food_item.dart';
import '../../../shared/widgets/metric_badge.dart';

class FoodListTile extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onTap;

  const FoodListTile({super.key, required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dietary indicator
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: DietaryBadge(
                classification: food.dietaryClassification,
                showLabel: false,
              ),
            ),
            const SizedBox(width: 12),

            // Food Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (food.isCustom)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Custom',
                            style: TextStyle(fontSize: 10, color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${food.category} • ${food.preparationBasis}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${food.caloriesPer100.round()} kcal',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.calories,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${food.proteinPer100}g P',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.protein,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${food.carbsPer100}g C',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.carbs,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${food.fatPer100}g F',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.fat,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price & Efficiency Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${Formatters.currency(food.costPer100)} /100${food.measurementUnit}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                EfficiencyBadge(
                  efficiency: food.proteinPerRupee,
                  compact: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
