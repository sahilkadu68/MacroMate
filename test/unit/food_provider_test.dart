import 'package:flutter_test/flutter_test.dart';
import 'package:macromate_india/core/constants/app_constants.dart';
import 'package:macromate_india/data/models/food_item.dart';
import 'package:macromate_india/data/repositories/food_repository.dart';
import 'package:macromate_india/data/seed/indian_foods_seed.dart';
import 'package:macromate_india/providers/food_provider.dart';

class MockFoodRepository implements FoodRepository {
  final List<FoodItem> _foods = List.from(IndianFoodsSeed.initialFoods);

  @override
  Future<List<FoodItem>> getAllFoods() async => List.from(_foods);

  @override
  Future<FoodItem?> getFoodById(int id) async =>
      _foods.where((f) => f.id == id).firstOrNull;

  @override
  Future<int> addFood(FoodItem food) async {
    _foods.add(food.copyWith(id: _foods.length + 1));
    return _foods.length;
  }

  @override
  Future<int> updateFood(FoodItem food) async => 1;

  @override
  Future<int> deleteFood(int id) async => 1;
}

void main() {
  group('FoodProvider Unit Tests', () {
    late FoodProvider foodProvider;

    setUp(() async {
      foodProvider = FoodProvider(repository: MockFoodRepository());
      await foodProvider.loadFoods();
    });

    test('Initial state loads all seeded Indian foods', () {
      expect(foodProvider.foods.length, greaterThanOrEqualTo(50));
      expect(foodProvider.selectedDietaryPreference, isNull);
    });

    test('Dietary filter "Veg Only" isolates pure vegetarian items', () {
      foodProvider.setDietaryFilter(AppConstants.dietVeg);
      expect(foodProvider.selectedDietaryPreference, AppConstants.dietVeg);
      expect(foodProvider.foods, isNotEmpty);

      for (final food in foodProvider.foods) {
        expect(food.dietaryClassification, AppConstants.dietVeg);
      }

      final names = foodProvider.foods.map((f) => f.name).toList();
      expect(names, contains('Paneer (Fresh Cow Milk)'));
      expect(names, contains('Soya Chunks (Dry / Raw)'));
      expect(names.contains('Chicken Breast (Skinless, Raw)'), isFalse);
      expect(names.contains('Whole Boiled Egg (Large, ~50g)'), isFalse);
    });

    test('Dietary filter "Eggetarian" isolates egg items exclusively', () {
      foodProvider.setDietaryFilter(AppConstants.dietEgg);
      expect(foodProvider.selectedDietaryPreference, AppConstants.dietEgg);
      expect(foodProvider.foods, isNotEmpty);

      for (final food in foodProvider.foods) {
        expect(food.dietaryClassification, AppConstants.dietEgg);
      }

      final names = foodProvider.foods.map((f) => f.name).toList();
      expect(names, contains('Whole Boiled Egg (Large, ~50g)'));
      expect(names, contains('Egg White (Boiled, ~33g each)'));
      expect(names.contains('Paneer (Fresh Cow Milk)'), isFalse);
      expect(names.contains('Chicken Breast (Boneless, Cooked)'), isFalse);
    });

    test('Dietary filter "Non-Veg" isolates animal meat & fish items exclusively', () {
      foodProvider.setDietaryFilter(AppConstants.dietNonVeg);
      expect(foodProvider.selectedDietaryPreference, AppConstants.dietNonVeg);
      expect(foodProvider.foods, isNotEmpty);

      for (final food in foodProvider.foods) {
        expect(food.dietaryClassification, AppConstants.dietNonVeg);
      }

      final names = foodProvider.foods.map((f) => f.name).toList();
      expect(names, contains('Chicken Breast (Boneless, Cooked)'));
      expect(names, contains('Fish (Rohu / Katla, Pan Cooked)'));
      expect(names.contains('Paneer (Fresh Cow Milk)'), isFalse);
      expect(names.contains('Whole Boiled Egg (Large, ~50g)'), isFalse);
    });

    test('Clearing dietary filter restores full catalogue', () {
      foodProvider.setDietaryFilter(AppConstants.dietVeg);
      expect(foodProvider.foods.length, lessThan(foodProvider.allFoods.length));

      foodProvider.setDietaryFilter(null);
      expect(foodProvider.foods.length, equals(foodProvider.allFoods.length));
    });

    test('Search query narrows results accurately', () {
      foodProvider.setSearchQuery('paneer');
      expect(foodProvider.foods, isNotEmpty);
      for (final food in foodProvider.foods) {
        final matches = food.name.toLowerCase().contains('paneer') ||
            food.category.toLowerCase().contains('paneer') ||
            food.preparationBasis.toLowerCase().contains('paneer');
        expect(matches, isTrue);
      }
    });

    test('Sort options order foods correctly', () {
      foodProvider.setSortOption(FoodSortOption.protein);
      for (int i = 0; i < foodProvider.foods.length - 1; i++) {
        expect(
          foodProvider.foods[i].proteinPer100 >= foodProvider.foods[i + 1].proteinPer100,
          isTrue,
        );
      }

      foodProvider.setSortOption(FoodSortOption.costAsc);
      for (int i = 0; i < foodProvider.foods.length - 1; i++) {
        expect(
          foodProvider.foods[i].costPer100 <= foodProvider.foods[i + 1].costPer100,
          isTrue,
        );
      }
    });
  });
}
