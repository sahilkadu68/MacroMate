import '../database/database_helper.dart';
import '../models/recipe.dart';
import '../models/shopping_item.dart';

class PlanRepository {
  final DatabaseHelper _dbHelper;

  PlanRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // Recipes
  Future<List<Recipe>> getAllRecipes() => _dbHelper.getAllRecipes();
  Future<int> addRecipe(Recipe recipe) => _dbHelper.insertRecipe(recipe);
  Future<int> deleteRecipe(int id) => _dbHelper.deleteRecipe(id);

  // Shopping Items
  Future<List<ShoppingItem>> getShoppingItems() => _dbHelper.getShoppingItems();
  Future<int> addShoppingItem(ShoppingItem item) => _dbHelper.insertShoppingItem(item);
  Future<int> updateShoppingItem(ShoppingItem item) => _dbHelper.updateShoppingItem(item);
  Future<int> deleteShoppingItem(int id) => _dbHelper.deleteShoppingItem(id);
  Future<void> clearPurchasedShoppingItems() => _dbHelper.clearPurchasedShoppingItems();

  // Favorites
  Future<Set<int>> getFavoriteFoodIds() => _dbHelper.getFavoriteFoodIds();
  Future<bool> toggleFavoriteFood(int foodId) => _dbHelper.toggleFavoriteFood(foodId);
}
