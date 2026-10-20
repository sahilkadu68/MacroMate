import 'package:flutter_test/flutter_test.dart';
import 'package:macromate_india/core/constants/app_constants.dart';
import 'package:macromate_india/data/models/food_item.dart';
import 'package:macromate_india/data/seed/indian_foods_seed.dart';
import 'package:macromate_india/services/recommendation_service.dart';

void main() {
  group('RecommendationService Unit Tests', () {
    late List<FoodItem> testFoods;

    setUp(() {
      testFoods = IndianFoodsSeed.initialFoods;
    });

    test('filterEligibleFoods filters strictly by dietary preference', () {
      final vegEligible = RecommendationService.filterEligibleFoods(
        allFoods: testFoods,
        dietaryPreference: AppConstants.dietVeg,
        excludedFoodIds: [],
      );

      for (final f in vegEligible) {
        expect(f.dietaryClassification, AppConstants.dietVeg);
      }

      final eggEligible = RecommendationService.filterEligibleFoods(
        allFoods: testFoods,
        dietaryPreference: AppConstants.dietEgg,
        excludedFoodIds: [],
      );

      for (final f in eggEligible) {
        expect(
          f.dietaryClassification == AppConstants.dietVeg ||
              f.dietaryClassification == AppConstants.dietEgg,
          isTrue,
        );
      }
    });

    test('findRecommendations generates valid combinations within budget', () {
      const criteria = RecommendationCriteria(
        remainingProteinTarget: 35.0, // Need 35g protein
        remainingBudget: 30.0, // Have ₹30
        dietaryPreference: AppConstants.dietVeg,
        maxItems: 2,
      );

      final recommendations = RecommendationService.findRecommendations(
        allFoods: testFoods,
        criteria: criteria,
      );

      expect(recommendations, isNotEmpty);
      for (final plan in recommendations) {
        expect(plan.totalCost, lessThanOrEqualTo(criteria.remainingBudget));
        expect(plan.overallProteinPerRupee, isNotNull);
        expect(plan.rankReason, isNotEmpty);
      }
    });

    test(
      'findRecommendations respects optional calorie ceiling constraint',
      () {
        const criteria = RecommendationCriteria(
          remainingProteinTarget: 30.0,
          remainingBudget: 50.0,
          maxCalories: 250.0, // Hard ceiling of 250 kcal
          dietaryPreference: AppConstants.dietVeg,
          maxItems: 2,
        );

        final recommendations = RecommendationService.findRecommendations(
          allFoods: testFoods,
          criteria: criteria,
        );

        for (final plan in recommendations) {
          expect(plan.totalCalories, lessThanOrEqualTo(250.0));
        }
      },
    );

    test(
      'findRecommendations provides infeasible fallback explanation when budget is too tight',
      () {
        const criteria = RecommendationCriteria(
          remainingProteinTarget: 80.0, // Need 80g protein
          remainingBudget: 10.0, // Only ₹10 budget (impossible to reach 80g)
          dietaryPreference: AppConstants.dietVeg,
        );

        final recommendations = RecommendationService.findRecommendations(
          allFoods: testFoods,
          criteria: criteria,
        );

        expect(recommendations, isNotEmpty);
        final topPlan = recommendations.first;
        expect(topPlan.isFeasible, isFalse);
        expect(topPlan.infeasibilityNote, isNotNull);
        expect(topPlan.totalCost, lessThanOrEqualTo(10.0));
      },
    );

    test('Non-Vegetarian criteria generates combinations with animal protein heroes', () {
      const criteria = RecommendationCriteria(
        remainingProteinTarget: 40.0,
        remainingBudget: 80.0,
        dietaryPreference: AppConstants.dietNonVeg,
        maxItems: 2,
      );

      final recommendations = RecommendationService.findRecommendations(
        allFoods: testFoods,
        criteria: criteria,
      );

      expect(recommendations, isNotEmpty);
      // Verify every recommended plan has a non-veg item (e.g., Chicken Breast, Fish)
      for (final plan in recommendations) {
        final hasNonVeg = plan.items.any(
          (i) => i.food.dietaryClassification == AppConstants.dietNonVeg,
        );
        expect(hasNonVeg, isTrue);
        expect(plan.totalCost, lessThanOrEqualTo(criteria.remainingBudget));
      }
    });

    test('Eggetarian criteria generates combinations with egg protein', () {
      const criteria = RecommendationCriteria(
        remainingProteinTarget: 30.0,
        remainingBudget: 60.0,
        dietaryPreference: AppConstants.dietEgg,
        maxItems: 2,
      );

      final recommendations = RecommendationService.findRecommendations(
        allFoods: testFoods,
        criteria: criteria,
      );

      expect(recommendations, isNotEmpty);
      // Verify every recommended plan has an egg item (e.g., Whole Boiled Egg, Egg White)
      for (final plan in recommendations) {
        final hasEgg = plan.items.any(
          (i) => i.food.dietaryClassification == AppConstants.dietEgg,
        );
        expect(hasEgg, isTrue);
        expect(plan.totalCost, lessThanOrEqualTo(criteria.remainingBudget));
      }
    });
  });
}
