import 'package:flutter/foundation.dart';
import '../data/models/meal_entry.dart';
import '../data/repositories/meal_repository.dart';
import '../services/nutrition_service.dart';

class MealProvider with ChangeNotifier {
  final MealRepository _repository;

  DateTime _selectedDate = DateTime.now();
  List<MealEntry> _dailyEntries = [];
  DailyNutritionSummary _dailyTotals = const DailyNutritionSummary();
  bool _isLoading = false;
  String? _errorMessage;

  MealProvider({MealRepository? repository})
    : _repository = repository ?? MealRepository() {
    loadMealsForSelectedDate();
  }

  DateTime get selectedDate => _selectedDate;
  List<MealEntry> get dailyEntries => _dailyEntries;
  DailyNutritionSummary get dailyTotals => _dailyTotals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<MealEntry> getEntriesForMealType(String mealType) {
    return _dailyEntries.where((e) => e.mealType == mealType).toList();
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
      // If the entry belongs to the currently viewed date, update state
      if (_isSameDay(entry.entryDate, _selectedDate)) {
        _dailyEntries.add(entry.copyWith(id: id));
        _dailyTotals = NutritionService.calculateDailyTotals(_dailyEntries);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to save meal: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addMultipleMeals(List<MealEntry> entries) async {
    try {
      await _repository.addMultipleMeals(entries);
      await loadMealsForSelectedDate();
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
