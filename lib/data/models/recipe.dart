import '../models/food_item.dart';

class RecipeIngredient {
  final int? id;
  final int? recipeId;
  final int? foodId;
  final String foodName;
  final double quantity; // in measurementUnit
  final String measurementUnit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double cost;

  RecipeIngredient({
    this.id,
    this.recipeId,
    this.foodId,
    required this.foodName,
    required this.quantity,
    this.measurementUnit = 'g',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.cost,
  });

  factory RecipeIngredient.fromFood({
    required FoodItem food,
    required double quantity,
  }) {
    return RecipeIngredient(
      foodId: food.id,
      foodName: food.name,
      quantity: quantity,
      measurementUnit: food.measurementUnit,
      calories: food.caloriesForQuantity(quantity),
      protein: food.proteinForQuantity(quantity),
      carbs: food.carbsForQuantity(quantity),
      fat: food.fatForQuantity(quantity),
      cost: food.costForQuantity(quantity),
    );
  }

  Map<String, dynamic> toMap(int recipeId) {
    return {
      if (id != null) 'id': id,
      'recipe_id': recipeId,
      'food_id': foodId,
      'food_name_snapshot': foodName,
      'quantity': quantity,
      'measurement_unit': measurementUnit,
      'calories_snapshot': calories,
      'protein_snapshot': protein,
      'carbs_snapshot': carbs,
      'fat_snapshot': fat,
      'cost_snapshot': cost,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      id: map['id'] as int?,
      recipeId: map['recipe_id'] as int?,
      foodId: map['food_id'] as int?,
      foodName: map['food_name_snapshot'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      measurementUnit: map['measurement_unit'] as String? ?? 'g',
      calories: (map['calories_snapshot'] as num).toDouble(),
      protein: (map['protein_snapshot'] as num).toDouble(),
      carbs: (map['carbs_snapshot'] as num).toDouble(),
      fat: (map['fat_snapshot'] as num).toDouble(),
      cost: (map['cost_snapshot'] as num).toDouble(),
    );
  }
}

class Recipe {
  final int? id;
  final String name;
  final String description;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final DateTime createdAt;
  final DateTime updatedAt;

  Recipe({
    this.id,
    required this.name,
    this.description = '',
    this.servings = 1,
    this.ingredients = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  double get totalCalories =>
      ingredients.fold(0.0, (sum, i) => sum + i.calories);
  double get totalProtein => ingredients.fold(0.0, (sum, i) => sum + i.protein);
  double get totalCarbs => ingredients.fold(0.0, (sum, i) => sum + i.carbs);
  double get totalFat => ingredients.fold(0.0, (sum, i) => sum + i.fat);
  double get totalCost => ingredients.fold(0.0, (sum, i) => sum + i.cost);

  double get perServingCalories =>
      servings > 0 ? totalCalories / servings : totalCalories;
  double get perServingProtein =>
      servings > 0 ? totalProtein / servings : totalProtein;
  double get perServingCarbs =>
      servings > 0 ? totalCarbs / servings : totalCarbs;
  double get perServingFat => servings > 0 ? totalFat / servings : totalFat;
  double get perServingCost => servings > 0 ? totalCost / servings : totalCost;

  double? get proteinPerRupee =>
      totalCost > 0 ? totalProtein / totalCost : null;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'servings': servings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Recipe.fromMap(
    Map<String, dynamic> map, {
    List<RecipeIngredient> ingredients = const [],
  }) {
    return Recipe(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      servings: map['servings'] as int? ?? 1,
      ingredients: ingredients,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Recipe copyWith({
    int? id,
    String? name,
    String? description,
    int? servings,
    List<RecipeIngredient>? ingredients,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      servings: servings ?? this.servings,
      ingredients: ingredients ?? this.ingredients,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
