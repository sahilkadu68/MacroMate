import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/recommendation.dart';
import '../../../shared/widgets/metric_badge.dart';

class RecommendationCard extends StatelessWidget {
  final RecommendationPlan plan;
  final Function(RecommendationPlan plan, String mealType) onAddToDiary;

  const RecommendationCard({
    super.key,
    required this.plan,
    required this.onAddToDiary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eff = plan.overallProteinPerRupee;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: plan.isFeasible
              ? AppColors.primary.withAlpha(80)
              : Colors.amber.shade700.withAlpha(120),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Rank reason / Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: plan.isFeasible
                              ? AppColors.primary.withAlpha(20)
                              : Colors.amber.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          plan.isFeasible
                              ? 'Feasible Combo'
                              : 'Closest Budget Match',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: plan.isFeasible
                                ? AppColors.primary
                                : Colors.amber.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        plan.rankReason,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                EfficiencyBadge(efficiency: eff),
              ],
            ),
            const SizedBox(height: 12),

            // Infeasibility note if budget too low
            if (plan.infeasibilityNote != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plan.infeasibilityNote!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Food Items in this Combination
            Text(
              'Recommended Servings',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
            const SizedBox(height: 6),

            ...plan.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.protein,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: '${item.food.name} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '(${item.quantity.toInt()}${item.food.measurementUnit})',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withAlpha(
                                  150,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '${item.protein.toStringAsFixed(1)}g P',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.protein,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Formatters.currency(item.cost),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 20),

            // Combination Stats Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildComboStat(
                  'Total Cost',
                  Formatters.currency(plan.totalCost),
                  AppColors.secondary,
                ),
                _buildComboStat(
                  'Total Protein',
                  '${plan.totalProtein.toStringAsFixed(1)}g',
                  AppColors.protein,
                ),
                _buildComboStat(
                  'Calories',
                  '${plan.totalCalories.round()} kcal',
                  AppColors.calories,
                ),
                _buildComboStat(
                  'Carbs / Fat',
                  '${plan.totalCarbs.round()}g / ${plan.totalFat.round()}g',
                  Colors.blueGrey,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Add to Diary Action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    icon: const Icon(Icons.add_task, size: 16),
                    label: const Text(
                      'Add Combination to Diary',
                      style: TextStyle(fontSize: 13),
                    ),
                    onPressed: () => _showMealSlotPicker(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMealSlotPicker(BuildContext context) {
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
                  child: Text(
                    'Select Meal Slot',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                ...AppConstants.mealTypes.map((type) {
                  return ListTile(
                    leading: const Icon(
                      Icons.restaurant,
                      color: AppColors.primary,
                    ),
                    title: Text(type),
                    onTap: () {
                      Navigator.pop(ctx);
                      onAddToDiary(plan, type);
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

  Widget _buildComboStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
