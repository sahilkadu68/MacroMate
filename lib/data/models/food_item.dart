import '../../core/constants/app_constants.dart';

class FoodItem {
  final int? id;
  final String name;
  final String? brand;
  final String category;
  final String dietaryClassification;
  final double caloriesPer100;
  final double proteinPer100;
  final double carbsPer100;
  final double fatPer100;
  final String measurementUnit; // g, ml, piece
  final String preparationBasis; // Raw, Dry, Cooked, Boiled, Roasted

  // Pricing & packaging model
  final String purchaseUnit; // 'kg', 'litre', 'dozen', 'pack', 'piece'
  final double
  packageQuantity; // Quantity/weight per package in measurementUnit (e.g. 1000 for kg, 12 for dozen, 1 for piece)
  final double packagePrice; // Purchase price of package in INR
  final double
  servingSize; // Standard serving in measurementUnit (e.g. 100g, 50g, 1 piece)
  final String
  priceSource; // e.g. 'Blinkit / Zepto / Local Mandi Estimate (2024-2026)', 'ICMR Reference'
  final DateTime lastPriceUpdate;
  final bool
  isPriceEstimate; // true = estimated retail, false = verified live price

  final String sourceNote;
  final bool isCustom;
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodItem({
    this.id,
    required this.name,
    this.brand,
    required this.category,
    required this.dietaryClassification,
    required this.caloriesPer100,
    required this.proteinPer100,
    required this.carbsPer100,
    required this.fatPer100,
    this.measurementUnit = AppConstants.unitGrams,
    this.preparationBasis = AppConstants.prepCooked,
    double? packagePrice,
    double? estimatedUnitPrice,
    double? packageQuantity,
    double? priceQuantityBasis,
    double? servingSize,
    String? purchaseUnit,
    String? priceSource,
    DateTime? lastPriceUpdate,
    this.isPriceEstimate = true,
    this.sourceNote = 'Sample reference estimate',
    this.isCustom = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : packagePrice = packagePrice ?? estimatedUnitPrice ?? 0.0,
       packageQuantity = packageQuantity ?? priceQuantityBasis ?? 100.0,
       servingSize = servingSize ?? 100.0,
       purchaseUnit =
           purchaseUnit ??
           (measurementUnit == AppConstants.unitMl
               ? 'litre'
               : measurementUnit == AppConstants.unitPiece
               ? 'piece'
               : 'kg'),
       priceSource =
           priceSource ??
           (sourceNote.isNotEmpty
               ? sourceNote
               : 'Estimated retail in India (2024-2026)'),
       lastPriceUpdate = lastPriceUpdate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Backwards-compatible alias for packagePrice
  double get estimatedUnitPrice => packagePrice;

  /// Backwards-compatible alias for packageQuantity
  double get priceQuantityBasis => packageQuantity;

  /// Estimated cost for 100g / 100ml / 100 pieces
  double get costPer100 {
    if (packageQuantity <= 0 || packagePrice <= 0) return 0.0;
    return (packagePrice / packageQuantity) * 100.0;
  }

  /// Estimated cost for one standard serving
  double get costPerServing => costForQuantity(servingSize);

  /// Calories for one standard serving
  double get caloriesPerServing => caloriesForQuantity(servingSize);

  /// Protein for one standard serving
  double get proteinPerServing => proteinForQuantity(servingSize);

  /// Carbohydrates for one standard serving
  double get carbsPerServing => carbsForQuantity(servingSize);

  /// Fat for one standard serving
  double get fatPerServing => fatForQuantity(servingSize);

  /// Grams of protein obtained per rupee spent.
  /// Defined as: Protein in grams per serving ÷ Cost per serving in rupees.
  /// Mathematically equivalent to: proteinPer100 ÷ costPer100.
  /// Returns null if cost is zero, negative, or invalid to prevent division by zero or false high rankings.
  double? get proteinPerRupee {
    final c100 = costPer100;
    if (c100 <= 0 || proteinPer100 <= 0) return null;
    return proteinPer100 / c100;
  }

  /// Calculates nutritional values and cost for a given serving quantity
  /// Cost = packagePrice * quantity / packageQuantity
  double costForQuantity(double quantity) {
    if (packageQuantity <= 0 || packagePrice <= 0 || quantity <= 0) {
      return 0.0;
    }
    return (packagePrice / packageQuantity) * quantity;
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
    String? brand,
    String? category,
    String? dietaryClassification,
    double? caloriesPer100,
    double? proteinPer100,
    double? carbsPer100,
    double? fatPer100,
    String? measurementUnit,
    String? preparationBasis,
    double? packagePrice,
    double? estimatedUnitPrice,
    double? packageQuantity,
    double? priceQuantityBasis,
    double? servingSize,
    String? purchaseUnit,
    String? priceSource,
    DateTime? lastPriceUpdate,
    bool? isPriceEstimate,
    String? sourceNote,
    bool? isCustom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      dietaryClassification:
          dietaryClassification ?? this.dietaryClassification,
      caloriesPer100: caloriesPer100 ?? this.caloriesPer100,
      proteinPer100: proteinPer100 ?? this.proteinPer100,
      carbsPer100: carbsPer100 ?? this.carbsPer100,
      fatPer100: fatPer100 ?? this.fatPer100,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      preparationBasis: preparationBasis ?? this.preparationBasis,
      packagePrice: packagePrice ?? estimatedUnitPrice ?? this.packagePrice,
      packageQuantity:
          packageQuantity ?? priceQuantityBasis ?? this.packageQuantity,
      servingSize: servingSize ?? this.servingSize,
      purchaseUnit: purchaseUnit ?? this.purchaseUnit,
      priceSource: priceSource ?? this.priceSource,
      lastPriceUpdate: lastPriceUpdate ?? this.lastPriceUpdate,
      isPriceEstimate: isPriceEstimate ?? this.isPriceEstimate,
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
      'brand': brand,
      'category': category,
      'dietary_classification': dietaryClassification,
      'calories_per_100': caloriesPer100,
      'protein_per_100': proteinPer100,
      'carbs_per_100': carbsPer100,
      'fat_per_100': fatPer100,
      'measurement_unit': measurementUnit,
      'preparation_basis': preparationBasis,
      'estimated_unit_price': packagePrice,
      'price_quantity_basis': packageQuantity,
      'purchase_unit': purchaseUnit,
      'package_quantity': packageQuantity,
      'package_price': packagePrice,
      'serving_size': servingSize,
      'price_source': priceSource,
      'last_price_update': lastPriceUpdate.toIso8601String(),
      'is_price_estimate': isPriceEstimate ? 1 : 0,
      'source_note': sourceNote,
      'is_custom': isCustom ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    final price =
        ((map['package_price'] ?? map['estimated_unit_price']) as num?)
            ?.toDouble() ??
        0.0;
    final qty =
        ((map['package_quantity'] ?? map['price_quantity_basis']) as num?)
            ?.toDouble() ??
        100.0;
    final unit = map['measurement_unit'] as String? ?? AppConstants.unitGrams;

    return FoodItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      category: map['category'] as String,
      dietaryClassification: map['dietary_classification'] as String,
      caloriesPer100: (map['calories_per_100'] as num).toDouble(),
      proteinPer100: (map['protein_per_100'] as num).toDouble(),
      carbsPer100: (map['carbs_per_100'] as num).toDouble(),
      fatPer100: (map['fat_per_100'] as num).toDouble(),
      measurementUnit: unit,
      preparationBasis:
          map['preparation_basis'] as String? ?? AppConstants.prepCooked,
      packagePrice: price,
      packageQuantity: qty,
      servingSize: (map['serving_size'] as num?)?.toDouble() ?? 100.0,
      purchaseUnit:
          map['purchase_unit'] as String? ??
          (unit == AppConstants.unitMl
              ? 'litre'
              : unit == AppConstants.unitPiece
              ? 'piece'
              : 'kg'),
      priceSource:
          map['price_source'] as String? ??
          map['source_note'] as String? ??
          'Estimated retail in India (2024-2026)',
      lastPriceUpdate: map['last_price_update'] != null
          ? DateTime.tryParse(map['last_price_update'] as String) ??
                DateTime.now()
          : DateTime.now(),
      isPriceEstimate:
          map['is_price_estimate'] == null ||
          (map['is_price_estimate'] as int) == 1,
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
