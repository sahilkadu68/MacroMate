import 'package:flutter/foundation.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/profile_repository.dart';
import '../services/nutrition_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileRepository _repository;

  UserProfile _profile = UserProfile.defaultProfile();
  bool _isLoading = false;
  String? _errorMessage;

  ProfileProvider({ProfileRepository? repository})
    : _repository = repository ?? ProfileRepository() {
    loadProfile();
  }

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.getProfile();
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    try {
      await _repository.saveProfile(newProfile);
      _profile = newProfile;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to save profile: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateGoals({
    double? budget,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? water,
  }) async {
    final updated = _profile.copyWith(
      dailyBudget: budget ?? _profile.dailyBudget,
      calorieTarget: calories ?? _profile.calorieTarget,
      proteinTarget: protein ?? _profile.proteinTarget,
      carbohydrateTarget: carbs ?? _profile.carbohydrateTarget,
      fatTarget: fat ?? _profile.fatTarget,
      waterTarget: water ?? _profile.waterTarget,
    );
    await updateProfile(updated);
  }

  /// Calculates estimated targets using the Mifflin-St Jeor equation
  Map<String, double> calculateEstimatedTargets({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String activityLevel,
    required String goal,
  }) {
    final bmr = NutritionService.calculateMifflinStJeorBmr(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );
    final tdee = NutritionService.calculateTdee(
      bmr: bmr,
      activityLevel: activityLevel,
    );
    final goalCalories = NutritionService.calculateGoalCalories(
      tdee: tdee,
      goal: goal,
    );
    final macroTargets = NutritionService.estimateMacroTargets(
      weightKg: weightKg,
      calorieTarget: goalCalories,
      goal: goal,
    );
    final waterTarget = NutritionService.estimateWaterTarget(weightKg);

    return {
      'bmr': bmr.roundToDouble(),
      'tdee': tdee.roundToDouble(),
      'calories': macroTargets['calories']!,
      'protein': macroTargets['protein']!,
      'carbs': macroTargets['carbs']!,
      'fat': macroTargets['fat']!,
      'water': waterTarget.roundToDouble(),
    };
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
