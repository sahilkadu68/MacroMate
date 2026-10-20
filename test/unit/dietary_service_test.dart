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

    test('Eggetarian user can consume veg foods and eggs, but never meat or fish', () {
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
    });

    test('Non-Vegetarian user is permitted all food types (veg, egg, non-veg)', () {
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
    });

    test('applyCatalogueFilter applies category chips correctly across Indian seed foods', () {
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
    });
  });
}
