import '../database/database_helper.dart';
import '../models/activity_log.dart';
import '../models/water_log.dart';
import '../models/weight_log.dart';

class TrackingRepository {
  final DatabaseHelper _dbHelper;

  TrackingRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // Water
  Future<List<WaterLog>> getWaterLogs(String dateStr) async {
    return await _dbHelper.getWaterLogsForDate(dateStr);
  }

  Future<double> getTotalWater(String dateStr) async {
    return await _dbHelper.getTotalWaterForDate(dateStr);
  }

  Future<int> addWater(WaterLog log) async {
    return await _dbHelper.insertWaterLog(log);
  }

  Future<int> deleteWater(int id) async {
    return await _dbHelper.deleteWaterLog(id);
  }

  // Weight
  Future<List<WeightLog>> getWeightLogs({int limit = 60}) async {
    return await _dbHelper.getWeightLogs(limit: limit);
  }

  Future<int> addWeight(WeightLog log) async {
    return await _dbHelper.insertWeightLog(log);
  }

  Future<int> deleteWeight(int id) async {
    return await _dbHelper.deleteWeightLog(id);
  }

  // Activity
  Future<List<ActivityLog>> getActivityLogs(String dateStr) async {
    return await _dbHelper.getActivityLogsForDate(dateStr);
  }

  Future<int> addActivity(ActivityLog log) async {
    return await _dbHelper.insertActivityLog(log);
  }

  Future<int> deleteActivity(int id) async {
    return await _dbHelper.deleteActivityLog(id);
  }
}
