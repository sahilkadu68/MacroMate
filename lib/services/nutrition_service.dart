import 'dart:math';
import '../core/constants/app_constants.dart';
import '../data/models/meal_entry.dart';
import '../data/models/user_profile.dart';

class DailyNutritionSummary {
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalCost;
  final int mealCount;

  const DailyNutritionSummary({
    this.totalCalories = 0.0,
    this.totalProtein = 0.0,
    this.totalCarbs = 0.0,
    this.totalFat = 0.0,
    this.totalCost = 0.0,
    this.mealCount = 0,
  });

  double? get overallProteinPerRupee {
    if (totalCost <= 0 || totalProtein <= 0) return null;
    return totalProtein / totalCost;
  }
}

class MacroTargetsRemaining {
  final double remainingCalories;
  final double remainingProtein;
  final double remainingCarbs;
  final double remainingFat;
  final double remainingBudget;

  const MacroTargetsRemaining({
    required this.remainingCalories,
    required this.remainingProtein,
    required this.remainingCarbs,
    required this.remainingFat,
    required this.remainingBudget,
  });
}

class NutritionService {
  /// Calculates nutrient amount for a specific quantity
  /// Formula: Nutrient amount = nutrient value per 100g/ml × selected grams / 100
  static double calculateNutrient({
    required double nutrientPer100,
    required double quantity,
  }) {
    if (quantity <= 0 || nutrientPer100 <= 0) return 0.0;
    return (nutrientPer100 * quantity) / 100.0;
  }

  /// Calculates serving cost in INR
  /// Formula: Cost = (estimatedUnitPrice / priceQuantityBasis) × quantity
  static double calculateServingCost({
    required double unitPrice,
    required double priceBasis,
    required double quantity,
  }) {
    if (unitPrice <= 0 || priceBasis <= 0 || quantity <= 0) return 0.0;
    return (unitPrice / priceBasis) * quantity;
  }

  /// Calculates protein efficiency (grams of protein per Rupee)
  /// Formula: Protein Efficiency = Protein (g) / Cost (₹)
  /// Returns null if cost is zero, negative, or invalid to prevent division by zero
  static double? calculateProteinEfficiency({
    required double proteinGrams,
    required double costRupees,
  }) {
    if (costRupees <= 0 ||
        proteinGrams <= 0 ||
        costRupees.isNaN ||
        costRupees.isInfinite) {
      return null;
    }
    return proteinGrams / costRupees;
  }

  /// Aggregates daily nutrition and expenditure from a list of meal entries
  static DailyNutritionSummary calculateDailyTotals(List<MealEntry> entries) {
    if (entries.isEmpty) {
      return const DailyNutritionSummary();
    }

    double calories = 0.0;
    double protein = 0.0;
    double carbs = 0.0;
    double fat = 0.0;
    double cost = 0.0;

    for (final entry in entries) {
      calories += entry.caloriesSnapshot;
      protein += entry.proteinSnapshot;
      carbs += entry.carbsSnapshot;
      fat += entry.fatSnapshot;
      cost += entry.costSnapshot;
    }

    return DailyNutritionSummary(
      totalCalories: calories,
      totalProtein: protein,
      totalCarbs: carbs,
      totalFat: fat,
      totalCost: cost,
      mealCount: entries.length,
    );
  }

  /// Calculates remaining macro targets and budget
  static MacroTargetsRemaining calculateRemainingTargets({
    required UserProfile profile,
    required DailyNutritionSummary consumed,
  }) {
    return MacroTargetsRemaining(
      remainingCalories: max(
        0.0,
        profile.calorieTarget - consumed.totalCalories,
      ),
      remainingProtein: max(0.0, profile.proteinTarget - consumed.totalProtein),
      remainingCarbs: max(
        0.0,
        profile.carbohydrateTarget - consumed.totalCarbs,
      ),
      remainingFat: max(0.0, profile.fatTarget - consumed.totalFat),
      remainingBudget: max(0.0, profile.dailyBudget - consumed.totalCost),
    );
  }

  /// Calculates target completion ratio (0.0 to 1.0+)
  static double calculateCompletionRatio({
    required double consumed,
    required double target,
  }) {
    if (target <= 0) return 0.0;
    return consumed / target;
  }

  /// Estimates Basal Metabolic Rate (BMR) using the Mifflin-St Jeor equation:
  /// Men: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) + 5
  /// Women: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) - 161
  /// Other / Neutral: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) - 78
  static double calculateMifflinStJeorBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    if (gender.toLowerCase() == 'female') {
      return base - 161.0;
    } else if (gender.toLowerCase() == 'male') {
      return base + 5.0;
    } else {
      return base - 78.0;
    }
  }

  /// Estimates Total Daily Energy Expenditure (TDEE) with activity multipliers
  static double calculateTdee({
    required double bmr,
    required String activityLevel,
  }) {
    double multiplier;
    if (activityLevel == AppConstants.activitySedentary) {
      multiplier = 1.2;
    } else if (activityLevel == AppConstants.activityLight) {
      multiplier = 1.375;
    } else if (activityLevel == AppConstants.activityModerate) {
      multiplier = 1.55;
    } else if (activityLevel == AppConstants.activityVeryActive) {
      multiplier = 1.725;
    } else if (activityLevel == AppConstants.activityExtraActive) {
      multiplier = 1.9;
    } else {
      multiplier = 1.4; // Conservative default
    }
    return bmr * multiplier;
  }

  /// Calculates estimated calorie requirement based on fitness goal
  static double calculateGoalCalories({
    required double tdee,
    required String goal,
  }) {
    if (goal == AppConstants.goalLose) {
      return max(1200.0, tdee - 400.0); // Conservative deficit, safe floor
    } else if (goal == AppConstants.goalGain) {
      return tdee + 350.0; // Clean surplus
    }
    return tdee; // Maintenance
  }

  /// Calculates macro split recommendations based on bodyweight and goal calories
  /// Conservative evidence-based fitness macros:
  /// - Protein: 1.8g/kg for gain/lose, 1.4g/kg for maintain
  /// - Fat: 0.8g/kg bodyweight
  /// - Carbs: Remaining calories / 4 kcal per gram
  static Map<String, double> estimateMacroTargets({
    required double weightKg,
    required double calorieTarget,
    required String goal,
  }) {
    double proteinGramsPerKg = (goal == AppConstants.goalMaintain) ? 1.4 : 1.8;
    double proteinTarget = weightKg * proteinGramsPerKg;
    double fatTarget = weightKg * 0.8;

    double proteinCals = proteinTarget * 4;
    double fatCals = fatTarget * 9;
    double remainingCals = max(0.0, calorieTarget - (proteinCals + fatCals));
    double carbTarget = remainingCals / 4;

    return {
      'calories': calorieTarget.roundToDouble(),
      'protein': proteinTarget.roundToDouble(),
      'carbs': carbTarget.roundToDouble(),
      'fat': fatTarget.roundToDouble(),
    };
  }

  /// Calculates water requirement in ml (standard: ~35-40 ml per kg of bodyweight)
  static double estimateWaterTarget(double weightKg) {
    return max(2000.0, weightKg * 35.0);
  }
}
