import 'dart:math';
import '../core/constants/app_constants.dart';
import '../data/models/food_item.dart';
import '../data/models/recommendation.dart';

class RecommendationCriteria {
  final double remainingProteinTarget; // g
  final double remainingBudget; // INR
  final double? maxCalories; // optional kcal limit
  final String dietaryPreference; // Veg, Eggetarian, Non-Veg
  final List<int> excludedFoodIds;
  final List<int> includedFoodIds;
  final int maxItems; // default 2 or 3

  const RecommendationCriteria({
    required this.remainingProteinTarget,
    required this.remainingBudget,
    this.maxCalories,
    this.dietaryPreference = AppConstants.dietVeg,
    this.excludedFoodIds = const [],
    this.includedFoodIds = const [],
    this.maxItems = 3,
  });
}

class RecommendationService {
  /// Realistic portion steps for Indian foods (in grams/ml)
  static List<double> getPortionStepsForFood(FoodItem food) {
    final lowerName = food.name.toLowerCase();
    if (lowerName.contains('egg')) {
      return [50.0, 100.0, 150.0, 200.0]; // 1, 2, 3, or 4 eggs
    }
    if (lowerName.contains('soya chunks') || lowerName.contains('sattu')) {
      return [30.0, 50.0, 75.0, 100.0];
    }
    if (lowerName.contains('milk') || lowerName.contains('chaas')) {
      return [200.0, 250.0, 300.0, 500.0];
    }
    if (lowerName.contains('paneer') || lowerName.contains('tofu')) {
      return [50.0, 100.0, 150.0];
    }
    if (lowerName.contains('peanut') || lowerName.contains('seed')) {
      return [25.0, 35.0, 50.0];
    }
    if (lowerName.contains('chicken') || lowerName.contains('fish')) {
      return [100.0, 150.0, 200.0];
    }
    if (lowerName.contains('dal') ||
        lowerName.contains('chana') ||
        lowerName.contains('rajma')) {
      return [100.0, 150.0, 200.0];
    }
    return [50.0, 100.0, 150.0];
  }

  /// Filters candidate foods by dietary preference, price validity, and user exclusions
  static List<FoodItem> filterEligibleFoods({
    required List<FoodItem> allFoods,
    required String dietaryPreference,
    required List<int> excludedFoodIds,
  }) {
    return allFoods.where((food) {
      if (food.id != null && excludedFoodIds.contains(food.id)) {
        return false;
      }
      if (food.estimatedUnitPrice <= 0 || food.priceQuantityBasis <= 0) {
        return false;
      }
      if (dietaryPreference == AppConstants.dietVeg) {
        return food.dietaryClassification == AppConstants.dietVeg;
      } else if (dietaryPreference == AppConstants.dietEgg) {
        return food.dietaryClassification == AppConstants.dietVeg ||
            food.dietaryClassification == AppConstants.dietEgg;
      }
      return true; // Non-Veg accepts all
    }).toList();
  }

  /// Generates and ranks budget-aware food combinations to meet remaining protein target
  static List<RecommendationPlan> findRecommendations({
    required List<FoodItem> allFoods,
    required RecommendationCriteria criteria,
  }) {
    if (criteria.remainingProteinTarget <= 0 || criteria.remainingBudget <= 0) {
      return [];
    }

    final eligibleFoods = filterEligibleFoods(
      allFoods: allFoods,
      dietaryPreference: criteria.dietaryPreference,
      excludedFoodIds: criteria.excludedFoodIds,
    );

    if (eligibleFoods.isEmpty) {
      return [];
    }

    // Sort by protein efficiency (g/₹) to prioritize budget-friendly proteins
    eligibleFoods.sort((a, b) {
      final effA = a.proteinPerRupee ?? 0.0;
      final effB = b.proteinPerRupee ?? 0.0;
      return effB.compareTo(effA);
    });

    // Take the top pool to keep combinatorial search bounded and fast
    final candidatePool = eligibleFoods.take(18).toList();

    final List<RecommendationPlan> feasiblePlans = [];
    final List<RecommendationPlan> partialPlans = [];

    // Helper to evaluate and collect candidate items
    void evaluateCombination(List<RecommendationItem> items) {
      final totalCost = items.fold(0.0, (sum, i) => sum + i.cost);
      if (totalCost > criteria.remainingBudget) return;

      final totalCals = items.fold(0.0, (sum, i) => sum + i.calories);
      if (criteria.maxCalories != null && totalCals > criteria.maxCalories!) {
        return;
      }

      final totalProtein = items.fold(0.0, (sum, i) => sum + i.protein);
      final coverage = totalProtein / criteria.remainingProteinTarget;

      final eff = totalCost > 0 ? totalProtein / totalCost : 0.0;

      if (coverage >= 0.85) {
        // Meets at least 85% of target within budget: Feasible solution
        final overshoot = max(
          0.0,
          totalProtein - criteria.remainingProteinTarget,
        );
        final reason = _generateFeasibleExplanation(
          totalProtein: totalProtein,
          totalCost: totalCost,
          efficiency: eff,
          itemsCount: items.length,
          overshoot: overshoot,
        );

        feasiblePlans.add(
          RecommendationPlan(
            id: '${items.length}_${items.map((i) => '${i.food.id}_${i.quantity.toInt()}').join('-')}',
            items: items,
            targetProtein: criteria.remainingProteinTarget,
            maxBudget: criteria.remainingBudget,
            maxCalories: criteria.maxCalories,
            rankReason: reason,
            isFeasible: true,
          ),
        );
      } else {
        // Below 85% target: Collect for fallback in case budget cannot achieve 85%
        partialPlans.add(
          RecommendationPlan(
            id: 'partial_${items.map((i) => '${i.food.id}_${i.quantity.toInt()}').join('-')}',
            items: items,
            targetProtein: criteria.remainingProteinTarget,
            maxBudget: criteria.remainingBudget,
            maxCalories: criteria.maxCalories,
            rankReason:
                'Closest budget match providing ${totalProtein.toStringAsFixed(1)}g protein.',
            isFeasible: false,
            infeasibilityNote:
                'Budget of ₹${criteria.remainingBudget.toStringAsFixed(0)} is limited. This delivers the maximum feasible protein within your budget.',
          ),
        );
      }
    }

    // 1-item combinations
    for (final food in candidatePool) {
      for (final portion in getPortionStepsForFood(food)) {
        evaluateCombination([RecommendationItem.fromFood(food, portion)]);
      }
    }

    // 2-item combinations
    if (criteria.maxItems >= 2) {
      for (int i = 0; i < candidatePool.length; i++) {
        final foodA = candidatePool[i];
        for (int j = i + 1; j < candidatePool.length; j++) {
          final foodB = candidatePool[j];
          for (final portionA in getPortionStepsForFood(foodA)) {
            for (final portionB in getPortionStepsForFood(foodB)) {
              evaluateCombination([
                RecommendationItem.fromFood(foodA, portionA),
                RecommendationItem.fromFood(foodB, portionB),
              ]);
            }
          }
        }
      }
    }

    // 3-item combinations (sample high efficiency top candidates)
    if (criteria.maxItems >= 3 && candidatePool.length >= 3) {
      final topSub = candidatePool.take(8).toList();
      for (int i = 0; i < topSub.length; i++) {
        for (int j = i + 1; j < topSub.length; j++) {
          for (int k = j + 1; k < topSub.length; k++) {
            evaluateCombination([
              RecommendationItem.fromFood(
                topSub[i],
                getPortionStepsForFood(topSub[i]).first,
              ),
              RecommendationItem.fromFood(
                topSub[j],
                getPortionStepsForFood(topSub[j]).first,
              ),
              RecommendationItem.fromFood(
                topSub[k],
                getPortionStepsForFood(topSub[k]).first,
              ),
            ]);
          }
        }
      }
    }

    if (feasiblePlans.isNotEmpty) {
      // Rank feasible plans: balance high protein efficiency (g/₹), close target match, and cost savings
      feasiblePlans.sort((a, b) {
        final scoreA = _scorePlan(a, criteria);
        final scoreB = _scorePlan(b, criteria);
        return scoreB.compareTo(scoreA);
      });

      // Remove near-identical duplicates and return top 6
      return _deduplicatePlans(feasiblePlans).take(6).toList();
    } else {
      // If budget is too tight to reach target, return best feasible alternatives
      partialPlans.sort((a, b) {
        // Sort by highest protein reached within budget
        return b.totalProtein.compareTo(a.totalProtein);
      });
      return _deduplicatePlans(partialPlans).take(4).toList();
    }
  }

  /// Calculates a deterministic score for ranking candidates
  static double _scorePlan(
    RecommendationPlan plan,
    RecommendationCriteria criteria,
  ) {
    final protein = plan.totalProtein;
    final cost = plan.totalCost;
    final eff = plan.overallProteinPerRupee ?? 0.0;

    // Target match: 1.0 is exact match
    final coverage = protein / criteria.remainingProteinTarget;
    final targetMatchPenalty = (coverage - 1.0).abs() * 20.0;

    // Cost efficiency bonus: higher g/₹ is heavily rewarded
    final efficiencyBonus = min(eff, 4.0) * 15.0;

    // Budget savings bonus: saving money within target
    final budgetSavingsRatio = max(
      0.0,
      (criteria.remainingBudget - cost) / criteria.remainingBudget,
    );
    final savingsBonus = budgetSavingsRatio * 15.0;

    return 100.0 + efficiencyBonus + savingsBonus - targetMatchPenalty;
  }

  static String _generateFeasibleExplanation({
    required double totalProtein,
    required double totalCost,
    required double efficiency,
    required int itemsCount,
    required double overshoot,
  }) {
    final costStr = '₹${totalCost.toStringAsFixed(1)}';
    final pStr = '${totalProtein.toStringAsFixed(1)}g';
    final effStr = '${efficiency.toStringAsFixed(2)} g/₹';

    if (efficiency >= 1.5) {
      return 'Super Budget Saver: High efficiency ($effStr). Delivers $pStr protein for just $costStr.';
    } else if (itemsCount == 1) {
      return 'Simple Single-Food Serving: Convenient 1-item solution delivering $pStr protein for $costStr ($effStr).';
    } else if (overshoot <= 3.0) {
      return 'Target Bullseye: Perfectly hits target with $pStr protein for $costStr ($effStr).';
    } else {
      return 'Balanced Combination: Wholesome pairing providing $pStr protein for $costStr ($effStr).';
    }
  }

  static List<RecommendationPlan> _deduplicatePlans(
    List<RecommendationPlan> plans,
  ) {
    final List<RecommendationPlan> unique = [];
    final Set<String> seenFoodSets = {};

    for (final plan in plans) {
      final key =
          plan.items.map((i) => '${i.food.id}:${i.quantity.toInt()}').toList()
            ..sort();
      final keyStr = key.join('|');

      if (!seenFoodSets.contains(keyStr)) {
        seenFoodSets.add(keyStr);
        unique.add(plan);
      }
    }
    return unique;
  }
}
