import '../data/models/meal_entry.dart';
import '../data/models/weight_log.dart';
import '../data/repositories/meal_repository.dart';
import '../data/repositories/tracking_repository.dart';

class DailyAnalyticsPoint {
  final DateTime date;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double cost;

  const DailyAnalyticsPoint({
    required this.date,
    this.calories = 0.0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.cost = 0.0,
  });
}

class AnalyticsService {
  final MealRepository _mealRepo;
  final TrackingRepository _trackingRepo;

  AnalyticsService({MealRepository? mealRepo, TrackingRepository? trackingRepo})
    : _mealRepo = mealRepo ?? MealRepository(),
      _trackingRepo = trackingRepo ?? TrackingRepository();

  /// Fetches daily nutrition and expenditure aggregated across the past [days] days
  Future<List<DailyAnalyticsPoint>> getNutritionHistory(int days) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(Duration(days: days - 1));

    final entries = await _mealRepo.getMealsBetweenDates(startDate, now);

    // Group by YYYY-MM-DD
    final Map<String, List<MealEntry>> grouped = {};
    for (int i = 0; i < days; i++) {
      final d = startDate.add(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      grouped[key] = [];
    }

    for (final e in entries) {
      final d = e.entryDate;
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (grouped.containsKey(key)) {
        grouped[key]!.add(e);
      }
    }

    final List<DailyAnalyticsPoint> points = [];
    for (int i = 0; i < days; i++) {
      final d = startDate.add(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final dayMeals = grouped[key] ?? [];

      double cals = 0.0;
      double prot = 0.0;
      double carbs = 0.0;
      double fat = 0.0;
      double cost = 0.0;

      for (final m in dayMeals) {
        cals += m.caloriesSnapshot;
        prot += m.proteinSnapshot;
        carbs += m.carbsSnapshot;
        fat += m.fatSnapshot;
        cost += m.costSnapshot;
      }

      points.add(
        DailyAnalyticsPoint(
          date: d,
          calories: cals,
          protein: prot,
          carbs: carbs,
          fat: fat,
          cost: cost,
        ),
      );
    }

    return points;
  }

  /// Fetches weight progression data for the past [days] days
  Future<List<WeightLog>> getWeightHistory(int days) async {
    return await _trackingRepo.getWeightLogs(limit: days);
  }
}
