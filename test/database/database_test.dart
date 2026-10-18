import 'package:flutter_test/flutter_test.dart';
import 'package:macromate_india/core/constants/app_constants.dart';
import 'package:macromate_india/data/database/database_helper.dart';
import 'package:macromate_india/data/models/activity_log.dart';
import 'package:macromate_india/data/models/food_item.dart';
import 'package:macromate_india/data/models/meal_entry.dart';
import 'package:macromate_india/data/models/water_log.dart';
import 'package:macromate_india/data/models/weight_log.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper dbHelper;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dbPath = await databaseFactory.getDatabasesPath();
    final path = p.join(dbPath, DatabaseHelper.dbName);
    await databaseFactory.deleteDatabase(path);
  });

  setUp(() async {
    dbHelper = DatabaseHelper.instance;
    await dbHelper.database;
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('Database Initialization & Seeding Tests', () {
    test('seeds 50+ Indian food items idempotently', () async {
      final foods = await dbHelper.getAllFoods();
      expect(foods.length, greaterThanOrEqualTo(50));

      // Check key staples exist
      final names = foods.map((f) => f.name).toList();
      expect(names, contains('Paneer (Fresh Cow Milk)'));
      expect(names, contains('Soya Chunks (Dry / Raw)'));
      expect(names, contains('Whole Boiled Egg (Large, ~50g)'));
      expect(names, contains('Yellow Moong Dal (Cooked Dal Tadka)'));
      expect(names, contains('Hung Curd / Greek Yogurt (Plain)'));
      expect(names, contains('Double Toned Milk (1.5% Fat)'));
    });

    test('initializes default student user profile', () async {
      final profile = await dbHelper.getUserProfile();
      expect(profile.dailyBudget, equals(AppConstants.defaultDailyBudget));
      expect(profile.calorieTarget, equals(AppConstants.defaultCalories));
      expect(profile.proteinTarget, equals(AppConstants.defaultProtein));
    });
  });

  group('Food CRUD & Protein Efficiency Tests', () {
    test('can add custom food item and compute protein efficiency', () async {
      final customFood = FoodItem(
        name: 'Whey Protein Isolate (Student Brand)',
        category: AppConstants.catOther,
        dietaryClassification: AppConstants.dietVeg,
        caloriesPer100: 380,
        proteinPer100: 80.0,
        carbsPer100: 4.0,
        fatPer100: 2.0,
        measurementUnit: AppConstants.unitGrams,
        preparationBasis: AppConstants.prepRaw,
        estimatedUnitPrice: 2400.0,
        priceQuantityBasis:
            1000.0, // ₹240 per 100g -> ₹2.40 per g, 80g protein -> 80/240 = 0.33 g/₹
        isCustom: true,
      );

      final id = await dbHelper.insertFood(customFood);
      expect(id, isPositive);

      final fetched = await dbHelper.getFoodById(id);
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Whey Protein Isolate (Student Brand)'));
      expect(fetched.isCustom, isTrue);
      expect(fetched.costPer100, closeTo(240.0, 0.01));
      expect(fetched.proteinPerRupee, closeTo(0.333, 0.01));

      // Cleanup
      await dbHelper.deleteFood(id);
      final afterDelete = await dbHelper.getFoodById(id);
      expect(afterDelete, isNull);
    });
  });

  group('Meal Logging & Historical Snapshot Immutability Tests', () {
    test(
      'preserves historical nutritional snapshots when food price or macros change',
      () async {
        final testDate = DateTime(2026, 10, 19);

        // 1. Create a food item
        final food = FoodItem(
          name: 'Test Dal Tadka',
          category: AppConstants.catPlantProtein,
          dietaryClassification: AppConstants.dietVeg,
          caloriesPer100: 120.0,
          proteinPer100: 7.0,
          carbsPer100: 16.0,
          fatPer100: 3.5,
          measurementUnit: AppConstants.unitGrams,
          preparationBasis: AppConstants.prepCooked,
          estimatedUnitPrice: 100.0,
          priceQuantityBasis: 500.0, // ₹20 per 100g
          isCustom: true,
        );
        final foodId = await dbHelper.insertFood(food);

        // 2. Log 200g serving on 2026-10-19
        final entry = MealEntry.fromFoodItem(
          food: food.copyWith(id: foodId),
          entryDate: testDate,
          mealType: AppConstants.mealLunch,
          quantity: 200.0,
        );
        final entryId = await dbHelper.insertMealEntry(entry);
        expect(entryId, isPositive);

        // Verify snapshot values
        final loggedEntries = await dbHelper.getMealEntriesForDate(testDate);
        final logged = loggedEntries.firstWhere((e) => e.id == entryId);
        expect(logged.caloriesSnapshot, closeTo(240.0, 0.01));
        expect(logged.proteinSnapshot, closeTo(14.0, 0.01));
        expect(logged.costSnapshot, closeTo(40.0, 0.01));

        // 3. Mutate the base food item (e.g. price inflation + different recipe)
        final mutatedFood = food.copyWith(
          id: foodId,
          caloriesPer100: 200.0, // Changed from 120
          proteinPer100: 12.0, // Changed from 7
          estimatedUnitPrice: 250.0, // Changed from 100
        );
        await dbHelper.updateFood(mutatedFood);

        // 4. Re-fetch logged meal entry and verify snapshot is 100% IMMUTABLE
        final loggedEntriesAfter = await dbHelper.getMealEntriesForDate(
          testDate,
        );
        final preserved = loggedEntriesAfter.firstWhere((e) => e.id == entryId);
        expect(
          preserved.caloriesSnapshot,
          closeTo(240.0, 0.01),
          reason: 'Calories snapshot must be preserved',
        );
        expect(
          preserved.proteinSnapshot,
          closeTo(14.0, 0.01),
          reason: 'Protein snapshot must be preserved',
        );
        expect(
          preserved.costSnapshot,
          closeTo(40.0, 0.01),
          reason: 'Cost snapshot must be preserved',
        );

        // Cleanup
        await dbHelper.deleteMealEntry(entryId);
        await dbHelper.deleteFood(foodId);
      },
    );
  });

  group('Water, Weight, and Activity Tracking Tests', () {
    test('logs water intake and calculates daily totals', () async {
      final log1 = WaterLog(entryDate: '2026-10-19', quantityMl: 250);
      final log2 = WaterLog(entryDate: '2026-10-19', quantityMl: 500);

      await dbHelper.insertWaterLog(log1);
      await dbHelper.insertWaterLog(log2);

      final total = await dbHelper.getTotalWaterForDate('2026-10-19');
      expect(total, equals(750.0));
    });

    test('logs weight and tracks chronologically', () async {
      final w1 = WeightLog(
        measurementDate: '2026-10-10',
        weight: 68.5,
        notes: 'Morning fasting',
      );
      final w2 = WeightLog(
        measurementDate: '2026-10-17',
        weight: 68.0,
        notes: 'Post workout',
      );

      final id1 = await dbHelper.insertWeightLog(w1);
      final id2 = await dbHelper.insertWeightLog(w2);

      final logs = await dbHelper.getWeightLogs();
      expect(logs.any((l) => l.id == id1 && l.weight == 68.5), isTrue);
      expect(logs.any((l) => l.id == id2 && l.weight == 68.0), isTrue);
    });

    test('logs physical activity with calorie burn', () async {
      final act = ActivityLog(
        activityDate: '2026-10-19',
        activityType: 'Weight Training / Gym',
        durationMinutes: 60,
        estimatedCalories: 300.0,
      );

      final id = await dbHelper.insertActivityLog(act);
      final logs = await dbHelper.getActivityLogsForDate('2026-10-19');
      expect(
        logs.any((a) => a.id == id && a.estimatedCalories == 300.0),
        isTrue,
      );
    });
  });
}
