import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/meal_entry.dart';
import '../../providers/meal_provider.dart';
import '../../shared/widgets/empty_state_view.dart';
import 'log_meal_screen.dart';

class MealLogScreen extends StatelessWidget {
  const MealLogScreen({super.key});

  Future<void> _openLogger(
    BuildContext context,
    DateTime date,
    String mealType, {
    MealEntry? existing,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LogMealScreen(
          initialMealType: mealType,
          entryDate: date,
          existingEntry: existing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meals = context.watch<MealProvider>();
    final date = meals.selectedDate;
    final mealTypes = AppConstants.mealTypes;
    return Scaffold(
      appBar: AppBar(title: const Text('Meal log')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            Formatters.formatDate(date),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (final type in mealTypes)
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: Text('Add $type'),
                subtitle: Text(
                  '${meals.getEntriesForMealType(type).length} items logged',
                ),
                onTap: () => _openLogger(context, date, type),
              ),
            ),
          const SizedBox(height: 12),
          if (meals.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (meals.dailyEntries.isEmpty)
            const EmptyStateView(
              icon: Icons.receipt_long_outlined,
              title: 'No meals logged for this date',
              message:
                  'Add a meal above. Its nutrition and price are saved as a history snapshot.',
            )
          else ...[
            Text(
              'Logged foods',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            for (final entry in meals.dailyEntries)
              Card(
                child: ListTile(
                  title: Text(entry.foodNameSnapshot),
                  subtitle: Text(
                    '${entry.mealType} · ${entry.quantity.toStringAsFixed(0)} ${entry.measurementUnit} · ${entry.caloriesSnapshot.round()} kcal · ${entry.proteinSnapshot.toStringAsFixed(1)} g protein · ${Formatters.currency(entry.costSnapshot)}',
                  ),
                  onTap: () => _openLogger(
                    context,
                    date,
                    entry.mealType,
                    existing: entry,
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete meal entry',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: entry.id == null
                        ? null
                        : () => meals.deleteMeal(entry.id!),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
