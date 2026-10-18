class WeightLog {
  final int? id;
  final String measurementDate; // YYYY-MM-DD
  final double weight; // kg
  final String? notes;
  final DateTime createdAt;

  WeightLog({
    this.id,
    required this.measurementDate,
    required this.weight,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'measurement_date': measurementDate,
      'weight': weight,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeightLog.fromMap(Map<String, dynamic> map) {
    return WeightLog(
      id: map['id'] as int?,
      measurementDate: map['measurement_date'] as String,
      weight: (map['weight'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}
