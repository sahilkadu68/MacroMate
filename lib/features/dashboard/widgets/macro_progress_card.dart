import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
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
    final remaining = NutritionService.calculateRemainingTargets(
      profile: profile,
      consumed: summary,
    );

    final calRatio = profile.calorieTarget > 0
        ? (summary.totalCalories / profile.calorieTarget).clamp(0.0, 1.0)
        : 0.0;
    final protRatio = profile.proteinTarget > 0
        ? (summary.totalProtein / profile.proteinTarget).clamp(0.0, 1.0)
        : 0.0;
    final carbRatio = profile.carbohydrateTarget > 0
        ? (summary.totalCarbs / profile.carbohydrateTarget).clamp(0.0, 1.0)
        : 0.0;
    final fatRatio = profile.fatTarget > 0
        ? (summary.totalFat / profile.fatTarget).clamp(0.0, 1.0)
        : 0.0;

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
                    'Daily Nutrition Targets',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${Formatters.percentage(summary.totalProtein / (profile.proteinTarget > 0 ? profile.proteinTarget : 1))} Protein Hit',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Calories Spotlight
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
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
                        const Icon(
                          Icons.local_fire_department,
                          size: 18,
                          color: AppColors.calories,
                        ),
                        Text(
                          '${summary.totalCalories.round()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calories Consumed',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          children: [
                            TextSpan(
                              text: '${summary.totalCalories.round()} ',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: '/ ${profile.calorieTarget.round()} kcal',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface.withAlpha(
                                  150,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remaining.remainingCalories > 0
                            ? '${remaining.remainingCalories.round()} kcal remaining today'
                            : 'Target achieved! (+${(summary.totalCalories - profile.calorieTarget).round()} surplus)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: remaining.remainingCalories > 0
                              ? AppColors.calories
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Three Macro Progress Bars
            _buildMacroRow(
              context: context,
              label: 'Protein',
              consumed: summary.totalProtein,
              target: profile.proteinTarget,
              ratio: protRatio,
              color: AppColors.protein,
              unit: 'g',
            ),
            const SizedBox(height: 12),
            _buildMacroRow(
              context: context,
              label: 'Carbs',
              consumed: summary.totalCarbs,
              target: profile.carbohydrateTarget,
              ratio: carbRatio,
              color: AppColors.carbs,
              unit: 'g',
            ),
            const SizedBox(height: 12),
            _buildMacroRow(
              context: context,
              label: 'Fat',
              consumed: summary.totalFat,
              target: profile.fatTarget,
              ratio: fatRatio,
              color: AppColors.fat,
              unit: 'g',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow({
    required BuildContext context,
    required String label,
    required double consumed,
    required double target,
    required double ratio,
    required Color color,
    required String unit,
  }) {
    final theme = Theme.of(context);
    final remaining = (target - consumed).clamp(0.0, 9999.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Flexible(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: '${consumed.toStringAsFixed(1)}$unit ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: '/ ${target.toStringAsFixed(0)}$unit',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                    TextSpan(
                      text: ' (${remaining.toStringAsFixed(1)}$unit left)',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: color.withAlpha(35),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
