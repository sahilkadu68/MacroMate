import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/activity_log.dart';
import '../models/food_item.dart';
import '../models/meal_entry.dart';
import '../models/recipe.dart';
import '../models/shopping_item.dart';
import '../models/user_profile.dart';
import '../models/water_log.dart';
import '../models/weight_log.dart';
import '../seed/indian_foods_seed.dart';
import 'database_factory_helper.dart';

class DatabaseHelper {
  static const String dbName = 'macromate_india.db';
  static const int dbVersion = 2;

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;
  bool _isFallbackMode = false;

  // In-memory fallback storage for web environments without WebAssembly/workers
  UserProfile? _memProfile;
  final List<FoodItem> _memFoods = [];
  final List<MealEntry> _memMealEntries = [];
  final List<WaterLog> _memWaterLogs = [];
  final List<WeightLog> _memWeightLogs = [];
  final List<ActivityLog> _memActivityLogs = [];
  final List<Recipe> _memRecipes = [];
  final List<ShoppingItem> _memShoppingItems = [];
  final Set<int> _memFavoriteFoodIds = {};
  int _nextId = 1000;

  bool get isFallbackMode => _isFallbackMode;

  void _initMemoryFallback() {
    _memProfile ??= UserProfile.defaultProfile();
    if (_memFoods.isEmpty) {
      int id = 1;
      for (final f in IndianFoodsSeed.initialFoods) {
        _memFoods.add(f.copyWith(id: id++));
      }
      _nextId = id + 10;
    }
  }

  Future<Database?> get database async {
    if (_isFallbackMode) return null;
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    try {
      _database = await _initDatabase();
      return _database;
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        return null;
      }
      rethrow;
    }
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
        price_quantity_basis REAL NOT NULL,
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
        FOREIGN KEY (food_id) REFERENCES foods (id) ON DELETE SET NULL
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

    // 7. recipes
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        servings INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 8. recipe_ingredients
    await db.execute('''
      CREATE TABLE recipe_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL,
        food_id INTEGER,
        food_name_snapshot TEXT NOT NULL,
        quantity REAL NOT NULL,
        measurement_unit TEXT NOT NULL,
        calories_snapshot REAL NOT NULL,
        protein_snapshot REAL NOT NULL,
        carbs_snapshot REAL NOT NULL,
        fat_snapshot REAL NOT NULL,
        cost_snapshot REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE,
        FOREIGN KEY (food_id) REFERENCES foods (id) ON DELETE SET NULL
      )
    ''');

    // 9. shopping_items
    await db.execute('''
      CREATE TABLE shopping_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        is_purchased INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 10. favorite_foods
    await db.execute('''
      CREATE TABLE favorite_foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        food_id INTEGER NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        FOREIGN KEY (food_id) REFERENCES foods (id) ON DELETE CASCADE
      )
    ''');

    // Create Indexes for performant date and category filtering
    await db.execute(
      'CREATE INDEX idx_meal_entries_date ON meal_entries(entry_date)',
    );
    await db.execute(
      'CREATE INDEX idx_meal_entries_type ON meal_entries(meal_type)',
    );
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
    await db.execute(
      'CREATE INDEX idx_recipe_ing_recipe ON recipe_ingredients(recipe_id)',
    );

    // Seed Initial Data
    await _seedDatabase(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recipes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          servings INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS recipe_ingredients (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          recipe_id INTEGER NOT NULL,
          food_id INTEGER,
          food_name_snapshot TEXT NOT NULL,
          quantity REAL NOT NULL,
          measurement_unit TEXT NOT NULL,
          calories_snapshot REAL NOT NULL,
          protein_snapshot REAL NOT NULL,
          carbs_snapshot REAL NOT NULL,
          fat_snapshot REAL NOT NULL,
          cost_snapshot REAL NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE,
          FOREIGN KEY (food_id) REFERENCES foods (id) ON DELETE SET NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS shopping_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          quantity REAL NOT NULL,
          unit TEXT NOT NULL,
          is_purchased INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorite_foods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          food_id INTEGER NOT NULL UNIQUE,
          created_at TEXT NOT NULL,
          FOREIGN KEY (food_id) REFERENCES foods (id) ON DELETE CASCADE
        )
      ''');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recipe_ing_recipe ON recipe_ingredients(recipe_id)',
      );
    }
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
    if (_isFallbackMode) {
      _memProfile ??= UserProfile.defaultProfile();
      return _memProfile!;
    }
    try {
      final db = await database;
      if (db == null) {
        _memProfile ??= UserProfile.defaultProfile();
        return _memProfile!;
      }
      final List<Map<String, dynamic>> maps = await db.query(
        'user_profile',
        orderBy: 'id ASC',
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return UserProfile.fromMap(maps.first);
      }
      final def = UserProfile.defaultProfile();
      final id = await db.insert('user_profile', def.toMap());
      return def.copyWith(id: id);
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        return _memProfile!;
      }
      rethrow;
    }
  }

  Future<int> updateUserProfile(UserProfile profile) async {
    if (_isFallbackMode) {
      _memProfile = profile;
      return 1;
    }
    try {
      final db = await database;
      if (db == null) {
        _memProfile = profile;
        return 1;
      }
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
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        _memProfile = profile;
        return 1;
      }
      rethrow;
    }
  }

  // ================= FOODS CRUD =================
  Future<List<FoodItem>> getAllFoods() async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      return List.from(_memFoods);
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        return List.from(_memFoods);
      }
      final List<Map<String, dynamic>> maps = await db.query(
        'foods',
        orderBy: 'name ASC',
      );
      return maps.map((m) => FoodItem.fromMap(m)).toList();
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        return List.from(_memFoods);
      }
      rethrow;
    }
  }

  Future<FoodItem?> getFoodById(int id) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      for (final f in _memFoods) {
        if (f.id == id) return f;
      }
      return null;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        for (final f in _memFoods) {
          if (f.id == id) return f;
        }
        return null;
      }
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
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        for (final f in _memFoods) {
          if (f.id == id) return f;
        }
        return null;
      }
      rethrow;
    }
  }

  Future<int> insertFood(FoodItem food) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      final id = _nextId++;
      _memFoods.add(food.copyWith(id: id));
      return id;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        final id = _nextId++;
        _memFoods.add(food.copyWith(id: id));
        return id;
      }
      return await db.insert('foods', food.toMap());
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        final id = _nextId++;
        _memFoods.add(food.copyWith(id: id));
        return id;
      }
      rethrow;
    }
  }

  Future<int> updateFood(FoodItem food) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      final idx = _memFoods.indexWhere((f) => f.id == food.id);
      if (idx != -1) _memFoods[idx] = food;
      return 1;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        final idx = _memFoods.indexWhere((f) => f.id == food.id);
        if (idx != -1) _memFoods[idx] = food;
        return 1;
      }
      return await db.update(
        'foods',
        food.toMap(),
        where: 'id = ?',
        whereArgs: [food.id],
      );
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        final idx = _memFoods.indexWhere((f) => f.id == food.id);
        if (idx != -1) _memFoods[idx] = food;
        return 1;
      }
      rethrow;
    }
  }

  Future<int> deleteFood(int id) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      _memFoods.removeWhere((f) => f.id == id);
      return 1;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        _memFoods.removeWhere((f) => f.id == id);
        return 1;
      }
      return await db.delete('foods', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        _memFoods.removeWhere((f) => f.id == id);
        return 1;
      }
      rethrow;
    }
  }

  // ================= MEAL ENTRIES CRUD =================
  Future<int> insertMealEntry(MealEntry entry) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      final id = _nextId++;
      _memMealEntries.add(entry.copyWith(id: id));
      return id;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        final id = _nextId++;
        _memMealEntries.add(entry.copyWith(id: id));
        return id;
      }
      return await db.insert('meal_entries', entry.toMap());
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        final id = _nextId++;
        _memMealEntries.add(entry.copyWith(id: id));
        return id;
      }
      rethrow;
    }
  }

  Future<List<MealEntry>> getMealEntriesForDate(DateTime date) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (_isFallbackMode) {
      _initMemoryFallback();
      return _memMealEntries.where((e) {
        final eDateStr =
            '${e.entryDate.year.toString().padLeft(4, '0')}-${e.entryDate.month.toString().padLeft(2, '0')}-${e.entryDate.day.toString().padLeft(2, '0')}';
        return eDateStr == dateStr;
      }).toList();
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        return _memMealEntries.where((e) {
          final eDateStr =
              '${e.entryDate.year.toString().padLeft(4, '0')}-${e.entryDate.month.toString().padLeft(2, '0')}-${e.entryDate.day.toString().padLeft(2, '0')}';
          return eDateStr == dateStr;
        }).toList();
      }
      final List<Map<String, dynamic>> maps = await db.query(
        'meal_entries',
        where: "entry_date LIKE ?",
        whereArgs: ['$dateStr%'],
        orderBy: 'id ASC',
      );
      return maps.map((m) => MealEntry.fromMap(m)).toList();
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        return _memMealEntries.where((e) {
          final eDateStr =
              '${e.entryDate.year.toString().padLeft(4, '0')}-${e.entryDate.month.toString().padLeft(2, '0')}-${e.entryDate.day.toString().padLeft(2, '0')}';
          return eDateStr == dateStr;
        }).toList();
      }
      rethrow;
    }
  }

  Future<List<MealEntry>> getMealEntriesBetweenDates(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startStr =
        '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr =
        '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}T23:59:59';

    if (_isFallbackMode) {
      _initMemoryFallback();
      return _memMealEntries.where((e) {
        return !e.entryDate.isBefore(startDate) &&
            !e.entryDate.isAfter(endDate.add(const Duration(days: 1)));
      }).toList();
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        return _memMealEntries.where((e) {
          return !e.entryDate.isBefore(startDate) &&
              !e.entryDate.isAfter(endDate.add(const Duration(days: 1)));
        }).toList();
      }
      final List<Map<String, dynamic>> maps = await db.query(
        'meal_entries',
        where: 'entry_date >= ? AND entry_date <= ?',
        whereArgs: [startStr, endStr],
        orderBy: 'entry_date ASC',
      );
      return maps.map((m) => MealEntry.fromMap(m)).toList();
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        return _memMealEntries.where((e) {
          return !e.entryDate.isBefore(startDate) &&
              !e.entryDate.isAfter(endDate.add(const Duration(days: 1)));
        }).toList();
      }
      rethrow;
    }
  }

  Future<void> insertMultipleMealEntries(List<MealEntry> entries) async {
    if (entries.isEmpty) return;
    if (_isFallbackMode) {
      _initMemoryFallback();
      for (final entry in entries) {
        final id = _nextId++;
        _memMealEntries.add(entry.copyWith(id: id));
      }
      return;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        for (final entry in entries) {
          final id = _nextId++;
          _memMealEntries.add(entry.copyWith(id: id));
        }
        return;
      }
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final entry in entries) {
          batch.insert('meal_entries', entry.toMap());
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        for (final entry in entries) {
          final id = _nextId++;
          _memMealEntries.add(entry.copyWith(id: id));
        }
        return;
      }
      rethrow;
    }
  }

  Future<int> updateMealEntry(MealEntry entry) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      final index = _memMealEntries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _memMealEntries[index] = entry;
        return 1;
      }
      return 0;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        final index = _memMealEntries.indexWhere((e) => e.id == entry.id);
        if (index != -1) {
          _memMealEntries[index] = entry;
          return 1;
        }
        return 0;
      }
      return await db.update(
        'meal_entries',
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        final index = _memMealEntries.indexWhere((e) => e.id == entry.id);
        if (index != -1) {
          _memMealEntries[index] = entry;
          return 1;
        }
        return 0;
      }
      rethrow;
    }
  }

  Future<int> deleteMealEntry(int id) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      _memMealEntries.removeWhere((e) => e.id == id);
      return 1;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        _memMealEntries.removeWhere((e) => e.id == id);
        return 1;
      }
      return await db.delete('meal_entries', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        _memMealEntries.removeWhere((e) => e.id == id);
        return 1;
      }
      rethrow;
    }
  }

  // ================= WATER LOGS CRUD =================
  Future<List<WaterLog>> getWaterLogsForDate(String date) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      return _memWaterLogs.where((w) => w.entryDate == date).toList();
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        return _memWaterLogs.where((w) => w.entryDate == date).toList();
      }
      final List<Map<String, dynamic>> maps = await db.query(
        'water_logs',
        where: 'entry_date = ?',
        whereArgs: [date],
        orderBy: 'id ASC',
      );
      return maps.map((m) => WaterLog.fromMap(m)).toList();
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        return _memWaterLogs.where((w) => w.entryDate == date).toList();
      }
      rethrow;
    }
  }

  Future<int> insertWaterLog(WaterLog log) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      final id = _nextId++;
      _memWaterLogs.add(
        WaterLog(
          id: id,
          entryDate: log.entryDate,
          quantityMl: log.quantityMl,
          createdAt: log.createdAt,
        ),
      );
      return id;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        final id = _nextId++;
        _memWaterLogs.add(
          WaterLog(
            id: id,
            entryDate: log.entryDate,
            quantityMl: log.quantityMl,
            createdAt: log.createdAt,
          ),
        );
        return id;
      }
      return await db.insert('water_logs', log.toMap());
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        final id = _nextId++;
        _memWaterLogs.add(
          WaterLog(
            id: id,
            entryDate: log.entryDate,
            quantityMl: log.quantityMl,
            createdAt: log.createdAt,
          ),
        );
        return id;
      }
      rethrow;
    }
  }

  Future<int> deleteWaterLog(int id) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      _memWaterLogs.removeWhere((w) => w.id == id);
      return 1;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        _memWaterLogs.removeWhere((w) => w.id == id);
        return 1;
      }
      return await db.delete('water_logs', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        _memWaterLogs.removeWhere((w) => w.id == id);
        return 1;
      }
      rethrow;
    }
  }

  Future<double> getTotalWaterForDate(String date) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      return _memWaterLogs.where((w) => w.entryDate == date).fold<double>(
        0.0,
        (double sum, w) => sum + w.quantityMl,
      );
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        return _memWaterLogs.where((w) => w.entryDate == date).fold<double>(
          0.0,
          (double sum, w) => sum + w.quantityMl,
        );
      }
      final result = await db.rawQuery(
        'SELECT SUM(quantity_ml) as total FROM water_logs WHERE entry_date = ?',
        [date],
      );
      if (result.isNotEmpty && result.first['total'] != null) {
        return (result.first['total'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        return _memWaterLogs.where((w) => w.entryDate == date).fold<double>(
          0.0,
          (double sum, w) => sum + w.quantityMl,
        );
      }
      rethrow;
    }
  }

  // ================= WEIGHT LOGS CRUD =================
  Future<List<WeightLog>> getWeightLogs({int limit = 60}) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      final logs = List<WeightLog>.from(_memWeightLogs);
      logs.sort((a, b) => b.measurementDate.compareTo(a.measurementDate));
      return logs.take(limit).toList();
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        final logs = List<WeightLog>.from(_memWeightLogs);
        logs.sort((a, b) => b.measurementDate.compareTo(a.measurementDate));
        return logs.take(limit).toList();
      }
      final List<Map<String, dynamic>> maps = await db.query(
        'weight_logs',
        orderBy: 'measurement_date DESC',
        limit: limit,
      );
      return maps.map((m) => WeightLog.fromMap(m)).toList();
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        final logs = List<WeightLog>.from(_memWeightLogs);
        logs.sort((a, b) => b.measurementDate.compareTo(a.measurementDate));
        return logs.take(limit).toList();
      }
      rethrow;
    }
  }

  Future<int> insertWeightLog(WeightLog log) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      final id = _nextId++;
      _memWeightLogs.add(
        WeightLog(
          id: id,
          measurementDate: log.measurementDate,
          weight: log.weight,
          notes: log.notes,
          createdAt: log.createdAt,
        ),
      );
      return id;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        final id = _nextId++;
        _memWeightLogs.add(
          WeightLog(
            id: id,
            measurementDate: log.measurementDate,
            weight: log.weight,
            notes: log.notes,
            createdAt: log.createdAt,
          ),
        );
        return id;
      }
      return await db.insert('weight_logs', log.toMap());
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        final id = _nextId++;
        _memWeightLogs.add(
          WeightLog(
            id: id,
            measurementDate: log.measurementDate,
            weight: log.weight,
            notes: log.notes,
            createdAt: log.createdAt,
          ),
        );
        return id;
      }
      rethrow;
    }
  }

  Future<int> deleteWeightLog(int id) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      _memWeightLogs.removeWhere((w) => w.id == id);
      return 1;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        _memWeightLogs.removeWhere((w) => w.id == id);
        return 1;
      }
      return await db.delete('weight_logs', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        _memWeightLogs.removeWhere((w) => w.id == id);
        return 1;
      }
      rethrow;
    }
  }

  // ================= ACTIVITY LOGS CRUD =================
  Future<List<ActivityLog>> getActivityLogsForDate(String date) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      return _memActivityLogs.where((a) => a.activityDate == date).toList();
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        return _memActivityLogs.where((a) => a.activityDate == date).toList();
      }
      final List<Map<String, dynamic>> maps = await db.query(
        'activity_logs',
        where: 'activity_date = ?',
        whereArgs: [date],
        orderBy: 'id ASC',
      );
      return maps.map((m) => ActivityLog.fromMap(m)).toList();
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        return _memActivityLogs.where((a) => a.activityDate == date).toList();
      }
      rethrow;
    }
  }

  Future<int> insertActivityLog(ActivityLog log) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      final id = _nextId++;
      _memActivityLogs.add(
        ActivityLog(
          id: id,
          activityDate: log.activityDate,
          activityType: log.activityType,
          durationMinutes: log.durationMinutes,
          estimatedCalories: log.estimatedCalories,
          notes: log.notes,
          createdAt: log.createdAt,
        ),
      );
      return id;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        final id = _nextId++;
        _memActivityLogs.add(
          ActivityLog(
            id: id,
            activityDate: log.activityDate,
            activityType: log.activityType,
            durationMinutes: log.durationMinutes,
            estimatedCalories: log.estimatedCalories,
            notes: log.notes,
            createdAt: log.createdAt,
          ),
        );
        return id;
      }
      return await db.insert('activity_logs', log.toMap());
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        final id = _nextId++;
        _memActivityLogs.add(
          ActivityLog(
            id: id,
            activityDate: log.activityDate,
            activityType: log.activityType,
            durationMinutes: log.durationMinutes,
            estimatedCalories: log.estimatedCalories,
            notes: log.notes,
            createdAt: log.createdAt,
          ),
        );
        return id;
      }
      rethrow;
    }
  }

  Future<int> deleteActivityLog(int id) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      _memActivityLogs.removeWhere((a) => a.id == id);
      return 1;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        _memActivityLogs.removeWhere((a) => a.id == id);
        return 1;
      }
      return await db.delete(
        'activity_logs',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        _memActivityLogs.removeWhere((a) => a.id == id);
        return 1;
      }
      rethrow;
    }
  }

  // ================= RECIPES CRUD =================
  Future<List<Recipe>> getAllRecipes() async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      return List.from(_memRecipes);
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        return List.from(_memRecipes);
      }
      final recipeMaps = await db.query('recipes', orderBy: 'name ASC');
      final List<Recipe> recipes = [];
      for (final rMap in recipeMaps) {
        final rId = rMap['id'] as int;
        final ingMaps = await db.query(
          'recipe_ingredients',
          where: 'recipe_id = ?',
          whereArgs: [rId],
        );
        final ingredients = ingMaps.map((m) => RecipeIngredient.fromMap(m)).toList();
        recipes.add(Recipe.fromMap(rMap, ingredients: ingredients));
      }
      return recipes;
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        return List.from(_memRecipes);
      }
      rethrow;
    }
  }

  Future<int> insertRecipe(Recipe recipe) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      final rId = _nextId++;
      final savedIngredients = recipe.ingredients.map((i) {
        return RecipeIngredient(
          id: _nextId++,
          recipeId: rId,
          foodId: i.foodId,
          foodName: i.foodName,
          quantity: i.quantity,
          measurementUnit: i.measurementUnit,
          calories: i.calories,
          protein: i.protein,
          carbs: i.carbs,
          fat: i.fat,
          cost: i.cost,
        );
      }).toList();
      _memRecipes.add(recipe.copyWith(id: rId, ingredients: savedIngredients));
      return rId;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        final rId = _nextId++;
        _memRecipes.add(recipe.copyWith(id: rId));
        return rId;
      }
      return await db.transaction<int>((txn) async {
        final rId = await txn.insert('recipes', recipe.toMap());
        final batch = txn.batch();
        for (final ing in recipe.ingredients) {
          batch.insert('recipe_ingredients', ing.toMap(rId));
        }
        await batch.commit(noResult: true);
        return rId;
      });
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        final rId = _nextId++;
        _memRecipes.add(recipe.copyWith(id: rId));
        return rId;
      }
      rethrow;
    }
  }

  Future<int> deleteRecipe(int id) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      _memRecipes.removeWhere((r) => r.id == id);
      return 1;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        _memRecipes.removeWhere((r) => r.id == id);
        return 1;
      }
      return await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        _memRecipes.removeWhere((r) => r.id == id);
        return 1;
      }
      rethrow;
    }
  }

  // ================= SHOPPING ITEMS CRUD =================
  Future<List<ShoppingItem>> getShoppingItems() async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      return List.from(_memShoppingItems);
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        return List.from(_memShoppingItems);
      }
      final maps = await db.query(
        'shopping_items',
        orderBy: 'is_purchased ASC, id DESC',
      );
      return maps.map((m) => ShoppingItem.fromMap(m)).toList();
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        return List.from(_memShoppingItems);
      }
      rethrow;
    }
  }

  Future<int> insertShoppingItem(ShoppingItem item) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      final id = _nextId++;
      _memShoppingItems.add(item.copyWith(id: id));
      return id;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        final id = _nextId++;
        _memShoppingItems.add(item.copyWith(id: id));
        return id;
      }
      return await db.insert('shopping_items', item.toMap());
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        final id = _nextId++;
        _memShoppingItems.add(item.copyWith(id: id));
        return id;
      }
      rethrow;
    }
  }

  Future<int> updateShoppingItem(ShoppingItem item) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      final idx = _memShoppingItems.indexWhere((i) => i.id == item.id);
      if (idx != -1) _memShoppingItems[idx] = item;
      return 1;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        final idx = _memShoppingItems.indexWhere((i) => i.id == item.id);
        if (idx != -1) _memShoppingItems[idx] = item;
        return 1;
      }
      return await db.update(
        'shopping_items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        final idx = _memShoppingItems.indexWhere((i) => i.id == item.id);
        if (idx != -1) _memShoppingItems[idx] = item;
        return 1;
      }
      rethrow;
    }
  }

  Future<int> deleteShoppingItem(int id) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      _memShoppingItems.removeWhere((i) => i.id == id);
      return 1;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        _memShoppingItems.removeWhere((i) => i.id == id);
        return 1;
      }
      return await db.delete('shopping_items', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        _memShoppingItems.removeWhere((i) => i.id == id);
        return 1;
      }
      rethrow;
    }
  }

  Future<void> clearPurchasedShoppingItems() async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      _memShoppingItems.removeWhere((i) => i.isPurchased);
      return;
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        _memShoppingItems.removeWhere((i) => i.isPurchased);
        return;
      }
      await db.delete('shopping_items', where: 'is_purchased = 1');
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        _memShoppingItems.removeWhere((i) => i.isPurchased);
        return;
      }
      rethrow;
    }
  }

  // ================= FAVORITE FOODS CRUD =================
  Future<Set<int>> getFavoriteFoodIds() async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      return Set.from(_memFavoriteFoodIds);
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        return Set.from(_memFavoriteFoodIds);
      }
      final maps = await db.query('favorite_foods', columns: ['food_id']);
      return maps.map((m) => m['food_id'] as int).toSet();
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        return Set.from(_memFavoriteFoodIds);
      }
      rethrow;
    }
  }

  Future<bool> toggleFavoriteFood(int foodId) async {
    if (_isFallbackMode) {
      _initMemoryFallback();
      if (_memFavoriteFoodIds.contains(foodId)) {
        _memFavoriteFoodIds.remove(foodId);
        return false;
      } else {
        _memFavoriteFoodIds.add(foodId);
        return true;
      }
    }
    try {
      final db = await database;
      if (db == null) {
        _initMemoryFallback();
        if (_memFavoriteFoodIds.contains(foodId)) {
          _memFavoriteFoodIds.remove(foodId);
          return false;
        } else {
          _memFavoriteFoodIds.add(foodId);
          return true;
        }
      }
      final existing = await db.query(
        'favorite_foods',
        where: 'food_id = ?',
        whereArgs: [foodId],
      );
      if (existing.isNotEmpty) {
        await db.delete('favorite_foods', where: 'food_id = ?', whereArgs: [foodId]);
        return false;
      } else {
        await db.insert('favorite_foods', {
          'food_id': foodId,
          'created_at': DateTime.now().toIso8601String(),
        });
        return true;
      }
    } catch (e) {
      if (kIsWeb) {
        _isFallbackMode = true;
        _initMemoryFallback();
        if (_memFavoriteFoodIds.contains(foodId)) {
          _memFavoriteFoodIds.remove(foodId);
          return false;
        } else {
          _memFavoriteFoodIds.add(foodId);
          return true;
        }
      }
      rethrow;
    }
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
