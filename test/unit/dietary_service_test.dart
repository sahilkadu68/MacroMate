import 'package:flutter_test/flutter_test.dart';
import 'package:macromate_india/core/constants/app_constants.dart';
import 'package:macromate_india/data/seed/indian_foods_seed.dart';
import 'package:macromate_india/services/dietary_service.dart';

void main() {
  group('DietaryService Unit Tests', () {
    test('Vegetarian user is strictly protected from non-veg and eggs', () {
      expect(
        DietaryService.isFoodEligible(
          foodClassification: AppConstants.dietVeg,
          userPreference: AppConstants.dietVeg,
        ),
        isTrue,
      );
      expect(
        DietaryService.isFoodEligible(
          foodClassification: AppConstants.dietEgg,
          userPreference: AppConstants.dietVeg,
        ),
        isFalse,
      );
      expect(
        DietaryService.isFoodEligible(
          foodClassification: AppConstants.dietNonVeg,
          userPreference: AppConstants.dietVeg,
        ),
        isFalse,
      );
    });

    test(
      'Eggetarian user can consume veg foods and eggs, but never meat or fish',
      () {
        expect(
          DietaryService.isFoodEligible(
            foodClassification: AppConstants.dietVeg,
            userPreference: AppConstants.dietEgg,
          ),
          isTrue,
        );
        expect(
          DietaryService.isFoodEligible(
            foodClassification: AppConstants.dietEgg,
            userPreference: AppConstants.dietEgg,
          ),
          isTrue,
        );
        expect(
          DietaryService.isFoodEligible(
            foodClassification: AppConstants.dietNonVeg,
            userPreference: AppConstants.dietEgg,
          ),
          isFalse,
        );
      },
    );

    test(
      'Non-Vegetarian user is permitted all food types (veg, egg, non-veg)',
      () {
        expect(
          DietaryService.isFoodEligible(
            foodClassification: AppConstants.dietVeg,
            userPreference: AppConstants.dietNonVeg,
          ),
          isTrue,
        );
        expect(
          DietaryService.isFoodEligible(
            foodClassification: AppConstants.dietEgg,
            userPreference: AppConstants.dietNonVeg,
          ),
          isTrue,
        );
        expect(
          DietaryService.isFoodEligible(
            foodClassification: AppConstants.dietNonVeg,
            userPreference: AppConstants.dietNonVeg,
          ),
          isTrue,
        );
      },
    );

    test('All preference permits every food category unconditionally', () {
      expect(
        DietaryService.isFoodEligible(
          foodClassification: AppConstants.dietVeg,
          userPreference: AppConstants.dietAll,
        ),
        isTrue,
      );
      expect(
        DietaryService.isFoodEligible(
          foodClassification: AppConstants.dietEgg,
          userPreference: AppConstants.dietAll,
        ),
        isTrue,
      );
      expect(
        DietaryService.isFoodEligible(
          foodClassification: AppConstants.dietNonVeg,
          userPreference: AppConstants.dietAll,
        ),
        isTrue,
      );
    });

    test(
      'applyCatalogueFilter supports new short filters (All, Veg, Egg, Non-Veg)',
      () {
        final foods = IndianFoodsSeed.initialFoods;

        final allFoods = DietaryService.applyCatalogueFilter(
          foods: foods,
          selectedFilter: DietaryService.filterAll,
        );
        expect(allFoods.length, equals(foods.length));

        final veg = DietaryService.applyCatalogueFilter(
          foods: foods,
          selectedFilter: DietaryService.filterVeg,
        );
        for (final f in veg) {
          expect(f.dietaryClassification, AppConstants.dietVeg);
        }

        final egg = DietaryService.applyCatalogueFilter(
          foods: foods,
          selectedFilter: DietaryService.filterEgg,
        );
        for (final f in egg) {
          expect(f.dietaryClassification, AppConstants.dietEgg);
        }

        final nonVeg = DietaryService.applyCatalogueFilter(
          foods: foods,
          selectedFilter: DietaryService.filterNonVeg,
        );
        for (final f in nonVeg) {
          expect(f.dietaryClassification, AppConstants.dietNonVeg);
        }
      },
    );

    test(
      'applyCatalogueFilter applies category chips correctly across Indian seed foods',
      () {
        final foods = IndianFoodsSeed.initialFoods;

        final vegOnly = DietaryService.applyCatalogueFilter(
          foods: foods,
          selectedFilter: DietaryService.filterVegOnly,
        );
        for (final f in vegOnly) {
          expect(f.dietaryClassification, AppConstants.dietVeg);
        }

        final eggsOnly = DietaryService.applyCatalogueFilter(
          foods: foods,
          selectedFilter: DietaryService.filterEggsOnly,
        );
        for (final f in eggsOnly) {
          expect(f.dietaryClassification, AppConstants.dietEgg);
        }

        final meatFishOnly = DietaryService.applyCatalogueFilter(
          foods: foods,
          selectedFilter: DietaryService.filterMeatFish,
        );
        for (final f in meatFishOnly) {
          expect(f.dietaryClassification, AppConstants.dietNonVeg);
        }

        final highProtein = DietaryService.applyCatalogueFilter(
          foods: foods,
          selectedFilter: DietaryService.filterHighProtein,
        );
        for (final f in highProtein) {
          expect(f.proteinPer100, greaterThanOrEqualTo(15.0));
        }

        final budgetSavers = DietaryService.applyCatalogueFilter(
          foods: foods,
          selectedFilter: DietaryService.filterBudgetSaver,
        );
        for (final f in budgetSavers) {
          expect(f.proteinPerRupee, isNotNull);
          expect(f.proteinPerRupee!, greaterThanOrEqualTo(1.2));
        }
      },
    );

    test('FoodItem calculates cost and macros per serving accurately', () {
      final chickenBreast = IndianFoodsSeed.initialFoods.firstWhere(
        (f) => f.name.contains('Chicken Breast (Boiled / Grilled, Cooked)'),
      );
      expect(chickenBreast.servingSize, equals(120.0));
      expect(chickenBreast.costPerServing, closeTo(48.0, 0.1));
      expect(chickenBreast.proteinPerServing, closeTo(37.2, 0.1));
      expect(chickenBreast.caloriesPerServing, closeTo(198.0, 0.1));

      final rawEgg = IndianFoodsSeed.initialFoods.firstWhere(
        (f) => f.name.contains('Whole Boiled Egg'),
      );
      expect(rawEgg.costPerServing, closeTo(7.0, 0.1));
      expect(rawEgg.proteinPerServing, closeTo(6.5, 0.1));
    });
  });
}
