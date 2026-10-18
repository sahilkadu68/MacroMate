import '../database/database_helper.dart';
import '../models/meal_entry.dart';

class MealRepository {
  final DatabaseHelper _dbHelper;

  MealRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<MealEntry>> getMealsForDate(DateTime date) async {
    return await _dbHelper.getMealEntriesForDate(date);
  }

  Future<List<MealEntry>> getMealsBetweenDates(
    DateTime start,
    DateTime end,
  ) async {
    return await _dbHelper.getMealEntriesBetweenDates(start, end);
  }

  Future<int> addMeal(MealEntry entry) async {
    return await _dbHelper.insertMealEntry(entry);
  }

  Future<void> addMultipleMeals(List<MealEntry> entries) async {
    await _dbHelper.insertMultipleMealEntries(entries);
  }

  Future<int> updateMeal(MealEntry entry) async {
    return await _dbHelper.updateMealEntry(entry);
  }

  Future<int> deleteMeal(int id) async {
    return await _dbHelper.deleteMealEntry(id);
  }
}
