class InputValidators {
  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? positiveNumber(
    String? value,
    String fieldName, {
    bool allowZero = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final num? parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number for $fieldName';
    }
    if (allowZero ? parsed < 0 : parsed <= 0) {
      return allowZero
          ? '$fieldName cannot be negative'
          : '$fieldName must be greater than 0';
    }
    return null;
  }

  static String? realisticMacro(String? value, String macroName) {
    final baseValidation = positiveNumber(value, macroName, allowZero: true);
    if (baseValidation != null) return baseValidation;

    final num parsed = double.parse(value!.trim());
    if (parsed > 100) {
      return '$macroName cannot exceed 100g per 100g';
    }
    return null;
  }

  static String? realisticCalories(String? value) {
    final baseValidation = positiveNumber(value, 'Calories', allowZero: true);
    if (baseValidation != null) return baseValidation;

    final num parsed = double.parse(value!.trim());
    if (parsed > 900) {
      return 'Calories cannot exceed 900 kcal per 100g (pure fat limit)';
    }
    return null;
  }

  static String? realisticWeight(String? value) {
    final baseValidation = positiveNumber(value, 'Weight', allowZero: false);
    if (baseValidation != null) return baseValidation;

    final num parsed = double.parse(value!.trim());
    if (parsed < 20 || parsed > 300) {
      return 'Enter a realistic weight between 20 and 300 kg';
    }
    return null;
  }

  static String? realisticHeight(String? value) {
    final baseValidation = positiveNumber(value, 'Height', allowZero: false);
    if (baseValidation != null) return baseValidation;

    final num parsed = double.parse(value!.trim());
    if (parsed < 50 || parsed > 260) {
      return 'Enter a realistic height between 50 and 260 cm';
    }
    return null;
  }

  static String? realisticAge(String? value) {
    if (value == null || value.trim().isEmpty) return null; // age is optional
    final int? parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 10 || parsed > 120) {
      return 'Enter a realistic age between 10 and 120';
    }
    return null;
  }
}
