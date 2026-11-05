import '../data/models/food_item.dart';
import '../data/models/recipe.dart';

class RecipeCostService {
  static FoodItem asPlannableFood(Recipe recipe, List<FoodItem> foods) {
    final current = refresh(recipe, foods);
    final ids = recipe.ingredients
        .map((ingredient) => ingredient.foodId)
        .toSet();
    final components = foods.where((food) => ids.contains(food.id));
    final diet =
        components.any((food) => food.dietaryClassification == 'Non-Vegetarian')
        ? 'Non-Vegetarian'
        : components.any((food) => food.dietaryClassification == 'Eggetarian')
        ? 'Eggetarian'
        : 'Vegetarian';
    return FoodItem(
      id: -recipe.id!,
      name: recipe.name,
      category: 'Recipes',
      dietaryClassification: diet,
      caloriesPer100: current.perServingCalories * 100,
      proteinPer100: current.perServingProtein * 100,
      carbsPer100: current.perServingCarbs * 100,
      fatPer100: current.perServingFat * 100,
      measurementUnit: 'serving',
      servingSize: 1,
      packagePrice: current.perServingCost,
      packageQuantity: 1,
      entryType: 'Recipe',
      ingredients: recipe.ingredients.map((item) => item.foodName).join(', '),
      priceSource: 'Sum of current ingredient quantities × local unit prices',
      priceConfidence: 'Ingredient-derived estimate',
    );
  }

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
