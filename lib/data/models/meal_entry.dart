import '../../core/constants/app_constants.dart';
import 'food_item.dart';

class MealEntry {
  final int? id;
  final int? foodId; // Nullable if referenced food is deleted
  final String foodNameSnapshot;
  final DateTime entryDate;
  final String mealType; // Breakfast, Lunch, Dinner, Snack
  final double quantity; // in measurementUnit
  final String measurementUnit; // g, ml, piece
  final String preparationBasis; // Raw, Cooked, Boiled, etc.
  final double caloriesSnapshot;
  final double proteinSnapshot;
  final double carbsSnapshot;
  final double fatSnapshot;
  final double unitPriceSnapshot;
  final double costSnapshot;
  final DateTime createdAt;
  final DateTime updatedAt;

  MealEntry({
    this.id,
    this.foodId,
    required this.foodNameSnapshot,
    required this.entryDate,
    required this.mealType,
    required this.quantity,
    this.measurementUnit = AppConstants.unitGrams,
    this.preparationBasis = AppConstants.prepCooked,
    required this.caloriesSnapshot,
    required this.proteinSnapshot,
    required this.carbsSnapshot,
    required this.fatSnapshot,
    required this.unitPriceSnapshot,
    required this.costSnapshot,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Creates a MealEntry directly from a FoodItem and selected quantity
  factory MealEntry.fromFoodItem({
    required FoodItem food,
    required DateTime entryDate,
    required String mealType,
    required double quantity,
  }) {
    return MealEntry(
      foodId: food.id,
      foodNameSnapshot: food.name,
      entryDate: entryDate,
      mealType: mealType,
      quantity: quantity,
      measurementUnit: food.measurementUnit,
      preparationBasis: food.preparationBasis,
      caloriesSnapshot: food.caloriesForQuantity(quantity),
      proteinSnapshot: food.proteinForQuantity(quantity),
      carbsSnapshot: food.carbsForQuantity(quantity),
      fatSnapshot: food.fatForQuantity(quantity),
      unitPriceSnapshot: food.estimatedUnitPrice,
      costSnapshot: food.costForQuantity(quantity),
    );
  }

  /// Protein per rupee efficiency of this specific logged entry
  double? get proteinPerRupee {
    if (costSnapshot <= 0 || proteinSnapshot <= 0) return null;
    return proteinSnapshot / costSnapshot;
  }

  MealEntry copyWith({
    int? id,
    int? foodId,
    String? foodNameSnapshot,
    DateTime? entryDate,
    String? mealType,
    double? quantity,
    String? measurementUnit,
    String? preparationBasis,
    double? caloriesSnapshot,
    double? proteinSnapshot,
    double? carbsSnapshot,
    double? fatSnapshot,
    double? unitPriceSnapshot,
    double? costSnapshot,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealEntry(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      foodNameSnapshot: foodNameSnapshot ?? this.foodNameSnapshot,
      entryDate: entryDate ?? this.entryDate,
      mealType: mealType ?? this.mealType,
      quantity: quantity ?? this.quantity,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      preparationBasis: preparationBasis ?? this.preparationBasis,
      caloriesSnapshot: caloriesSnapshot ?? this.caloriesSnapshot,
      proteinSnapshot: proteinSnapshot ?? this.proteinSnapshot,
      carbsSnapshot: carbsSnapshot ?? this.carbsSnapshot,
      fatSnapshot: fatSnapshot ?? this.fatSnapshot,
      unitPriceSnapshot: unitPriceSnapshot ?? this.unitPriceSnapshot,
      costSnapshot: costSnapshot ?? this.costSnapshot,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'food_id': foodId,
      'food_name_snapshot': foodNameSnapshot,
      'entry_date': entryDate.toIso8601String(),
      'meal_type': mealType,
      'quantity': quantity,
      'measurement_unit': measurementUnit,
      'preparation_basis': preparationBasis,
      'calories_snapshot': caloriesSnapshot,
      'protein_snapshot': proteinSnapshot,
      'carbs_snapshot': carbsSnapshot,
      'fat_snapshot': fatSnapshot,
      'unit_price_snapshot': unitPriceSnapshot,
      'cost_snapshot': costSnapshot,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      id: map['id'] as int?,
      foodId: map['food_id'] as int?,
      foodNameSnapshot: map['food_name_snapshot'] as String,
      entryDate: DateTime.parse(map['entry_date'] as String),
      mealType: map['meal_type'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      measurementUnit:
          map['measurement_unit'] as String? ?? AppConstants.unitGrams,
      preparationBasis:
          map['preparation_basis'] as String? ?? AppConstants.prepCooked,
      caloriesSnapshot: (map['calories_snapshot'] as num).toDouble(),
      proteinSnapshot: (map['protein_snapshot'] as num).toDouble(),
      carbsSnapshot: (map['carbs_snapshot'] as num).toDouble(),
      fatSnapshot: (map['fat_snapshot'] as num).toDouble(),
      unitPriceSnapshot: (map['unit_price_snapshot'] as num).toDouble(),
      costSnapshot: (map['cost_snapshot'] as num).toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
