import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../data/models/food_item.dart';

class DietaryService {
  /// Evaluates whether a food item is eligible under the user's declared dietary preference.
  ///
  /// RULES:
  /// - Vegetarian: Vegetarian foods are eligible. Eggs, meat, poultry, and fish are excluded.
  /// - Eggetarian: Vegetarian foods AND eggs are eligible. Meat, poultry, and fish are excluded.
  ///   (An eggetarian user is NOT restricted to eggs alone; vegetarian foods are completely eligible).
  /// - Non-Vegetarian: Vegetarian foods, eggs, meat, poultry, and fish are eligible.
  ///   (A non-vegetarian user is NOT forced to consume meat/fish; all food categories are eligible).
  static bool isFoodEligible({
    required String foodClassification,
    required String userPreference,
  }) {
    switch (userPreference) {
      case AppConstants.dietAll:
        return true; // All foods eligible (veg, egg, non-veg)
      case AppConstants.dietVeg:
      case 'Veg':
        return foodClassification == AppConstants.dietVeg;
      case AppConstants.dietEgg:
      case 'Egg':
        return foodClassification == AppConstants.dietVeg ||
            foodClassification == AppConstants.dietEgg;
      case AppConstants.dietNonVeg:
      case 'Non-Veg':
        return true; // All foods permitted for non-vegetarians
      default:
        return true;
    }
  }

  /// Filters a list of foods according to the user's dietary preference
  static List<FoodItem> filterEligibleFoods({
    required List<FoodItem> foods,
    required String userPreference,
  }) {
    return foods
        .where(
          (f) => isFoodEligible(
            foodClassification: f.dietaryClassification,
            userPreference: userPreference,
          ),
        )
        .toList();
  }

  /// Categorical catalogue filters for explicit browsing
  static const String filterAll = 'All';
  static const String filterVeg = 'Veg';
  static const String filterEgg = 'Egg';
  static const String filterNonVeg = 'Non-Veg';
  static const String filterHighProtein = 'High Protein';
  static const String filterBudgetSaver = 'Budget Saver';

  // Legacy aliases for backward compatibility
  static const String filterVegOnly = 'Veg';
  static const String filterEggsOnly = 'Egg';
  static const String filterMeatFish = 'Non-Veg';

  static const List<String> catalogueFilterOptions = [
    filterAll,
    filterVeg,
    filterEgg,
    filterNonVeg,
    filterHighProtein,
    filterBudgetSaver,
  ];

  /// Filters catalogue by explicit category chip
  static List<FoodItem> applyCatalogueFilter({
    required List<FoodItem> foods,
    required String selectedFilter,
  }) {
    switch (selectedFilter) {
      case filterVeg:
      case 'Veg Only':
        return foods
            .where((f) => f.dietaryClassification == AppConstants.dietVeg)
            .toList();
      case filterEgg:
      case 'Eggs Only':
      case 'Eggetarian':
        return foods
            .where((f) => f.dietaryClassification == AppConstants.dietEgg)
            .toList();
      case filterNonVeg:
      case 'Meat & Fish':
      case 'Non-Vegetarian':
        return foods
            .where((f) => f.dietaryClassification == AppConstants.dietNonVeg)
            .toList();
      case filterHighProtein:
      case 'High Protein (>15g)':
        return foods.where((f) => f.proteinPer100 >= 15.0).toList();
      case filterBudgetSaver:
      case 'Budget Saver (>1.2 g/₹)':
        return foods.where((f) => (f.proteinPerRupee ?? 0.0) >= 1.2).toList();
      case filterAll:
      default:
        return List.from(foods);
    }
  }

  /// Visual badge color for dietary tags
  static Color getClassificationColor(String classification) {
    switch (classification) {
      case AppConstants.dietVeg:
        return AppColors.vegGreen;
      case AppConstants.dietEgg:
        return AppColors.eggYellow;
      case AppConstants.dietNonVeg:
        return AppColors.nonVegRed;
      default:
        return Colors.grey;
    }
  }

  /// Visual label for dietary tags
  static String getClassificationLabel(String classification) {
    switch (classification) {
      case AppConstants.dietVeg:
        return 'Veg';
      case AppConstants.dietEgg:
        return 'Egg';
      case AppConstants.dietNonVeg:
        return 'Non-Veg';
      default:
        return classification;
    }
  }
}
