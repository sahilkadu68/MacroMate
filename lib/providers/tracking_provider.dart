import 'package:flutter/foundation.dart';
import '../core/utils/formatters.dart';
import '../data/models/activity_log.dart';
import '../data/models/water_log.dart';
import '../data/models/weight_log.dart';
import '../data/repositories/tracking_repository.dart';

class TrackingProvider with ChangeNotifier {
  final TrackingRepository _repository;

  DateTime _selectedDate = DateTime.now();
  double _todayWaterMl = 0.0;
  List<WaterLog> _waterLogs = [];
  List<WeightLog> _weightLogs = [];
  List<ActivityLog> _activityLogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  TrackingProvider({TrackingRepository? repository})
    : _repository = repository ?? TrackingRepository() {
    loadAllForDate(_selectedDate);
    loadWeightHistory();
  }

  double get todayWaterMl => _todayWaterMl;
  List<WaterLog> get waterLogs => _waterLogs;
  List<WeightLog> get weightLogs => _weightLogs;
  List<ActivityLog> get activityLogs => _activityLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  WeightLog? get latestWeight =>
      _weightLogs.isNotEmpty ? _weightLogs.last : null;

  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    await loadAllForDate(date);
  }

  Future<void> loadAllForDate(DateTime date) async {
    _isLoading = true;
    notifyListeners();
    final dateStr = Formatters.toIsoDateOnly(date);
    try {
      _todayWaterMl = await _repository.getTotalWater(dateStr);
      _waterLogs = await _repository.getWaterLogs(dateStr);
      _activityLogs = await _repository.getActivityLogs(dateStr);
    } catch (e) {
      _errorMessage = 'Failed to load tracking data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWeightHistory() async {
    try {
      _weightLogs = await _repository.getWeightLogs(limit: 60);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load weight history: $e';
      notifyListeners();
    }
  }

  // Water
  Future<void> addWater(double amountMl) async {
    final dateStr = Formatters.toIsoDateOnly(_selectedDate);
    final log = WaterLog(entryDate: dateStr, quantityMl: amountMl);
    try {
      final id = await _repository.addWater(log);
      _todayWaterMl += amountMl;
      _waterLogs.add(
        WaterLog(id: id, entryDate: dateStr, quantityMl: amountMl),
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add water: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeWaterLog(int id) async {
    try {
      final item = _waterLogs.firstWhere((w) => w.id == id);
      await _repository.deleteWater(id);
      _todayWaterMl = (_todayWaterMl - item.quantityMl).clamp(0.0, 99999.0);
      _waterLogs.removeWhere((w) => w.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete water entry: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Weight
  Future<void> addWeight(double weight, {String? notes}) async {
    final dateStr = Formatters.toIsoDateOnly(_selectedDate);
    final log = WeightLog(
      measurementDate: dateStr,
      weight: weight,
      notes: notes,
    );
    try {
      final id = await _repository.addWeight(log);
      _weightLogs.add(
        WeightLog(
          id: id,
          measurementDate: dateStr,
          weight: weight,
          notes: notes,
        ),
      );
      _weightLogs.sort(
        (a, b) => a.measurementDate.compareTo(b.measurementDate),
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to log weight: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteWeight(int id) async {
    try {
      await _repository.deleteWeight(id);
      _weightLogs.removeWhere((w) => w.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete weight log: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Activity
  Future<void> addActivity({
    required String type,
    required int durationMinutes,
    required double estimatedCalories,
    String? notes,
  }) async {
    final dateStr = Formatters.toIsoDateOnly(_selectedDate);
    final log = ActivityLog(
      activityDate: dateStr,
      activityType: type,
      durationMinutes: durationMinutes,
      estimatedCalories: estimatedCalories,
      notes: notes,
    );
    try {
      final id = await _repository.addActivity(log);
      _activityLogs.add(
        ActivityLog(
          id: id,
          activityDate: dateStr,
          activityType: type,
          durationMinutes: durationMinutes,
          estimatedCalories: estimatedCalories,
          notes: notes,
        ),
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to log activity: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteActivity(int id) async {
    try {
      await _repository.deleteActivity(id);
      _activityLogs.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete activity log: $e';
      notifyListeners();
      rethrow;
    }
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
