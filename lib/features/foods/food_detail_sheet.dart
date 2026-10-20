import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/food_item.dart';
import '../../providers/food_provider.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/metric_badge.dart';
import '../meal_logging/log_meal_screen.dart';
import 'add_edit_food_screen.dart';

class FoodDetailSheet extends StatelessWidget {
  final FoodItem food;
  final VoidCallback? onDeleted;
  final VoidCallback? onEdited;

  const FoodDetailSheet({
    super.key,
    required this.food,
    this.onDeleted,
    this.onEdited,
  });

  void _showEditPriceDialog(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    final controller = TextEditingController(text: food.estimatedUnitPrice.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Edit Price: ${food.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update price to match your local market/mess. Price is per ${food.priceQuantityBasis.toInt()}${food.measurementUnit}.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Local Price (₹)',
                  prefixText: '₹ ',
                  suffixText: '/ ${food.priceQuantityBasis.toInt()}${food.measurementUnit}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPrice = double.tryParse(controller.text.trim());
                if (newPrice != null && newPrice > 0 && food.id != null) {
                  await foodProvider.updateFoodPrice(food.id!, newPrice);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.primary,
                        content: Text('Updated price for ${food.name} to ₹$newPrice!'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Price'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foodProvider = Provider.of<FoodProvider>(context);
    final eff = food.proteinPerRupee;
    final isFav = foodProvider.isFavorite(food.id);

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
                    food.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : Colors.grey,
                  ),
                  tooltip: isFav ? 'Remove from Favourites' : 'Add to Favourites',
                  onPressed: () {
                    if (food.id != null) foodProvider.toggleFavorite(food.id!);
                  },
                ),
                DietaryBadge(classification: food.dietaryClassification),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${food.category} • Basis: ${food.preparationBasis}',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
            const SizedBox(height: 16),

            // Macro summary grid
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroStat(
                        'Calories',
                        '${food.caloriesPer100.round()} kcal',
                        AppColors.calories,
                      ),
                      _buildMacroStat(
                        'Protein',
                        '${food.proteinPer100}g',
                        AppColors.protein,
                      ),
                      _buildMacroStat(
                        'Carbs',
                        '${food.carbsPer100}g',
                        AppColors.carbs,
                      ),
                      _buildMacroStat(
                        'Fat',
                        '${food.fatPer100}g',
                        AppColors.fat,
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Estimated Cost',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${Formatters.currency(food.costPer100)} /100${food.measurementUnit}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'Protein Efficiency',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          EfficiencyBadge(efficiency: eff),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Price Reference Basis with Edit Local Price button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price Reference Basis',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${food.estimatedUnitPrice.toStringAsFixed(1)} per ${food.priceQuantityBasis.toInt()}${food.measurementUnit}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 32),
                  ),
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: const Text('Edit Local Price', style: TextStyle(fontSize: 11)),
                  onPressed: () => _showEditPriceDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (food.sourceNote.isNotEmpty) ...[
              Text(
                'Source & Verification Note',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withAlpha(160),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                food.sourceNote,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(160),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Log This Food'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LogMealScreen(entryDate: DateTime.now()),
                        ),
                      );
                    },
                  ),
                ),
                if (food.isCustom) ...[
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    icon: const Icon(Icons.edit, size: 18),
                    tooltip: 'Edit Custom Food',
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddEditFoodScreen(existingFood: food),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    tooltip: 'Delete Custom Food',
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final confirmed = await ConfirmDialog.show(
                        context: context,
                        title: 'Delete Custom Food',
                        message:
                            'Are you sure you want to delete "${food.name}" from your catalogue?',
                      );
                      if (confirmed) {
                        nav.pop();
                        onDeleted?.call();
                      }
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
