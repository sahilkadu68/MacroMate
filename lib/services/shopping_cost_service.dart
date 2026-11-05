import '../data/models/food_item.dart';
import '../data/models/shopping_item.dart';

/// Uses only matching catalogue entries and compatible units. Unknown costs
/// remain unknown instead of being presented as free groceries.
class ShoppingCostService {
  static double? estimate(ShoppingItem item, List<FoodItem> foods) {
    if (!item.quantity.isFinite || item.quantity <= 0) return null;
    final matches = foods.where(
      (food) =>
          food.name.trim().toLowerCase() == item.name.trim().toLowerCase(),
    );
    if (matches.length != 1) return null;
    final food = matches.single;
    final from = _unit(item.unit);
    final to = _unit(food.measurementUnit);
    if (from.$1 != to.$1 ||
        food.packagePrice <= 0 ||
        !food.packagePrice.isFinite ||
        food.packageQuantity <= 0 ||
        !food.packageQuantity.isFinite) {
      return null;
    }
    return food.costForQuantity(item.quantity * from.$2 / to.$2);
  }

  static (String, double) _unit(String unit) => switch (unit.toLowerCase()) {
    'kg' => ('mass', 1000),
    'g' => ('mass', 1),
    'l' || 'litre' => ('volume', 1000),
    'ml' => ('volume', 1),
    _ => (unit.toLowerCase(), 1),
  };
}
