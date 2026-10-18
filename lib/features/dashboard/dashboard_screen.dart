import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/meal_entry.dart';
import '../../providers/meal_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/tracking_provider.dart';
import '../meal_logging/log_meal_screen.dart';
import '../navigation/main_scaffold.dart';
import 'widgets/budget_card.dart';
import 'widgets/date_selector_bar.dart';
import 'widgets/macro_progress_card.dart';
import 'widgets/meal_section.dart';
import 'widgets/water_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final mealProvider = Provider.of<MealProvider>(context);
    final trackingProvider = Provider.of<TrackingProvider>(context);

    final profile = profileProvider.profile;
    final summary = mealProvider.dailyTotals;
    final selectedDate = mealProvider.selectedDate;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.appName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Welcome back, ${profile.displayName}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt, color: AppColors.secondary),
            tooltip: 'Open Protein Finder',
            onPressed: () => _openProteinFinder(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await mealProvider.loadMealsForSelectedDate();
          await trackingProvider.loadAllForDate(selectedDate);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date selector bar
              DateSelectorBar(
                selectedDate: selectedDate,
                onDateChanged: (newDate) {
                  mealProvider.setSelectedDate(newDate);
                  trackingProvider.setSelectedDate(newDate);
                },
              ),
              const SizedBox(height: 12),

              // Macro targets card
              MacroProgressCard(profile: profile, summary: summary),
              const SizedBox(height: 12),

              // Student daily budget card
              BudgetCard(
                profile: profile,
                summary: summary,
                onOpenProteinFinder: () => _openProteinFinder(context),
              ),
              const SizedBox(height: 12),

              // Dynamic Daily Insights Card (if meals are logged)
              if (mealProvider.dailyEntries.isNotEmpty)
                _buildInsightCard(context, mealProvider),

              // Water tracker quick widget
              WaterCard(
                consumedMl: trackingProvider.todayWaterMl,
                targetMl: profile.waterTarget,
                onAddWater: (amount) => trackingProvider.addWater(amount),
              ),
              const SizedBox(height: 12),

              // Meal diary sections
              MealSection(
                mealType: AppConstants.mealBreakfast,
                entries: mealProvider.getEntriesForMealType(
                  AppConstants.mealBreakfast,
                ),
                onAddFood: (slot) => _openLogMeal(context, slot, selectedDate),
                onEditMeal: (entry) =>
                    _openEditMeal(context, entry, selectedDate),
                onDeleteMeal: (id) => mealProvider.deleteMeal(id),
              ),
              const SizedBox(height: 10),

              MealSection(
                mealType: AppConstants.mealLunch,
                entries: mealProvider.getEntriesForMealType(
                  AppConstants.mealLunch,
                ),
                onAddFood: (slot) => _openLogMeal(context, slot, selectedDate),
                onEditMeal: (entry) =>
                    _openEditMeal(context, entry, selectedDate),
                onDeleteMeal: (id) => mealProvider.deleteMeal(id),
              ),
              const SizedBox(height: 10),

              MealSection(
                mealType: AppConstants.mealDinner,
                entries: mealProvider.getEntriesForMealType(
                  AppConstants.mealDinner,
                ),
                onAddFood: (slot) => _openLogMeal(context, slot, selectedDate),
                onEditMeal: (entry) =>
                    _openEditMeal(context, entry, selectedDate),
                onDeleteMeal: (id) => mealProvider.deleteMeal(id),
              ),
              const SizedBox(height: 10),

              MealSection(
                mealType: AppConstants.mealSnack,
                entries: mealProvider.getEntriesForMealType(
                  AppConstants.mealSnack,
                ),
                onAddFood: (slot) => _openLogMeal(context, slot, selectedDate),
                onEditMeal: (entry) =>
                    _openEditMeal(context, entry, selectedDate),
                onDeleteMeal: (id) => mealProvider.deleteMeal(id),
              ),
              const SizedBox(height: 80), // Padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () =>
            _openLogMeal(context, AppConstants.mealLunch, selectedDate),
        icon: const Icon(Icons.add),
        label: const Text('Log Food'),
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, MealProvider mealProvider) {
    final theme = Theme.of(context);
    final topProtein = mealProvider.topProteinEntry;
    final bestEff = mealProvider.mostEfficientEntry;

    if (topProtein == null && bestEff == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: theme.colorScheme.primaryContainer.withAlpha(50),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Today\'s Nutrition & Budget Insights',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (topProtein != null)
                Text(
                  '• Top Protein: ${topProtein.foodNameSnapshot} gave you ${Formatters.grams(topProtein.proteinSnapshot)} protein (${topProtein.caloriesSnapshot.round()} kcal).',
                  style: const TextStyle(fontSize: 12),
                ),
              if (bestEff != null && bestEff.proteinPerRupee != null) ...[
                const SizedBox(height: 4),
                Text(
                  '• Best Budget Saver: ${bestEff.foodNameSnapshot} delivered ${Formatters.efficiency(bestEff.proteinPerRupee)} (Cost: ${Formatters.currency(bestEff.costSnapshot)}).',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openLogMeal(BuildContext context, String mealType, DateTime date) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LogMealScreen(initialMealType: mealType, entryDate: date),
      ),
    );
  }

  void _openEditMeal(BuildContext context, MealEntry entry, DateTime date) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LogMealScreen(
          initialMealType: entry.mealType,
          entryDate: date,
          existingEntry: entry,
        ),
      ),
    );
  }

  void _openProteinFinder(BuildContext context) {
    MainScaffold.of(context)?.switchTab(2);
  }
}
