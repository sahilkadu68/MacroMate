class WaterLog {
  final int? id;
  final String entryDate; // YYYY-MM-DD
  final double quantityMl;
  final DateTime createdAt;

  WaterLog({
    this.id,
    required this.entryDate,
    required this.quantityMl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entry_date': entryDate,
      'quantity_ml': quantityMl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WaterLog.fromMap(Map<String, dynamic> map) {
    return WaterLog(
      id: map['id'] as int?,
      entryDate: map['entry_date'] as String,
      quantityMl: (map['quantity_ml'] as num).toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}
