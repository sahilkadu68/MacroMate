import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macromate_india/core/theme/app_theme.dart';
import 'package:macromate_india/data/models/food_item.dart';
import 'package:macromate_india/data/models/meal_entry.dart';
import 'package:macromate_india/data/repositories/food_repository.dart';
import 'package:macromate_india/data/repositories/meal_repository.dart';
import 'package:macromate_india/data/seed/indian_foods_seed.dart';
import 'package:macromate_india/features/meal_logging/log_meal_screen.dart';
import 'package:macromate_india/providers/food_provider.dart';
import 'package:macromate_india/providers/meal_provider.dart';
import 'package:provider/provider.dart';

class MockFoodRepo implements FoodRepository {
  final List<FoodItem> _foods = IndianFoodsSeed.initialFoods
      .asMap()
      .entries
      .map((e) => e.value.copyWith(id: e.key + 1))
      .toList();

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

class MockMealRepo implements MealRepository {
  final List<MealEntry> _entries = [];

  @override
  Future<List<MealEntry>> getMealsForDate(DateTime date) async =>
      List.from(_entries);

  @override
  Future<List<MealEntry>> getMealsBetweenDates(
    DateTime start,
    DateTime end,
  ) async => List.from(_entries);

  @override
  Future<int> addMeal(MealEntry entry) async {
    _entries.add(entry.copyWith(id: _entries.length + 1));
    return _entries.length;
  }

  @override
  Future<void> addMultipleMeals(List<MealEntry> entries) async {
    for (final e in entries) {
      _entries.add(e.copyWith(id: _entries.length + 1));
    }
  }

  @override
  Future<int> updateMeal(MealEntry entry) async => 1;

  @override
  Future<int> deleteMeal(int id) async => 1;
}

void main() {
  late FoodProvider foodProvider;
  late MealProvider mealProvider;

  setUp(() async {
    foodProvider = FoodProvider(repository: MockFoodRepo());
    await foodProvider.loadFoods();
    mealProvider = MealProvider(repository: MockMealRepo());
  });

  Widget buildTestableLogMealScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FoodProvider>.value(value: foodProvider),
        ChangeNotifierProvider<MealProvider>.value(value: mealProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: LogMealScreen(entryDate: DateTime.now()),
      ),
    );
  }

  testWidgets(
    'LogMealScreen renders without infinite width or RenderFlex layout exception',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableLogMealScreen());
      await tester.pumpAndSettle();

      // Verify header and initial meal slot
      expect(find.text('Log Meal'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);

      // Verify the Save Meal button is present with bounded finite width
      final saveButtonFinder = find.widgetWithText(
        ElevatedButton,
        'Save Meal (0)',
      );
      expect(saveButtonFinder, findsOneWidget);

      final RenderBox buttonBox = tester.renderObject(saveButtonFinder);
      expect(buttonBox.hasSize, isTrue);
      expect(buttonBox.size.width.isFinite, isTrue);
      expect(buttonBox.size.height.isFinite, isTrue);

      // Tap to add a food item to staged list (opens portion dialog)
      final addButtons = find.byIcon(Icons.add_circle);
      expect(addButtons, findsWidgets);
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // Verify portion dialog appears and confirm addition
      expect(find.text('Add to Meal'), findsOneWidget);
      await tester.tap(find.text('Add to Meal'));
      await tester.pumpAndSettle();

      // Verify staged item appears and button text updates to Save Meal (1)
      expect(find.text('Save Meal (1)'), findsOneWidget);

      final RenderBox buttonBoxAfter = tester.renderObject(
        find.widgetWithText(ElevatedButton, 'Save Meal (1)'),
      );
      expect(buttonBoxAfter.size.width.isFinite, isTrue);

      // Tap the Save Meal button and verify atomic save executes without layout crash
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Meal (1)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    },
  );

  testWidgets(
    'LogMealScreen renders safely on wide desktop viewport without infinite width exception',
    (WidgetTester tester) async {
      // Simulate wide desktop web viewport
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableLogMealScreen());
      await tester.pumpAndSettle();

      final saveButtonFinder = find.widgetWithText(
        ElevatedButton,
        'Save Meal (0)',
      );
      expect(saveButtonFinder, findsOneWidget);

      final RenderBox buttonBox = tester.renderObject(saveButtonFinder);
      expect(buttonBox.size.width.isFinite, isTrue);
      expect(buttonBox.size.width, greaterThan(0));
    },
  );
}
