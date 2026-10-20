import 'dart:math';
import '../core/constants/app_constants.dart';
import '../data/models/food_item.dart';
import '../data/models/recommendation.dart';
import 'dietary_service.dart';

class RecommendationCriteria {
  final double remainingProteinTarget; // g
  final double remainingBudget; // INR
  final double? maxCalories; // optional kcal limit
  final String dietaryPreference; // Veg, Eggetarian, Non-Veg
  final List<int> excludedFoodIds;
  final List<int> includedFoodIds;
  final int maxItems; // 1, 2, or 3 items

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
    if (lowerName.contains('egg white')) {
      return [66.0, 99.0, 132.0, 198.0]; // 2, 3, 4, or 6 egg whites
    }
    if (lowerName.contains('egg')) {
      return [50.0, 100.0, 150.0, 200.0]; // 1, 2, 3, or 4 whole eggs
    }
    if (lowerName.contains('chicken breast')) {
      return [100.0, 150.0, 200.0, 250.0];
    }
    if (lowerName.contains('chicken') || lowerName.contains('fish')) {
      return [100.0, 150.0, 200.0];
    }
    if (lowerName.contains('mutton')) {
      return [100.0, 150.0];
    }
    if (lowerName.contains('soya chunks') || lowerName.contains('sattu')) {
      return [30.0, 50.0, 75.0, 100.0];
    }
    if (lowerName.contains('milk') || lowerName.contains('chaas')) {
      return [200.0, 250.0, 300.0, 500.0];
    }
    if (lowerName.contains('paneer') || lowerName.contains('tofu')) {
      return [50.0, 100.0, 150.0, 200.0];
    }
    if (lowerName.contains('peanut') || lowerName.contains('seed')) {
      return [25.0, 35.0, 50.0];
    }
    if (lowerName.contains('dal') ||
        lowerName.contains('chana') ||
        lowerName.contains('rajma') ||
        lowerName.contains('chole')) {
      return [100.0, 150.0, 200.0];
    }
    if (lowerName.contains('rice') ||
        lowerName.contains('roti') ||
        lowerName.contains('oats')) {
      return [50.0, 100.0, 150.0];
    }
    return [50.0, 100.0, 150.0];
  }

  /// Filters candidate foods by dietary eligibility, valid pricing, and user exclusions
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
      return DietaryService.isFoodEligible(
        foodClassification: food.dietaryClassification,
        userPreference: dietaryPreference,
      );
    }).toList();
  }

  /// Generates and ranks budget-aware food combinations to meet remaining protein target
  /// Algorithm: Bounded combinatorial exploration of eligible foods with strict pruning.
  /// Complexity: O(N * P + N^2 * P^2 + N^3 * P^3) bounded by small candidate pools (N<=18, P<=3).
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

    // Build balanced candidate pool:
    // Take top efficiency foods across eligible staples, ensuring diverse sources
    final sortedFoods = List<FoodItem>.from(eligibleFoods)
      ..sort((a, b) => (b.proteinPerRupee ?? 0).compareTo(a.proteinPerRupee ?? 0));

    // Diverse representation: include high protein, high efficiency, and preferred foods
    final Set<String> addedKeys = {};
    final List<FoodItem> candidatePool = [];

    // Always include user specified foods first
    if (criteria.includedFoodIds.isNotEmpty) {
      for (final f in eligibleFoods) {
        if (f.id != null && criteria.includedFoodIds.contains(f.id)) {
          final key = f.id != null ? 'id_${f.id}' : f.name;
          if (!addedKeys.contains(key)) {
            candidatePool.add(f);
            addedKeys.add(key);
          }
        }
      }
    }

    // For Non-Veg preference: prioritize animal protein heroes (chicken breast, fish)
    if (criteria.dietaryPreference == AppConstants.dietNonVeg) {
      final nonVegItems = eligibleFoods
          .where((f) => f.dietaryClassification == AppConstants.dietNonVeg)
          .toList()
        ..sort((a, b) => (b.proteinPerRupee ?? 0).compareTo(a.proteinPerRupee ?? 0));
      for (final f in nonVegItems.take(5)) {
        final key = f.id != null ? 'id_${f.id}' : f.name;
        if (!addedKeys.contains(key)) {
          candidatePool.add(f);
          addedKeys.add(key);
        }
      }
    }

    // For Eggetarian preference: prioritize egg heroes
    if (criteria.dietaryPreference == AppConstants.dietEgg || criteria.dietaryPreference == AppConstants.dietNonVeg) {
      final eggItems = eligibleFoods
          .where((f) => f.dietaryClassification == AppConstants.dietEgg)
          .toList()
        ..sort((a, b) => (b.proteinPerRupee ?? 0).compareTo(a.proteinPerRupee ?? 0));
      for (final f in eggItems.take(4)) {
        final key = f.id != null ? 'id_${f.id}' : f.name;
        if (!addedKeys.contains(key)) {
          candidatePool.add(f);
          addedKeys.add(key);
        }
      }
    }

    // Include top efficiency items
    for (final f in sortedFoods) {
      final key = f.id != null ? 'id_${f.id}' : f.name;
      if (!addedKeys.contains(key)) {
        candidatePool.add(f);
        addedKeys.add(key);
        if (candidatePool.length >= 24) break;
      }
    }

    final List<RecommendationPlan> feasiblePlans = [];
    final List<RecommendationPlan> partialPlans = [];

    void evaluateCombination(List<RecommendationItem> items) {
      // 1. HARD CONSTRAINT: Dietary eligibility verification
      for (final item in items) {
        if (!DietaryService.isFoodEligible(
          foodClassification: item.food.dietaryClassification,
          userPreference: criteria.dietaryPreference,
        )) {
          return;
        }
      }

      // 2. HARD CONSTRAINT: Total cost must never exceed budget
      final totalCost = items.fold(0.0, (sum, i) => sum + i.cost);
      if (totalCost > criteria.remainingBudget) return;

      // 3. HARD CONSTRAINT: Total calories must not exceed calorie ceiling
      final totalCals = items.fold(0.0, (sum, i) => sum + i.calories);
      if (criteria.maxCalories != null && totalCals > criteria.maxCalories!) {
        return;
      }

      // 4. Hero Protein Alignment: If user requested Non-Veg or Eggetarian criteria,
      // require the combinations to feature their diet heroes when available
      if (criteria.dietaryPreference == AppConstants.dietNonVeg) {
        final hasNonVeg = items.any(
          (i) => i.food.dietaryClassification == AppConstants.dietNonVeg,
        );
        if (!hasNonVeg) return;
      }
      if (criteria.dietaryPreference == AppConstants.dietEgg) {
        final hasEgg = items.any(
          (i) => i.food.dietaryClassification == AppConstants.dietEgg,
        );
        if (!hasEgg) return;
      }

      final totalProtein = items.fold(0.0, (sum, i) => sum + i.protein);
      final coverage = totalProtein / criteria.remainingProteinTarget;
      final eff = totalCost > 0 ? totalProtein / totalCost : 0.0;

      if (coverage >= 0.80) {
        // Meets at least 80% of protein target: Feasible combination
        final overshoot = max(0.0, totalProtein - criteria.remainingProteinTarget);
        final reason = _generateFeasibleExplanation(
          totalProtein: totalProtein,
          totalCost: totalCost,
          efficiency: eff,
          itemsCount: items.length,
          overshoot: overshoot,
          diet: criteria.dietaryPreference,
          hasMeat: items.any((i) => i.food.dietaryClassification == AppConstants.dietNonVeg),
          hasEggs: items.any((i) => i.food.dietaryClassification == AppConstants.dietEgg),
        );

        feasiblePlans.add(
          RecommendationPlan(
            id: '${items.length}_${items.map((i) => '${i.food.id ?? i.food.name}_${i.quantity.toInt()}').join('-')}',
            items: items,
            targetProtein: criteria.remainingProteinTarget,
            maxBudget: criteria.remainingBudget,
            maxCalories: criteria.maxCalories,
            rankReason: reason,
            isFeasible: true,
          ),
        );
      } else {
        // Below 80%: Infeasible candidate for budget-limited fallback
        final gap = criteria.remainingProteinTarget - totalProtein;
        partialPlans.add(
          RecommendationPlan(
            id: 'partial_${items.map((i) => '${i.food.id ?? i.food.name}_${i.quantity.toInt()}').join('-')}',
            items: items,
            targetProtein: criteria.remainingProteinTarget,
            maxBudget: criteria.remainingBudget,
            maxCalories: criteria.maxCalories,
            rankReason:
                'Delivers ${totalProtein.toStringAsFixed(1)}g protein for ₹${totalCost.toStringAsFixed(0)} (${eff.toStringAsFixed(2)} g/₹).',
            isFeasible: false,
            infeasibilityNote:
                'Budget of ₹${criteria.remainingBudget.toStringAsFixed(0)} leaves a ${gap.toStringAsFixed(1)}g protein gap. This option maximizes protein within budget.',
          ),
        );
      }
    }

    // 1-item combinations
    if (criteria.maxItems >= 1) {
      for (final food in candidatePool) {
        for (final portion in getPortionStepsForFood(food)) {
          evaluateCombination([RecommendationItem.fromFood(food, portion)]);
        }
      }
    }

    // 2-item combinations
    if (criteria.maxItems >= 2) {
      final topSub = candidatePool.take(14).toList();
      for (int i = 0; i < topSub.length; i++) {
        for (int j = i + 1; j < topSub.length; j++) {
          final portionsA = getPortionStepsForFood(topSub[i]).take(3);
          final portionsB = getPortionStepsForFood(topSub[j]).take(3);
          for (final pA in portionsA) {
            for (final pB in portionsB) {
              evaluateCombination([
                RecommendationItem.fromFood(topSub[i], pA),
                RecommendationItem.fromFood(topSub[j], pB),
              ]);
            }
          }
        }
      }
    }

    // 3-item combinations
    if (criteria.maxItems >= 3) {
      final topSub = candidatePool.take(9).toList();
      for (int i = 0; i < topSub.length; i++) {
        for (int j = i + 1; j < topSub.length; j++) {
          for (int k = j + 1; k < topSub.length; k++) {
            final portionsA = getPortionStepsForFood(topSub[i]).take(2);
            final portionsB = getPortionStepsForFood(topSub[j]).take(2);
            final portionsC = getPortionStepsForFood(topSub[k]).take(2);
            for (final pA in portionsA) {
              for (final pB in portionsB) {
                for (final pC in portionsC) {
                  evaluateCombination([
                    RecommendationItem.fromFood(topSub[i], pA),
                    RecommendationItem.fromFood(topSub[j], pB),
                    RecommendationItem.fromFood(topSub[k], pC),
                  ]);
                }
              }
            }
          }
        }
      }
    }

    if (feasiblePlans.isNotEmpty) {
      // Deterministic ranking:
      feasiblePlans.sort((a, b) {
        final scoreA = _scorePlan(a, criteria);
        final scoreB = _scorePlan(b, criteria);
        return scoreB.compareTo(scoreA);
      });

      return _deduplicatePlans(feasiblePlans).take(6).toList();
    } else if (partialPlans.isNotEmpty) {
      // Return highest protein achievable within the hard budget limit
      partialPlans.sort((a, b) => b.totalProtein.compareTo(a.totalProtein));
      return _deduplicatePlans(partialPlans).take(4).toList();
    } else {
      // Extreme budget limitation fallback: single most efficient item
      final fallbacks = candidatePool.take(3);
      for (final f in fallbacks) {
        for (final p in getPortionStepsForFood(f)) {
          final cost = (f.estimatedUnitPrice * p) / f.priceQuantityBasis;
          if (cost <= criteria.remainingBudget) {
            final prot = (f.proteinPer100 * p) / 100.0;
            final gap = max(0.0, criteria.remainingProteinTarget - prot);
            partialPlans.add(
              RecommendationPlan(
                id: 'fallback_${f.id}_$p',
                items: [RecommendationItem.fromFood(f, p)],
                targetProtein: criteria.remainingProteinTarget,
                maxBudget: criteria.remainingBudget,
                rankReason:
                    '${f.name}: ${prot.toStringAsFixed(1)}g protein for ₹${cost.toStringAsFixed(1)}.',
                isFeasible: false,
                infeasibilityNote:
                    '₹${criteria.remainingBudget.toStringAsFixed(0)} is limited for ${criteria.remainingProteinTarget.toStringAsFixed(0)}g protein (${gap.toStringAsFixed(0)}g gap). Consider increasing budget or pairing with hostel staples.',
              ),
            );
          }
        }
      }
      return _deduplicatePlans(partialPlans).take(3).toList();
    }
  }

  /// Deterministic score function:
  /// - Base: 100 points
  /// - Target match accuracy: penalizes under/overshoot
  /// - Economic efficiency bonus: up to +30 pts for high g/₹
  /// - Budget savings bonus: up to +20 pts for remaining budget saved
  /// - Combo size match: +15 pts if matching exact requested size
  static double _scorePlan(
    RecommendationPlan plan,
    RecommendationCriteria criteria,
  ) {
    final protein = plan.totalProtein;
    final cost = plan.totalCost;
    final eff = plan.overallProteinPerRupee ?? 0.0;

    // Target match penalty
    final coverage = protein / criteria.remainingProteinTarget;
    final targetMatchPenalty = (coverage - 1.0).abs() * 25.0;

    // Cost efficiency bonus (0 to 30)
    final efficiencyBonus = min(eff, 3.0) * 10.0;

    // Budget savings bonus (0 to 20)
    final budgetSavingsRatio = max(
      0.0,
      (criteria.remainingBudget - cost) / criteria.remainingBudget,
    );
    final savingsBonus = budgetSavingsRatio * 20.0;

    // Preference for matching exact requested combo size
    final sizeBonus = (plan.items.length == criteria.maxItems) ? 15.0 : 0.0;

    return 100.0 + efficiencyBonus + savingsBonus + sizeBonus - targetMatchPenalty;
  }

  static String _generateFeasibleExplanation({
    required double totalProtein,
    required double totalCost,
    required double efficiency,
    required int itemsCount,
    required double overshoot,
    required String diet,
    required bool hasMeat,
    required bool hasEggs,
  }) {
    final costStr = '₹${totalCost.toStringAsFixed(1)}';
    final pStr = '${totalProtein.toStringAsFixed(1)}g';
    final effStr = '${efficiency.toStringAsFixed(2)} g/₹';

    if (hasMeat) {
      return 'Animal Protein Hero: Delivers $pStr protein for $costStr ($effStr). Complete amino acid profile.';
    } else if (hasEggs) {
      return 'Egg Protein Value: Delivers $pStr high-BV protein for $costStr ($effStr).';
    } else if (efficiency >= 1.5) {
      return 'Super Budget Saver: High efficiency ($effStr). Delivers $pStr protein for just $costStr.';
    } else if (itemsCount == 1) {
      return 'Simple Single-Item Serving: Delivers $pStr protein for $costStr ($effStr).';
    } else {
      return 'Balanced Combination: Delivers $pStr protein for $costStr within your food budget.';
    }
  }

  /// Removes plans that have the exact same set of foods and quantities
  static List<RecommendationPlan> _deduplicatePlans(
    List<RecommendationPlan> plans,
  ) {
    final Set<String> seenSignatures = {};
    final List<RecommendationPlan> unique = [];

    for (final plan in plans) {
      final sortedItems = List<RecommendationItem>.from(plan.items)
        ..sort((a, b) => (a.food.id?.toString() ?? a.food.name).compareTo(b.food.id?.toString() ?? b.food.name));

      final signature = sortedItems
          .map((i) => '${i.food.id ?? i.food.name}:${i.quantity.toInt()}')
          .join('|');

      if (!seenSignatures.contains(signature)) {
        seenSignatures.add(signature);
        unique.add(plan);
      }
    }

    return unique;
  }
}
