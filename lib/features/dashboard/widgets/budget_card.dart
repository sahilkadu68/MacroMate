import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/user_profile.dart';
import '../../../services/nutrition_service.dart';

class BudgetCard extends StatelessWidget {
  final UserProfile profile;
  final DailyNutritionSummary summary;
  final VoidCallback onOpenProteinFinder;

  const BudgetCard({
    super.key,
    required this.profile,
    required this.summary,
    required this.onOpenProteinFinder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spent = summary.totalCost;
    final budget = profile.dailyBudget;
    final remainingBudget = (budget - spent).clamp(0.0, 99999.0);
    final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > budget;
    final eff = summary.overallProteinPerRupee;

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
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.currency_rupee,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Food Budget',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (eff != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.highEfficiency.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${Formatters.efficiency(eff)} avg',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.highEfficiency,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Food Expenditure',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        children: [
                          TextSpan(
                            text: '${Formatters.currency(spent)} ',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '/ ${Formatters.currency(budget)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withAlpha(140),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  isOverBudget
                      ? 'Over budget by ${Formatters.currency(spent - budget)}'
                      : '${Formatters.currency(remainingBudget)} remaining',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isOverBudget ? Colors.red : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: isOverBudget
                    ? Colors.red.withAlpha(30)
                    : AppColors.secondary.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? Colors.red : AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Protein Finder Action Button
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onOpenProteinFinder,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(50),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt,
                      size: 20,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Find Affordable Protein Combos',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Optimize remaining ${Formatters.grams(profile.proteinTarget - summary.totalProtein)} for under ${Formatters.currency(remainingBudget)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
