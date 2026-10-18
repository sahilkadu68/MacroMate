import '../../core/constants/app_constants.dart';

class UserProfile {
  final int? id;
  final String displayName;
  final int? age;
  final double height; // cm
  final double currentWeight; // kg
  final String activityLevel;
  final String nutritionGoal;
  final String dietaryPreference;
  final double dailyBudget; // INR
  final double calorieTarget; // kcal
  final double proteinTarget; // g
  final double carbohydrateTarget; // g
  final double fatTarget; // g
  final double waterTarget; // ml
  final String gender; // 'male', 'female', 'other' for Mifflin-St Jeor formula
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    this.id,
    this.displayName = 'Student Athlete',
    this.age = 21,
    this.height = 172.0,
    this.currentWeight = 68.0,
    this.activityLevel = AppConstants.activityModerate,
    this.nutritionGoal = AppConstants.goalGain,
    this.dietaryPreference = AppConstants.dietVeg,
    this.dailyBudget = AppConstants.defaultDailyBudget,
    this.calorieTarget = AppConstants.defaultCalories,
    this.proteinTarget = AppConstants.defaultProtein,
    this.carbohydrateTarget = AppConstants.defaultCarbs,
    this.fatTarget = AppConstants.defaultFat,
    this.waterTarget = AppConstants.defaultWater,
    this.gender = 'male',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory UserProfile.defaultProfile() {
    return UserProfile();
  }

  UserProfile copyWith({
    int? id,
    String? displayName,
    int? age,
    double? height,
    double? currentWeight,
    String? activityLevel,
    String? nutritionGoal,
    String? dietaryPreference,
    double? dailyBudget,
    double? calorieTarget,
    double? proteinTarget,
    double? carbohydrateTarget,
    double? fatTarget,
    double? waterTarget,
    String? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      height: height ?? this.height,
      currentWeight: currentWeight ?? this.currentWeight,
      activityLevel: activityLevel ?? this.activityLevel,
      nutritionGoal: nutritionGoal ?? this.nutritionGoal,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      dailyBudget: dailyBudget ?? this.dailyBudget,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      proteinTarget: proteinTarget ?? this.proteinTarget,
      carbohydrateTarget: carbohydrateTarget ?? this.carbohydrateTarget,
      fatTarget: fatTarget ?? this.fatTarget,
      waterTarget: waterTarget ?? this.waterTarget,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'age': age,
      'height': height,
      'current_weight': currentWeight,
      'activity_level': activityLevel,
      'nutrition_goal': nutritionGoal,
      'dietary_preference': dietaryPreference,
      'daily_budget': dailyBudget,
      'calorie_target': calorieTarget,
      'protein_target': proteinTarget,
      'carbohydrate_target': carbohydrateTarget,
      'fat_target': fatTarget,
      'water_target': waterTarget,
      'gender': gender,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      displayName: map['display_name'] as String? ?? 'Student Athlete',
      age: map['age'] as int?,
      height: (map['height'] as num?)?.toDouble() ?? 172.0,
      currentWeight: (map['current_weight'] as num?)?.toDouble() ?? 68.0,
      activityLevel:
          map['activity_level'] as String? ?? AppConstants.activityModerate,
      nutritionGoal: map['nutrition_goal'] as String? ?? AppConstants.goalGain,
      dietaryPreference:
          map['dietary_preference'] as String? ?? AppConstants.dietVeg,
      dailyBudget:
          (map['daily_budget'] as num?)?.toDouble() ??
          AppConstants.defaultDailyBudget,
      calorieTarget:
          (map['calorie_target'] as num?)?.toDouble() ??
          AppConstants.defaultCalories,
      proteinTarget:
          (map['protein_target'] as num?)?.toDouble() ??
          AppConstants.defaultProtein,
      carbohydrateTarget:
          (map['carbohydrate_target'] as num?)?.toDouble() ??
          AppConstants.defaultCarbs,
      fatTarget:
          (map['fat_target'] as num?)?.toDouble() ?? AppConstants.defaultFat,
      waterTarget:
          (map['water_target'] as num?)?.toDouble() ??
          AppConstants.defaultWater,
      gender: map['gender'] as String? ?? 'male',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
