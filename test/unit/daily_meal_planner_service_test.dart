import 'package:flutter_test/flutter_test.dart';
import 'package:macromate_india/core/constants/app_constants.dart';
import 'package:macromate_india/data/models/food_item.dart';
import 'package:macromate_india/services/daily_meal_planner_service.dart';

FoodItem _food({
  required String name,
  required double protein,
  required double calories,
  required double price,
  String diet = AppConstants.dietVeg,
}) => FoodItem(
  name: name,
  category: AppConstants.catPlantProtein,
  dietaryClassification: diet,
  caloriesPer100: calories,
  proteinPer100: protein,
  carbsPer100: 15,
  fatPer100: 4,
  measurementUnit: AppConstants.unitGrams,
  preparationBasis: AppConstants.prepCooked,
  packagePrice: price,
  packageQuantity: 100,
  servingSize: 100,
  priceRegion: 'Test fixture',
);

void main() {
  group('DailyMealPlannerService', () {
    test('ingredient exclusions apply to plans and substitutions', () {
      final original = _food(
        name: 'Paneer',
        protein: 20,
        calories: 200,
        price: 40,
      );
      final peanut = _food(
        name: 'Peanut dish',
        protein: 18,
        calories: 190,
        price: 20,
      );
      expect(
        DailyMealPlannerService.generate(
          foods: [peanut],
          calorieTarget: 500,
          proteinTarget: 40,
          budget: 100,
          dietaryPreference: AppConstants.dietVeg,
          excludedIngredients: [' PEANUT '],
        ),
        isEmpty,
      );
      expect(
        DailyMealPlannerService.substitutions(
          current: original,
          foods: [peanut],
          dietaryPreference: AppConstants.dietVeg,
          excludedIngredients: ['peanut'],
        ),
        isEmpty,
      );
    });
    test('generates diet-matched meals within the supplied budget', () {
      final foods = [
        _food(name: 'Dal meal', protein: 10, calories: 180, price: 12),
        _food(name: 'Rajma meal', protein: 11, calories: 190, price: 10),
        _food(name: 'Chana meal', protein: 12, calories: 200, price: 9),
        _food(
          name: 'Egg meal',
          protein: 12,
          calories: 190,
          price: 15,
          diet: AppConstants.dietEgg,
        ),
        _food(
          name: 'Chicken meal',
          protein: 20,
          calories: 210,
          price: 24,
          diet: AppConstants.dietNonVeg,
        ),
      ];

      final meals = DailyMealPlannerService.generate(
        foods: foods,
        calorieTarget: 700,
        proteinTarget: 40,
        budget: 40,
        dietaryPreference: AppConstants.dietVeg,
        mealSlots: const ['Breakfast', 'Lunch', 'Dinner'],
      );

      expect(meals, hasLength(3));
      expect(
        meals.every(
          (meal) => meal.food.dietaryClassification == AppConstants.dietVeg,
        ),
        isTrue,
      );
      expect(
        meals.fold<double>(0, (sum, meal) => sum + meal.cost),
        lessThanOrEqualTo(40),
      );
    });

    test('returns no plan for invalid targets or budget', () {
      expect(
        DailyMealPlannerService.generate(
          foods: [_food(name: 'Dal', protein: 10, calories: 180, price: 12)],
          calorieTarget: double.infinity,
          proteinTarget: 30,
          budget: 50,
          dietaryPreference: AppConstants.dietVeg,
        ),
        isEmpty,
      );
    });

    test(
      'substitutions are cheaper and preserve a reasonable nutrition match',
      () {
        final original = _food(
          name: 'Paneer meal',
          protein: 20,
          calories: 220,
          price: 32,
        );
        final cheaper = _food(
          name: 'Soya meal',
          protein: 17,
          calories: 200,
          price: 16,
        );
        final poorMatch = _food(
          name: 'Rice meal',
          protein: 3,
          calories: 190,
          price: 5,
        );

        final choices = DailyMealPlannerService.substitutions(
          current: original,
          foods: [original, cheaper, poorMatch],
          dietaryPreference: AppConstants.dietVeg,
        );

        expect(choices, contains(cheaper));
        expect(choices, isNot(contains(poorMatch)));
      },
    );
  });
}
