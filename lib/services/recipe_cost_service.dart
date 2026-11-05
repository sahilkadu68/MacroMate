import '../data/models/food_item.dart';
import '../data/models/recipe.dart';

class RecipeCostService {
  /// Refresh future estimates using stable ingredient IDs. Missing ingredients
  /// keep their saved values; historical meal entries are never touched.
  static Recipe refresh(Recipe recipe, List<FoodItem> foods) {
    final byId = {
      for (final food in foods)
        if (food.id != null) food.id!: food,
    };
    return recipe.copyWith(
      ingredients: recipe.ingredients.map((ingredient) {
        final current = byId[ingredient.foodId];
        if (current == null ||
            current.measurementUnit != ingredient.measurementUnit) {
          return ingredient;
        }
        return RecipeIngredient(
          id: ingredient.id,
          recipeId: ingredient.recipeId,
          foodId: current.id,
          foodName: current.name,
          quantity: ingredient.quantity,
          measurementUnit: ingredient.measurementUnit,
          calories: current.caloriesForQuantity(ingredient.quantity),
          protein: current.proteinForQuantity(ingredient.quantity),
          carbs: current.carbsForQuantity(ingredient.quantity),
          fat: current.fatForQuantity(ingredient.quantity),
          cost: current.costForQuantity(ingredient.quantity),
        );
      }).toList(),
    );
  }
}
