import 'package:flutter_test/flutter_test.dart';
import 'package:macromate_india/data/models/recipe.dart';
import 'package:macromate_india/data/models/shopping_item.dart';

void main() {
  group('Recipe & ShoppingItem Unit Tests', () {
    test('Recipe correctly calculates total and per-serving nutrition and cost', () {
      final recipe = Recipe(
        name: 'High Protein Soya Paneer Bhurji',
        description: 'Nutritious student gym dinner',
        servings: 2,
        ingredients: [
          RecipeIngredient(
            foodName: 'Soya Chunks',
            quantity: 50.0,
            measurementUnit: 'g',
            calories: 172.5,
            protein: 26.0,
            carbs: 16.5,
            fat: 0.25,
            cost: 6.0,
          ),
          RecipeIngredient(
            foodName: 'Paneer',
            quantity: 100.0,
            measurementUnit: 'g',
            calories: 265.0,
            protein: 18.0,
            carbs: 3.0,
            fat: 20.0,
            cost: 45.0,
          ),
        ],
      );

      expect(recipe.totalCalories, 437.5);
      expect(recipe.totalProtein, 44.0);
      expect(recipe.totalCost, 51.0);

      expect(recipe.perServingCalories, 218.75);
      expect(recipe.perServingProtein, 22.0);
      expect(recipe.perServingCost, 25.5);
    });

    test('Recipe serialization and deserialization preserves all values', () {
      final original = Recipe(
        id: 42,
        name: 'Egg Omelette & Toast',
        servings: 1,
        ingredients: [
          RecipeIngredient(
            foodName: 'Whole Boiled Egg',
            quantity: 2.0,
            measurementUnit: 'piece',
            calories: 140.0,
            protein: 12.0,
            carbs: 1.0,
            fat: 10.0,
            cost: 14.0,
          ),
        ],
      );

      final map = original.toMap();
      final restored = Recipe.fromMap(map, ingredients: original.ingredients);

      expect(restored.id, 42);
      expect(restored.name, 'Egg Omelette & Toast');
      expect(restored.servings, 1);
      expect(restored.ingredients.length, 1);
      expect(restored.ingredients.first.foodName, 'Whole Boiled Egg');
    });

    test('ShoppingItem toggles purchased state and serialization', () {
      final item = ShoppingItem(
        id: 1,
        name: 'Eggs (Dozen)',
        quantity: 12.0,
        unit: 'piece',
        isPurchased: false,
      );

      expect(item.isPurchased, isFalse);
      final purchased = item.copyWith(isPurchased: true);
      expect(purchased.isPurchased, isTrue);

      final map = purchased.toMap();
      expect(map['is_purchased'], 1);

      final restored = ShoppingItem.fromMap(map);
      expect(restored.isPurchased, isTrue);
      expect(restored.name, 'Eggs (Dozen)');
    });
  });
}
