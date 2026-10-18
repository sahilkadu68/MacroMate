import 'package:flutter_test/flutter_test.dart';
import 'package:macromate_india/core/constants/app_constants.dart';
import 'package:macromate_india/data/models/meal_entry.dart';
import 'package:macromate_india/data/models/user_profile.dart';
import 'package:macromate_india/services/nutrition_service.dart';

void main() {
  group('NutritionService Unit Tests', () {
    test('calculateNutrient scales linearly with quantity', () {
      // 52g protein per 100g -> 50g serving should be 26g
      final protein = NutritionService.calculateNutrient(
        nutrientPer100: 52.0,
        quantity: 50.0,
      );
      expect(protein, 26.0);

      // 0 quantity or negative returns 0.0
      expect(
        NutritionService.calculateNutrient(nutrientPer100: 52.0, quantity: 0.0),
        0.0,
      );
      expect(
        NutritionService.calculateNutrient(
          nutrientPer100: 52.0,
          quantity: -10.0,
        ),
        0.0,
      );
    });

    test('calculateServingCost computes accurate price scaling in INR', () {
      // ₹120 per 1000g basis -> 250g serving should be ₹30.0
      final cost = NutritionService.calculateServingCost(
        unitPrice: 120.0,
        priceBasis: 1000.0,
        quantity: 250.0,
      );
      expect(cost, 30.0);

      // Edge case: 0 price or negative basis
      expect(
        NutritionService.calculateServingCost(
          unitPrice: 0,
          priceBasis: 1000,
          quantity: 100,
        ),
        0.0,
      );
      expect(
        NutritionService.calculateServingCost(
          unitPrice: 120,
          priceBasis: 0,
          quantity: 100,
        ),
        0.0,
      );
    });

    test(
      'calculateProteinEfficiency prevents division by zero and handles edge cases',
      () {
        // 52g protein for ₹12 cost -> 4.333... g/₹
        final eff = NutritionService.calculateProteinEfficiency(
          proteinGrams: 52.0,
          costRupees: 12.0,
        );
        expect(eff, isNotNull);
        expect(eff!, closeTo(4.333, 0.01));

        // Cost is 0 or negative -> must return null rather than Infinity or crash
        expect(
          NutritionService.calculateProteinEfficiency(
            proteinGrams: 20.0,
            costRupees: 0.0,
          ),
          isNull,
        );
        expect(
          NutritionService.calculateProteinEfficiency(
            proteinGrams: 20.0,
            costRupees: -5.0,
          ),
          isNull,
        );
        expect(
          NutritionService.calculateProteinEfficiency(
            proteinGrams: 0.0,
            costRupees: 10.0,
          ),
          isNull,
        );
      },
    );

    test('calculateDailyTotals aggregates multiple meals accurately', () {
      final entries = [
        MealEntry(
          foodNameSnapshot: 'Soya Chunks',
          entryDate: DateTime.now(),
          mealType: AppConstants.mealLunch,
          quantity: 50,
          caloriesSnapshot: 172.5,
          proteinSnapshot: 26.0,
          carbsSnapshot: 16.5,
          fatSnapshot: 0.25,
          unitPriceSnapshot: 120,
          costSnapshot: 6.0,
        ),
        MealEntry(
          foodNameSnapshot: 'Paneer',
          entryDate: DateTime.now(),
          mealType: AppConstants.mealDinner,
          quantity: 100,
          caloriesSnapshot: 265.0,
          proteinSnapshot: 18.3,
          carbsSnapshot: 1.2,
          fatSnapshot: 20.8,
          unitPriceSnapshot: 400,
          costSnapshot: 40.0,
        ),
      ];

      final summary = NutritionService.calculateDailyTotals(entries);
      expect(summary.mealCount, 2);
      expect(summary.totalCalories, closeTo(437.5, 0.01));
      expect(summary.totalProtein, closeTo(44.3, 0.01));
      expect(summary.totalCarbs, closeTo(17.7, 0.01));
      expect(summary.totalFat, closeTo(21.05, 0.01));
      expect(summary.totalCost, 46.0);
      expect(summary.overallProteinPerRupee, closeTo(44.3 / 46.0, 0.01));
    });

    test(
      'calculateRemainingTargets floors correctly at zero and prevents negative targets',
      () {
        final profile = UserProfile(
          proteinTarget: 100.0,
          calorieTarget: 2000.0,
          dailyBudget: 150.0,
        );

        final summary = DailyNutritionSummary(
          totalCalories: 1500.0,
          totalProtein: 120.0, // Over target by 20g
          totalCost: 100.0,
        );

        final remaining = NutritionService.calculateRemainingTargets(
          profile: profile,
          consumed: summary,
        );

        expect(remaining.remainingCalories, 500.0);
        expect(remaining.remainingProtein, 0.0); // Floored at 0
        expect(remaining.remainingBudget, 50.0);
      },
    );

    test('Mifflin-St Jeor equation computes correct sex-dependent BMR', () {
      // 70kg male, 175cm, 25 years old
      // Base: (10*70) + (6.25*175) - (5*25) = 700 + 1093.75 - 125 = 1668.75
      // Male (+5) = 1673.75
      final maleBmr = NutritionService.calculateMifflinStJeorBmr(
        weightKg: 70.0,
        heightCm: 175.0,
        age: 25,
        gender: 'male',
      );
      expect(maleBmr, 1673.75);

      // Female (-161) = 1507.75
      final femaleBmr = NutritionService.calculateMifflinStJeorBmr(
        weightKg: 70.0,
        heightCm: 175.0,
        age: 25,
        gender: 'female',
      );
      expect(femaleBmr, 1507.75);
    });

    test(
      'TDEE and Goal calories calculations apply documented multipliers',
      () {
        const bmr = 1600.0;
        final tdee = NutritionService.calculateTdee(
          bmr: bmr,
          activityLevel: AppConstants.activityModerate, // 1.55 multiplier
        );
        expect(tdee, 2480.0);

        // Cut (-400 kcal)
        final cutCals = NutritionService.calculateGoalCalories(
          tdee: tdee,
          goal: AppConstants.goalLose,
        );
        expect(cutCals, 2080.0);

        // Bulk (+350 kcal)
        final bulkCals = NutritionService.calculateGoalCalories(
          tdee: tdee,
          goal: AppConstants.goalGain,
        );
        expect(bulkCals, 2830.0);
      },
    );
  });
}
