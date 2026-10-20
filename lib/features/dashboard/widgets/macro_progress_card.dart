import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_profile.dart';
import '../../../services/nutrition_service.dart';

class MacroProgressCard extends StatelessWidget {
  final UserProfile profile;
  final DailyNutritionSummary summary;

  const MacroProgressCard({
    super.key,
    required this.profile,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calTarget = profile.calorieTarget > 0 ? profile.calorieTarget : 2000.0;
    final calConsumed = summary.totalCalories;
    final calRemaining = max(0.0, calTarget - calConsumed);
    final calRatio = (calConsumed / calTarget).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Daily Nutrition Progress',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${calConsumed.round()} / ${calTarget.round()} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withAlpha(160),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                // Single Calorie Circular Gauge
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: calRatio,
                          strokeWidth: 8,
                          backgroundColor: AppColors.calories.withAlpha(30),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.calories,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${calRemaining.round()}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            'kcal left',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),

                // Clean Macro Target Progress Bars
                Expanded(
                  child: Column(
                    children: [
                      _buildMacroBar(
                        label: 'Protein',
                        consumed: summary.totalProtein,
                        target: profile.proteinTarget,
                        color: AppColors.protein,
                        unit: 'g',
                      ),
                      const SizedBox(height: 10),
                      _buildMacroBar(
                        label: 'Carbs',
                        consumed: summary.totalCarbs,
                        target: profile.carbohydrateTarget,
                        color: AppColors.carbs,
                        unit: 'g',
                      ),
                      const SizedBox(height: 10),
                      _buildMacroBar(
                        label: 'Fat',
                        consumed: summary.totalFat,
                        target: profile.fatTarget,
                        color: AppColors.fat,
                        unit: 'g',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBar({
    required String label,
    required double consumed,
    required double target,
    required Color color,
    required String unit,
  }) {
    final validTarget = target > 0 ? target : 1.0;
    final ratio = (consumed / validTarget).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${consumed.round()}/${target.round()}$unit',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: color.withAlpha(25),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
