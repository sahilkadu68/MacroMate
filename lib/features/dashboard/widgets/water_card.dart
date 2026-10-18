import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class WaterCard extends StatelessWidget {
  final double consumedMl;
  final double targetMl;
  final ValueChanged<double> onAddWater;

  const WaterCard({
    super.key,
    required this.consumedMl,
    required this.targetMl,
    required this.onAddWater,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = targetMl > 0 ? (consumedMl / targetMl).clamp(0.0, 1.0) : 0.0;
    final remaining = (targetMl - consumedMl).clamp(0.0, 99999.0);

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
                        color: AppColors.water.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        size: 18,
                        color: AppColors.water,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hydration',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  remaining > 0
                      ? '${Formatters.ml(remaining)} left'
                      : 'Hydration Met!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: remaining > 0 ? AppColors.water : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    children: [
                      TextSpan(
                        text: '${Formatters.ml(consumedMl)} ',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: '/ ${Formatters.ml(targetMl)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(64, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => onAddWater(250.0),
                      child: const Text(
                        '+250ml',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(64, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => onAddWater(500.0),
                      child: const Text(
                        '+500ml',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: AppColors.water.withAlpha(35),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.water,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
