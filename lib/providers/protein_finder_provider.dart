import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../data/models/food_item.dart';
import '../data/models/meal_entry.dart';
import '../data/models/recommendation.dart';
import '../services/recommendation_service.dart';
import 'meal_provider.dart';

class ProteinFinderProvider with ChangeNotifier {
  List<RecommendationPlan> _recommendations = [];
  bool _isLoading = false;
  String? _errorMessage;
  RecommendationCriteria? _lastCriteria;

  List<RecommendationPlan> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  RecommendationCriteria? get lastCriteria => _lastCriteria;

  void findCombos({
    required List<FoodItem> allFoods,
    required double remainingProtein,
    required double remainingBudget,
    double? maxCalories,
    String dietaryPreference = AppConstants.dietVeg,
    List<int> excludedFoodIds = const [],
    int maxItems = 3,
  }) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final criteria = RecommendationCriteria(
        remainingProteinTarget: remainingProtein,
        remainingBudget: remainingBudget,
        maxCalories: maxCalories,
        dietaryPreference: dietaryPreference,
        excludedFoodIds: excludedFoodIds,
        maxItems: maxItems,
      );
      _lastCriteria = criteria;

      _recommendations = RecommendationService.findRecommendations(
        allFoods: allFoods,
        criteria: criteria,
      );
    } catch (e) {
      _errorMessage = 'Failed to generate recommendations: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds all food items in a recommended plan directly into the meal diary
  Future<void> addPlanToDiary({
    required RecommendationPlan plan,
    required MealProvider mealProvider,
    required String mealType,
    required DateTime date,
  }) async {
    final entries = plan.items.map((item) {
      return MealEntry.fromFoodItem(
        food: item.food,
        entryDate: date,
        mealType: mealType,
        quantity: item.quantity,
      );
    }).toList();

    await mealProvider.addMultipleMeals(entries);
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
