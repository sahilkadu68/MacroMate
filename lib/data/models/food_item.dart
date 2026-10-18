import '../../core/constants/app_constants.dart';

class FoodItem {
  final int? id;
  final String name;
  final String category;
  final String dietaryClassification;
  final double caloriesPer100;
  final double proteinPer100;
  final double carbsPer100;
  final double fatPer100;
  final String measurementUnit; // g, ml, piece
  final String preparationBasis; // Raw, Dry, Cooked, Boiled, Roasted
  final double estimatedUnitPrice; // In INR (e.g. ₹50)
  final double priceQuantityBasis; // In unit (e.g. 1000g, 100g, 1 piece)
  final String sourceNote;
  final bool isCustom;
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodItem({
    this.id,
    required this.name,
    required this.category,
    required this.dietaryClassification,
    required this.caloriesPer100,
    required this.proteinPer100,
    required this.carbsPer100,
    required this.fatPer100,
    this.measurementUnit = AppConstants.unitGrams,
    this.preparationBasis = AppConstants.prepCooked,
    required this.estimatedUnitPrice,
    this.priceQuantityBasis = 100.0,
    this.sourceNote = 'Sample reference estimate',
    this.isCustom = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Estimated cost for 100g / 100ml / 100 pieces
  double get costPer100 {
    if (priceQuantityBasis <= 0 || estimatedUnitPrice <= 0) return 0.0;
    return (estimatedUnitPrice / priceQuantityBasis) * 100.0;
  }

  /// Grams of protein obtained per rupee spent
  /// Returns null if cost is zero, negative, or invalid to prevent division by zero
  double? get proteinPerRupee {
    final c100 = costPer100;
    if (c100 <= 0 || proteinPer100 <= 0) return null;
    return proteinPer100 / c100;
  }

  /// Calculates nutritional values and cost for a given serving quantity
  double costForQuantity(double quantity) {
    if (priceQuantityBasis <= 0 || estimatedUnitPrice <= 0 || quantity <= 0) {
      return 0.0;
    }
    return (estimatedUnitPrice / priceQuantityBasis) * quantity;
  }

  double caloriesForQuantity(double quantity) {
    if (quantity <= 0) return 0.0;
    return (caloriesPer100 * quantity) / 100.0;
  }

  double proteinForQuantity(double quantity) {
    if (quantity <= 0) return 0.0;
    return (proteinPer100 * quantity) / 100.0;
  }

  double carbsForQuantity(double quantity) {
    if (quantity <= 0) return 0.0;
    return (carbsPer100 * quantity) / 100.0;
  }

  double fatForQuantity(double quantity) {
    if (quantity <= 0) return 0.0;
    return (fatPer100 * quantity) / 100.0;
  }

  FoodItem copyWith({
    int? id,
    String? name,
    String? category,
    String? dietaryClassification,
    double? caloriesPer100,
    double? proteinPer100,
    double? carbsPer100,
    double? fatPer100,
    String? measurementUnit,
    String? preparationBasis,
    double? estimatedUnitPrice,
    double? priceQuantityBasis,
    String? sourceNote,
    bool? isCustom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      dietaryClassification:
          dietaryClassification ?? this.dietaryClassification,
      caloriesPer100: caloriesPer100 ?? this.caloriesPer100,
      proteinPer100: proteinPer100 ?? this.proteinPer100,
      carbsPer100: carbsPer100 ?? this.carbsPer100,
      fatPer100: fatPer100 ?? this.fatPer100,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      preparationBasis: preparationBasis ?? this.preparationBasis,
      estimatedUnitPrice: estimatedUnitPrice ?? this.estimatedUnitPrice,
      priceQuantityBasis: priceQuantityBasis ?? this.priceQuantityBasis,
      sourceNote: sourceNote ?? this.sourceNote,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'dietary_classification': dietaryClassification,
      'calories_per_100': caloriesPer100,
      'protein_per_100': proteinPer100,
      'carbs_per_100': carbsPer100,
      'fat_per_100': fatPer100,
      'measurement_unit': measurementUnit,
      'preparation_basis': preparationBasis,
      'estimated_unit_price': estimatedUnitPrice,
      'price_quantity_basis': priceQuantityBasis,
      'source_note': sourceNote,
      'is_custom': isCustom ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      dietaryClassification: map['dietary_classification'] as String,
      caloriesPer100: (map['calories_per_100'] as num).toDouble(),
      proteinPer100: (map['protein_per_100'] as num).toDouble(),
      carbsPer100: (map['carbs_per_100'] as num).toDouble(),
      fatPer100: (map['fat_per_100'] as num).toDouble(),
      measurementUnit:
          map['measurement_unit'] as String? ?? AppConstants.unitGrams,
      preparationBasis:
          map['preparation_basis'] as String? ?? AppConstants.prepCooked,
      estimatedUnitPrice: (map['estimated_unit_price'] as num).toDouble(),
      priceQuantityBasis:
          (map['price_quantity_basis'] as num?)?.toDouble() ?? 100.0,
      sourceNote: map['source_note'] as String? ?? '',
      isCustom: (map['is_custom'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
