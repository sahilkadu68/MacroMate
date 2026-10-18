class ActivityLog {
  final int? id;
  final String activityDate; // YYYY-MM-DD
  final String
  activityType; // Walking, Gym/Weightlifting, Running, Yoga, Cycling, Sports
  final int durationMinutes;
  final double estimatedCalories;
  final String? notes;
  final DateTime createdAt;

  ActivityLog({
    this.id,
    required this.activityDate,
    required this.activityType,
    required this.durationMinutes,
    required this.estimatedCalories,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activity_date': activityDate,
      'activity_type': activityType,
      'duration_minutes': durationMinutes,
      'estimated_calories': estimatedCalories,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] as int?,
      activityDate: map['activity_date'] as String,
      activityType: map['activity_type'] as String,
      durationMinutes: map['duration_minutes'] as int,
      estimatedCalories: (map['estimated_calories'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}
