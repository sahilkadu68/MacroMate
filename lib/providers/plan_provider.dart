import 'package:flutter/foundation.dart';
import '../data/models/recipe.dart';
import '../data/models/shopping_item.dart';
import '../data/repositories/plan_repository.dart';

class PlanProvider with ChangeNotifier {
  final PlanRepository _repository;

  List<Recipe> _recipes = [];
  List<ShoppingItem> _shoppingItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  PlanProvider({PlanRepository? repository})
      : _repository = repository ?? PlanRepository() {
    loadAll();
  }

  List<Recipe> get recipes => _recipes;
  List<ShoppingItem> get shoppingItems => _shoppingItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recipes = await _repository.getAllRecipes();
      _shoppingItems = await _repository.getShoppingItems();
    } catch (e) {
      _errorMessage = 'Failed to load plans: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Recipes
  Future<int> addRecipe(Recipe recipe) async {
    try {
      final id = await _repository.addRecipe(recipe);
      await loadAll();
      return id;
    } catch (e) {
      _errorMessage = 'Failed to save recipe: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRecipe(int id) async {
    try {
      await _repository.deleteRecipe(id);
      _recipes.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete recipe: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Shopping Items
  Future<void> addShoppingItem(String name, double quantity, String unit) async {
    try {
      final item = ShoppingItem(name: name, quantity: quantity, unit: unit);
      final id = await _repository.addShoppingItem(item);
      _shoppingItems.insert(0, item.copyWith(id: id));
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add shopping item: $e';
      notifyListeners();
    }
  }

  Future<void> toggleShoppingItem(ShoppingItem item) async {
    try {
      final updated = item.copyWith(isPurchased: !item.isPurchased);
      await _repository.updateShoppingItem(updated);
      final idx = _shoppingItems.indexWhere((i) => i.id == item.id);
      if (idx != -1) {
        _shoppingItems[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update item: $e';
      notifyListeners();
    }
  }

  Future<void> deleteShoppingItem(int id) async {
    try {
      await _repository.deleteShoppingItem(id);
      _shoppingItems.removeWhere((i) => i.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete item: $e';
      notifyListeners();
    }
  }

  Future<void> clearPurchasedItems() async {
    try {
      await _repository.clearPurchasedShoppingItems();
      _shoppingItems.removeWhere((i) => i.isPurchased);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to clear items: $e';
      notifyListeners();
    }
  }

  /// Aggregates all ingredients of a recipe directly into the shopping list
  Future<void> addRecipeToShoppingList(Recipe recipe) async {
    for (final ing in recipe.ingredients) {
      // Check if item already exists: aggregate quantity
      final existingIdx = _shoppingItems.indexWhere(
        (i) => i.name.toLowerCase() == ing.foodName.toLowerCase() && !i.isPurchased,
      );
      if (existingIdx != -1) {
        final existing = _shoppingItems[existingIdx];
        final updated = existing.copyWith(quantity: existing.quantity + ing.quantity);
        await _repository.updateShoppingItem(updated);
        _shoppingItems[existingIdx] = updated;
      } else {
        final item = ShoppingItem(
          name: ing.foodName,
          quantity: ing.quantity,
          unit: ing.measurementUnit,
        );
        final id = await _repository.addShoppingItem(item);
        _shoppingItems.add(item.copyWith(id: id));
      }
    }
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
