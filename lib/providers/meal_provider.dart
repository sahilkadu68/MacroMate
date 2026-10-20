import 'package:flutter/foundation.dart';
import '../data/models/meal_entry.dart';
import '../data/repositories/meal_repository.dart';
import '../services/nutrition_service.dart';

class MealProvider with ChangeNotifier {
  final MealRepository _repository;

  DateTime _selectedDate = DateTime.now();
  List<MealEntry> _dailyEntries = [];
  List<MealEntry> _recentHistoryEntries = [];
  DailyNutritionSummary _dailyTotals = const DailyNutritionSummary();
  bool _isLoading = false;
  String? _errorMessage;

  MealProvider({MealRepository? repository})
      : _repository = repository ?? MealRepository() {
    loadMealsForSelectedDate();
    _loadRecentHistory();
  }

  DateTime get selectedDate => _selectedDate;
  List<MealEntry> get dailyEntries => _dailyEntries;
  DailyNutritionSummary get dailyTotals => _dailyTotals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<MealEntry> getEntriesForMealType(String mealType) {
    return _dailyEntries.where((e) => e.mealType == mealType).toList();
  }

  /// Unique food IDs logged in recent history (up to last 14 days)
  List<int> get recentFoodIds {
    final ids = <int>[];
    for (final e in _recentHistoryEntries) {
      if (e.foodId != null && !ids.contains(e.foodId!)) {
        ids.add(e.foodId!);
      }
    }
    return ids;
  }

  Future<void> _loadRecentHistory() async {
    try {
      final now = DateTime.now();
      final twoWeeksAgo = now.subtract(const Duration(days: 14));
      _recentHistoryEntries =
          await _repository.getMealsBetweenDates(twoWeeksAgo, now);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    await loadMealsForSelectedDate();
  }

  Future<void> loadMealsForSelectedDate() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dailyEntries = await _repository.getMealsForDate(_selectedDate);
      _dailyTotals = NutritionService.calculateDailyTotals(_dailyEntries);
    } catch (e) {
      _errorMessage = 'Failed to load meals: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMeal(MealEntry entry) async {
    try {
      final id = await _repository.addMeal(entry);
      if (_isSameDay(entry.entryDate, _selectedDate)) {
        _dailyEntries.add(entry.copyWith(id: id));
        _dailyTotals = NutritionService.calculateDailyTotals(_dailyEntries);
        _recentHistoryEntries.insert(0, entry.copyWith(id: id));
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to save meal: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addMultipleMeals(List<MealEntry> entries) async {
    if (entries.isEmpty) return;
    try {
      await _repository.addMultipleMeals(entries);
      await loadMealsForSelectedDate();
      await _loadRecentHistory();
    } catch (e) {
      _errorMessage = 'Failed to save meals: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateMeal(MealEntry entry) async {
    try {
      await _repository.updateMeal(entry);
      final idx = _dailyEntries.indexWhere((e) => e.id == entry.id);
      if (idx != -1) {
        _dailyEntries[idx] = entry;
        _dailyTotals = NutritionService.calculateDailyTotals(_dailyEntries);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update meal: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMeal(int id) async {
    try {
      await _repository.deleteMeal(id);
      _dailyEntries.removeWhere((e) => e.id == id);
      _dailyTotals = NutritionService.calculateDailyTotals(_dailyEntries);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete meal: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Copies yesterday's entries for a given meal type into today's diary
  Future<int> repeatYesterdayMeal(String mealType) async {
    final yesterday = _selectedDate.subtract(const Duration(days: 1));
    final yesterdayEntries = await _repository.getMealsForDate(yesterday);
    final targetEntries =
        yesterdayEntries.where((e) => e.mealType == mealType).toList();

    if (targetEntries.isEmpty) return 0;

    final clonedEntries = targetEntries.map((e) {
      return e.copyWith(
        id: null,
        entryDate: _selectedDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();

    await addMultipleMeals(clonedEntries);
    return clonedEntries.length;
  }

  /// Copies a list of meal entries to a target date
  Future<void> copyEntriesToDate(
    List<MealEntry> entries,
    DateTime targetDate, {
    String? targetMealType,
  }) async {
    final cloned = entries.map((e) {
      return e.copyWith(
        id: null,
        entryDate: targetDate,
        mealType: targetMealType ?? e.mealType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();

    await _repository.addMultipleMeals(cloned);
    if (_isSameDay(targetDate, _selectedDate)) {
      await loadMealsForSelectedDate();
    }
  }

  /// Finds the highest protein source consumed today
  MealEntry? get topProteinEntry {
    if (_dailyEntries.isEmpty) return null;
    MealEntry top = _dailyEntries.first;
    for (final e in _dailyEntries) {
      if (e.proteinSnapshot > top.proteinSnapshot) {
        top = e;
      }
    }
    return top;
  }

  /// Finds the most cost-efficient protein source consumed today (highest g/₹)
  MealEntry? get mostEfficientEntry {
    if (_dailyEntries.isEmpty) return null;
    MealEntry? best;
    double highestEff = -1.0;
    for (final e in _dailyEntries) {
      final eff = e.proteinPerRupee;
      if (eff != null && eff > highestEff) {
        highestEff = eff;
        best = e;
      }
    }
    return best;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
