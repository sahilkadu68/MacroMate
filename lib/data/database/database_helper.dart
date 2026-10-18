import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/activity_log.dart';
import '../models/food_item.dart';
import '../models/meal_entry.dart';
import '../models/user_profile.dart';
import '../models/water_log.dart';
import '../models/weight_log.dart';
import '../seed/indian_foods_seed.dart';
import 'database_factory_helper.dart';

class DatabaseHelper {
  static const String dbName = 'macromate_india.db';
  static const int dbVersion = 1;

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    initDatabaseFactory();
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, dbName);

    return await openDatabase(
      path,
      version: dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. user_profile
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        display_name TEXT NOT NULL,
        age INTEGER,
        height REAL NOT NULL,
        current_weight REAL NOT NULL,
        activity_level TEXT NOT NULL,
        nutrition_goal TEXT NOT NULL,
        dietary_preference TEXT NOT NULL,
        daily_budget REAL NOT NULL,
        calorie_target REAL NOT NULL,
        protein_target REAL NOT NULL,
        carbohydrate_target REAL NOT NULL,
        fat_target REAL NOT NULL,
        water_target REAL NOT NULL,
        gender TEXT NOT NULL DEFAULT 'male',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. foods
    await db.execute('''
      CREATE TABLE foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        dietary_classification TEXT NOT NULL,
        calories_per_100 REAL NOT NULL,
        protein_per_100 REAL NOT NULL,
        carbs_per_100 REAL NOT NULL,
        fat_per_100 REAL NOT NULL,
        measurement_unit TEXT NOT NULL,
        preparation_basis TEXT NOT NULL,
        estimated_unit_price REAL NOT NULL,
        price_quantity_basis REAL NOT NULL DEFAULT 100.0,
        source_note TEXT,
        is_custom INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 3. meal_entries
    await db.execute('''
      CREATE TABLE meal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        food_id INTEGER,
        food_name_snapshot TEXT NOT NULL,
        entry_date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        quantity REAL NOT NULL,
        measurement_unit TEXT NOT NULL,
        preparation_basis TEXT NOT NULL,
        calories_snapshot REAL NOT NULL,
        protein_snapshot REAL NOT NULL,
        carbs_snapshot REAL NOT NULL,
        fat_snapshot REAL NOT NULL,
        unit_price_snapshot REAL NOT NULL,
        cost_snapshot REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE SET NULL
      )
    ''');

    // 4. water_logs
    await db.execute('''
      CREATE TABLE water_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_date TEXT NOT NULL,
        quantity_ml REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 5. weight_logs
    await db.execute('''
      CREATE TABLE weight_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        measurement_date TEXT NOT NULL,
        weight REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 6. activity_logs
    await db.execute('''
      CREATE TABLE activity_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_date TEXT NOT NULL,
        activity_type TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        estimated_calories REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Performance Indexes
    await db.execute('CREATE INDEX idx_meals_date ON meal_entries(entry_date)');
    await db.execute('CREATE INDEX idx_foods_cat ON foods(category)');
    await db.execute(
      'CREATE INDEX idx_foods_diet ON foods(dietary_classification)',
    );
    await db.execute('CREATE INDEX idx_water_date ON water_logs(entry_date)');
    await db.execute(
      'CREATE INDEX idx_weight_date ON weight_logs(measurement_date)',
    );
    await db.execute(
      'CREATE INDEX idx_activity_date ON activity_logs(activity_date)',
    );

    // Seed Initial Data in transaction
    await _seedDatabase(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Schema migration hook for future versions
  }

  Future<void> _seedDatabase(DatabaseExecutor db) async {
    // 1. Insert default UserProfile if not exists
    final profileCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM user_profile'),
    );
    if (profileCount == null || profileCount == 0) {
      await db.insert('user_profile', UserProfile.defaultProfile().toMap());
    }

    // 2. Insert initial Indian Foods if not exists
    final foodCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM foods'),
    );
    if (foodCount == null || foodCount == 0) {
      final batch = db.batch();
      for (final food in IndianFoodsSeed.initialFoods) {
        batch.insert('foods', food.toMap());
      }
      await batch.commit(noResult: true);
    }
  }

  // ================= USER PROFILE CRUD =================
  Future<UserProfile> getUserProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      orderBy: 'id ASC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    // Fallback if somehow empty
    final def = UserProfile.defaultProfile();
    final id = await db.insert('user_profile', def.toMap());
    return def.copyWith(id: id);
  }

  Future<int> updateUserProfile(UserProfile profile) async {
    final db = await database;
    final map = profile.toMap()
      ..['updated_at'] = DateTime.now().toIso8601String();
    if (profile.id != null) {
      return await db.update(
        'user_profile',
        map,
        where: 'id = ?',
        whereArgs: [profile.id],
      );
    } else {
      return await db.insert('user_profile', map);
    }
  }

  // ================= FOODS CRUD =================
  Future<List<FoodItem>> getAllFoods() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      orderBy: 'name ASC',
    );
    return maps.map((m) => FoodItem.fromMap(m)).toList();
  }

  Future<FoodItem?> getFoodById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return FoodItem.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertFood(FoodItem food) async {
    final db = await database;
    return await db.insert('foods', food.toMap());
  }

  Future<int> updateFood(FoodItem food) async {
    final db = await database;
    final map = food.toMap()..['updated_at'] = DateTime.now().toIso8601String();
    return await db.update('foods', map, where: 'id = ?', whereArgs: [food.id]);
  }

  Future<int> deleteFood(int id) async {
    final db = await database;
    // Meal entries reference food_id with ON DELETE SET NULL, preserving meal history
    return await db.delete('foods', where: 'id = ?', whereArgs: [id]);
  }

  // ================= MEAL ENTRIES CRUD =================
  Future<List<MealEntry>> getMealEntriesForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();
    final endOfDay = DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
      999,
    ).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'meal_entries',
      where: 'entry_date >= ? AND entry_date <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => MealEntry.fromMap(m)).toList();
  }

  Future<List<MealEntry>> getMealEntriesBetweenDates(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startStr = DateTime(
      start.year,
      start.month,
      start.day,
    ).toIso8601String();
    final endStr = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
      999,
    ).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'meal_entries',
      where: 'entry_date >= ? AND entry_date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'entry_date ASC',
    );
    return maps.map((m) => MealEntry.fromMap(m)).toList();
  }

  Future<int> insertMealEntry(MealEntry entry) async {
    final db = await database;
    return await db.insert('meal_entries', entry.toMap());
  }

  Future<void> insertMultipleMealEntries(List<MealEntry> entries) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final entry in entries) {
        batch.insert('meal_entries', entry.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  Future<int> updateMealEntry(MealEntry entry) async {
    final db = await database;
    final map = entry.toMap()
      ..['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'meal_entries',
      map,
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteMealEntry(int id) async {
    final db = await database;
    return await db.delete('meal_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ================= WATER LOGS CRUD =================
  Future<List<WaterLog>> getWaterLogsForDate(String dateStr) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'water_logs',
      where: 'entry_date = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => WaterLog.fromMap(m)).toList();
  }

  Future<double> getTotalWaterForDate(String dateStr) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity_ml) as total FROM water_logs WHERE entry_date = ?',
      [dateStr],
    );
    final val = result.first['total'];
    return (val as num?)?.toDouble() ?? 0.0;
  }

  Future<int> insertWaterLog(WaterLog log) async {
    final db = await database;
    return await db.insert('water_logs', log.toMap());
  }

  Future<int> deleteWaterLog(int id) async {
    final db = await database;
    return await db.delete('water_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ================= WEIGHT LOGS CRUD =================
  Future<List<WeightLog>> getWeightLogs({int limit = 60}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'weight_logs',
      orderBy: 'measurement_date ASC',
      limit: limit,
    );
    return maps.map((m) => WeightLog.fromMap(m)).toList();
  }

  Future<int> insertWeightLog(WeightLog log) async {
    final db = await database;
    return await db.insert('weight_logs', log.toMap());
  }

  Future<int> deleteWeightLog(int id) async {
    final db = await database;
    return await db.delete('weight_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ================= ACTIVITY LOGS CRUD =================
  Future<List<ActivityLog>> getActivityLogsForDate(String dateStr) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activity_logs',
      where: 'activity_date = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => ActivityLog.fromMap(m)).toList();
  }

  Future<int> insertActivityLog(ActivityLog log) async {
    final db = await database;
    return await db.insert('activity_logs', log.toMap());
  }

  Future<int> deleteActivityLog(int id) async {
    final db = await database;
    return await db.delete('activity_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
