import 'package:flutter_test/flutter_test.dart';
import 'package:macromate_india/data/models/food_item.dart';
import 'package:macromate_india/data/models/shopping_item.dart';
import 'package:macromate_india/services/shopping_cost_service.dart';

void main() {
  final rice = FoodItem(
    name: 'Rice',
    category: 'Staples',
    dietaryClassification: 'Vegetarian',
    caloriesPer100: 350,
    proteinPer100: 7,
    carbsPer100: 77,
    fatPer100: 1,
    packagePrice: 80,
    packageQuantity: 1000,
  );
  test(
    'shopping converts kg to grams and reflects edited catalogue prices',
    () {
      final item = ShoppingItem(name: 'Rice', quantity: 0.5, unit: 'kg');
      expect(ShoppingCostService.estimate(item, [rice]), 40);
      expect(
        ShoppingCostService.estimate(item, [rice.copyWith(packagePrice: 100)]),
        50,
      );
    },
  );
  test('missing, incompatible and ambiguous prices remain unknown', () {
    expect(
      ShoppingCostService.estimate(
        ShoppingItem(name: 'Rice', quantity: 1, unit: 'L'),
        [rice],
      ),
      isNull,
    );
    expect(
      ShoppingCostService.estimate(ShoppingItem(name: 'Salt', quantity: 1), [
        rice,
      ]),
      isNull,
    );
    expect(
      ShoppingCostService.estimate(ShoppingItem(name: 'Rice', quantity: 1), [
        rice,
        rice,
      ]),
      isNull,
    );
    expect(
      ShoppingCostService.estimate(
        ShoppingItem(name: 'Rice', quantity: double.nan),
        [rice],
      ),
      isNull,
    );
  });
}
