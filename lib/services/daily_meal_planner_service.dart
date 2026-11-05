import '../core/constants/app_constants.dart';
import '../data/models/food_item.dart';
import 'dietary_service.dart';

class PlannedMeal {
  const PlannedMeal({
    required this.mealType,
    required this.food,
    required this.quantity,
    this.status = 'planned',
  });

  final String mealType;
  final FoodItem food;
  final double quantity;
  final String status;

  double get calories => food.caloriesForQuantity(quantity);
  double get protein => food.proteinForQuantity(quantity);
  double get cost => food.costForQuantity(quantity);

  PlannedMeal copyWith({FoodItem? food, double? quantity, String? status}) =>
      PlannedMeal(
        mealType: mealType,
        food: food ?? this.food,
        quantity: quantity ?? this.quantity,
        status: status ?? this.status,
      );
}

class DailyMealPlannerService {
  static const defaultMealSlots = [
    AppConstants.mealBreakfast,
    AppConstants.mealLunch,
    AppConstants.mealSnack,
    AppConstants.mealDinner,
  ];

  /// Builds a deterministic day plan. Total cost is constrained to the given
  /// budget; calorie and protein targets are used as ranking goals, not promises.
  static List<PlannedMeal> generate({
    required List<FoodItem> foods,
    required double calorieTarget,
    required double proteinTarget,
    required double budget,
    required String dietaryPreference,
    List<String>? mealSlots,
    List<String> excludedIngredients = const [],
  }) {
    if (!_validPositive(calorieTarget) ||
        !_validPositive(proteinTarget) ||
        !_validPositive(budget)) {
      return [];
    }
    final slots = mealSlots ?? defaultMealSlots;
    if (slots.isEmpty) return [];
    final candidates = foods.where(_validFood).where((food) {
      if (!_matchesIngredients(food, excludedIngredients)) return false;
      return DietaryService.isFoodEligible(
        foodClassification: food.dietaryClassification,
        userPreference: dietaryPreference,
      );
    }).toList();
    if (candidates.isEmpty) return [];

    final result = <PlannedMeal>[];
    final used = <String>{};
    var remainingCalories = calorieTarget;
    var remainingProtein = proteinTarget;
    var remainingBudget = budget;

    for (var index = 0; index < slots.length; index++) {
      final remainingSlots = slots.length - index;
      final targetCaloriesForMeal = remainingCalories / remainingSlots;
      final targetProteinForMeal = remainingProtein / remainingSlots;
      PlannedMeal? best;
      var bestScore = double.infinity;

      for (final food in candidates) {
        if (used.contains(food.name.toLowerCase())) continue;
        if (food.mealTypes.isNotEmpty &&
            !food.mealTypes.contains(slots[index]) &&
            !(slots[index] == AppConstants.mealSnack &&
                food.mealTypes.contains('Pre-workout'))) {
          continue;
        }
        final baseQuantity = food.servingSize;
        if (!_validPositive(baseQuantity)) continue;
        final factors = food.measurementUnit == AppConstants.unitPiece
            ? const [1.0]
            : const [0.75, 1.0, 1.25];
        for (final factor in factors) {
          final quantity = baseQuantity * factor;
          final cost = food.costForQuantity(quantity);
          final calories = food.caloriesForQuantity(quantity);
          final protein = food.proteinForQuantity(quantity);
          if (!_validNonNegative(cost) ||
              !_validNonNegative(calories) ||
              !_validNonNegative(protein) ||
              cost <= 0 ||
              cost > remainingBudget ||
              calories > targetCaloriesForMeal * 1.5) {
            continue;
          }
          final calorieError =
              (calories - targetCaloriesForMeal).abs() /
              targetCaloriesForMeal.clamp(100, double.infinity);
          final proteinError =
              (protein - targetProteinForMeal).abs() /
              targetProteinForMeal.clamp(5, double.infinity);
          final costShare = cost / remainingBudget;
          final score = calorieError + proteinError * 1.5 + costShare * 0.35;
          if (score < bestScore) {
            bestScore = score;
            best = PlannedMeal(
              mealType: slots[index],
              food: food,
              quantity: quantity,
            );
          }
        }
      }
      if (best == null) continue;
      result.add(best);
      used.add(best.food.name.toLowerCase());
      remainingCalories = (remainingCalories - best.calories)
          .clamp(0, double.infinity)
          .toDouble();
      remainingProtein = (remainingProtein - best.protein)
          .clamp(0, double.infinity)
          .toDouble();
      remainingBudget = (remainingBudget - best.cost)
          .clamp(0, double.infinity)
          .toDouble();
    }
    return result;
  }

  static List<FoodItem> substitutions({
    required FoodItem current,
    required List<FoodItem> foods,
    required String dietaryPreference,
    int limit = 5,
    List<String> excludedIngredients = const [],
  }) {
    final candidates = foods
        .where(_validFood)
        .where((food) {
          if (!_matchesIngredients(food, excludedIngredients)) return false;
          if ((current.id != null && food.id == current.id) ||
              food.name == current.name) {
            return false;
          }
          return DietaryService.isFoodEligible(
            foodClassification: food.dietaryClassification,
            userPreference: dietaryPreference,
          );
        })
        .where((food) {
          final cheaper = food.costPerServing < current.costPerServing;
          final similarProtein =
              current.proteinPerServing <= 0 ||
              food.proteinPerServing >= current.proteinPerServing * 0.7;
          final similarCalories =
              current.caloriesPerServing <= 0 ||
              food.caloriesPerServing <= current.caloriesPerServing * 1.4;
          return cheaper && similarProtein && similarCalories;
        })
        .toList();

    candidates.sort((a, b) {
      final scoreA = _substitutionScore(a, current);
      final scoreB = _substitutionScore(b, current);
      return scoreA.compareTo(scoreB);
    });
    return candidates.take(limit).toList();
  }

  static double _substitutionScore(FoodItem food, FoodItem original) {
    final proteinDifference = original.proteinPerServing <= 0
        ? 0.0
        : (food.proteinPerServing - original.proteinPerServing).abs() /
              original.proteinPerServing;
    final calorieDifference = original.caloriesPerServing <= 0
        ? 0.0
        : (food.caloriesPerServing - original.caloriesPerServing).abs() /
              original.caloriesPerServing;
    final cost = original.costPerServing <= 0
        ? 0.0
        : food.costPerServing / original.costPerServing;
    final efficiency = food.proteinPerRupee ?? 0;
    return proteinDifference +
        calorieDifference * 0.5 +
        cost -
        efficiency * 0.02;
  }

  static bool _matchesIngredients(FoodItem food, List<String> excluded) {
    final description = '${food.name} ${food.ingredients}'.toLowerCase();
    return !excluded.any(
      (term) =>
          term.trim().isNotEmpty &&
          description.contains(term.trim().toLowerCase()),
    );
  }

  static bool _validFood(FoodItem food) =>
      food.estimatedUnitPrice.isFinite &&
      food.estimatedUnitPrice > 0 &&
      food.priceQuantityBasis.isFinite &&
      food.priceQuantityBasis > 0 &&
      food.caloriesPer100.isFinite &&
      food.proteinPer100.isFinite &&
      food.carbsPer100.isFinite &&
      food.fatPer100.isFinite &&
      food.caloriesPer100 >= 0 &&
      food.proteinPer100 >= 0 &&
      food.carbsPer100 >= 0 &&
      food.fatPer100 >= 0;

  static bool _validPositive(double value) => value.isFinite && value > 0;
  static bool _validNonNegative(double value) => value.isFinite && value >= 0;
}
