import '../database/database_helper.dart';
import '../models/food_item.dart';

class FoodRepository {
  final DatabaseHelper _dbHelper;

  FoodRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<FoodItem>> getAllFoods() async {
    return await _dbHelper.getAllFoods();
  }

  Future<FoodItem?> getFoodById(int id) async {
    return await _dbHelper.getFoodById(id);
  }

  Future<int> addFood(FoodItem food) async {
    return await _dbHelper.insertFood(food);
  }

  Future<int> updateFood(FoodItem food) async {
    return await _dbHelper.updateFood(food);
  }

  Future<int> deleteFood(int id) async {
    return await _dbHelper.deleteFood(id);
  }
}
