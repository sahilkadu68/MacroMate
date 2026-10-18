import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

class EfficiencyBadge extends StatelessWidget {
  final double? efficiency; // protein per rupee
  final bool compact;

  const EfficiencyBadge({
    super.key,
    required this.efficiency,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (efficiency == null || efficiency! <= 0) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(30),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'N/A',
          style: TextStyle(
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    final eff = efficiency!;
    Color badgeColor;
    Color textColor;

    if (eff >= 1.2) {
      badgeColor = AppColors.highEfficiency.withAlpha(35);
      textColor = AppColors.highEfficiency;
    } else if (eff >= 0.6) {
      badgeColor = AppColors.midEfficiency.withAlpha(35);
      textColor = AppColors.midEfficiency;
    } else {
      badgeColor = Colors.blueGrey.withAlpha(30);
      textColor = Colors.blueGrey;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: compact ? 12 : 14, color: textColor),
          const SizedBox(width: 2),
          Text(
            Formatters.efficiency(eff),
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class DietaryBadge extends StatelessWidget {
  final String classification;
  final bool showLabel;

  const DietaryBadge({
    super.key,
    required this.classification,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    if (classification == AppConstants.dietVeg) {
      color = AppColors.vegGreen;
      label = 'Veg';
    } else if (classification == AppConstants.dietEgg) {
      color = AppColors.eggYellow;
      label = 'Egg';
    } else {
      color = AppColors.nonVegRed;
      label = 'Non-Veg';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        border: Border.all(color: color.withAlpha(80), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
