import 'package:flutter/foundation.dart';
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
  bool _isFallbackMode = false;

  // In-memory fallback storage for web environments without WebAssembly/workers
  UserProfile? _memProfile;
  final List<FoodItem> _memFoods = [];
  final List<MealEntry> _memMealEntries = [];
  final List<WaterLog> _memWaterLogs = [];
  final List<WeightLog> _memWeightLogs = [];
  final List<ActivityLog> _memActivityLogs = [];
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

    // Seed Initial Data
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
    for (final entry in entries) {
      await insertMealEntry(entry);
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

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
