import 'package:flutter_test/flutter_test.dart';
import 'package:macromate_india/data/models/food_item.dart';
import 'package:macromate_india/data/models/recipe.dart';
import 'package:macromate_india/services/recipe_cost_service.dart';

void main() {
  test(
    'current ingredient prices refresh future recipes without mutating saved values',
    () {
      final food = FoodItem(
        id: 7,
        name: 'Rice',
        category: 'Staples',
        dietaryClassification: 'Vegetarian',
        caloriesPer100: 350,
        proteinPer100: 7,
        carbsPer100: 77,
        fatPer100: 1,
        packagePrice: 80,
        packageQuantity: 1000,
      );
      final saved = Recipe(
        name: 'Rice bowl',
        servings: 2,
        ingredients: [RecipeIngredient.fromFood(food: food, quantity: 200)],
      );
      final refreshed = RecipeCostService.refresh(saved, [
        food.copyWith(packagePrice: 100),
      ]);
      expect(saved.totalCost, 16);
      expect(refreshed.totalCost, 20);
      expect(refreshed.perServingCost, 10);
      expect(refreshed.totalCalories, saved.totalCalories);
      expect(RecipeCostService.refresh(saved, []).totalCost, 16);
    },
  );
}
