import 'food_item.dart';

class RecommendationItem {
  final FoodItem food;
  final double quantity; // in food.measurementUnit (e.g. 50g, 2 pieces)
  final double protein;
  final double cost;
  final double calories;
  final double carbs;
  final double fat;

  RecommendationItem({
    required this.food,
    required this.quantity,
    required this.protein,
    required this.cost,
    required this.calories,
    required this.carbs,
    required this.fat,
  });

  factory RecommendationItem.fromFood(FoodItem food, double quantity) {
    return RecommendationItem(
      food: food,
      quantity: quantity,
      protein: food.proteinForQuantity(quantity),
      cost: food.costForQuantity(quantity),
      calories: food.caloriesForQuantity(quantity),
      carbs: food.carbsForQuantity(quantity),
      fat: food.fatForQuantity(quantity),
    );
  }

  double? get proteinPerRupee {
    if (cost <= 0 || protein <= 0) return null;
    return protein / cost;
  }
}

class RecommendationPlan {
  final String id;
  final List<RecommendationItem> items;
  final double targetProtein;
  final double maxBudget;
  final double? maxCalories;
  final String rankReason;
  final bool isFeasible;
  final String? infeasibilityNote;

  RecommendationPlan({
    required this.id,
    required this.items,
    required this.targetProtein,
    required this.maxBudget,
    this.maxCalories,
    required this.rankReason,
    this.isFeasible = true,
    this.infeasibilityNote,
  });

  double get totalProtein => items.fold(0.0, (sum, item) => sum + item.protein);

  double get totalCost => items.fold(0.0, (sum, item) => sum + item.cost);

  double get totalCalories =>
      items.fold(0.0, (sum, item) => sum + item.calories);

  double get totalCarbs => items.fold(0.0, (sum, item) => sum + item.carbs);

  double get totalFat => items.fold(0.0, (sum, item) => sum + item.fat);

  double? get overallProteinPerRupee {
    if (totalCost <= 0 || totalProtein <= 0) return null;
    return totalProtein / totalCost;
  }

  double get remainingProteinGap {
    final diff = targetProtein - totalProtein;
    return diff > 0 ? diff : 0.0;
  }

  double get remainingBudgetAfter {
    final diff = maxBudget - totalCost;
    return diff > 0 ? diff : 0.0;
  }

  double get targetCoverageRatio {
    if (targetProtein <= 0) return 1.0;
    return totalProtein / targetProtein;
  }
}
