class ShoppingItem {
  final int? id;
  final String name;
  final double quantity;
  final String unit;
  final bool isPurchased;
  final DateTime createdAt;

  ShoppingItem({
    this.id,
    required this.name,
    required this.quantity,
    this.unit = 'g',
    this.isPurchased = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'is_purchased': isPurchased ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'g',
      isPurchased: (map['is_purchased'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ShoppingItem copyWith({
    int? id,
    String? name,
    double? quantity,
    String? unit,
    bool? isPurchased,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isPurchased: isPurchased ?? this.isPurchased,
      createdAt: createdAt,
    );
  }
}
