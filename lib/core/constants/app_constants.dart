class AppConstants {
  static const String appName = 'MacroMate India';
  static const String appTagline = 'Nutrition on a Student Budget';

  // Dietary preferences
  static const String dietVeg = 'Vegetarian';
  static const String dietEgg = 'Eggetarian';
  static const String dietNonVeg = 'Non-Vegetarian';
  static const List<String> dietaryPreferences = [dietVeg, dietEgg, dietNonVeg];

  // Meal types
  static const String mealBreakfast = 'Breakfast';
  static const String mealLunch = 'Lunch';
  static const String mealDinner = 'Dinner';
  static const String mealSnack = 'Snack';
  static const List<String> mealTypes = [
    mealBreakfast,
    mealLunch,
    mealDinner,
    mealSnack,
  ];

  // Activity levels
  static const String activitySedentary = 'Sedentary (little to no exercise)';
  static const String activityLight = 'Lightly Active (1-3 days/week)';
  static const String activityModerate = 'Moderately Active (3-5 days/week)';
  static const String activityVeryActive = 'Very Active (6-7 days/week)';
  static const String activityExtraActive =
      'Extra Active (intense workouts/labour)';
  static const List<String> activityLevels = [
    activitySedentary,
    activityLight,
    activityModerate,
    activityVeryActive,
    activityExtraActive,
  ];

  // Nutrition goals
  static const String goalMaintain = 'Maintain Weight';
  static const String goalLose = 'Lose Fat / Cut';
  static const String goalGain = 'Build Muscle / Bulk';
  static const List<String> nutritionGoals = [goalMaintain, goalLose, goalGain];

  // Food categories
  static const String catDairy = 'Dairy';
  static const String catEggsMeat = 'Eggs & Meat';
  static const String catPlantProtein = 'Plant Protein (Dal, Soy, Chana)';
  static const String catStaples = 'Staples (Rice, Roti, Oats)';
  static const String catNutsSeeds = 'Nuts & Seeds';
  static const String catVegetablesFruits = 'Vegetables & Fruits';
  static const String catOther = 'Other';
  static const List<String> foodCategories = [
    catDairy,
    catEggsMeat,
    catPlantProtein,
    catStaples,
    catNutsSeeds,
    catVegetablesFruits,
    catOther,
  ];

  // Measurement units
  static const String unitGrams = 'g';
  static const String unitMl = 'ml';
  static const String unitPiece = 'piece';

  // Preparation bases
  static const String prepRaw = 'Raw';
  static const String prepDry = 'Dry';
  static const String prepCooked = 'Cooked';
  static const String prepBoiled = 'Boiled';
  static const String prepRoasted = 'Roasted';
  static const List<String> prepBases = [
    prepRaw,
    prepDry,
    prepCooked,
    prepBoiled,
    prepRoasted,
  ];

  // Default goals for students
  static const double defaultDailyBudget = 150.0; // INR
  static const double defaultCalories = 2200.0; // kcal
  static const double defaultProtein = 100.0; // g
  static const double defaultCarbs = 275.0; // g
  static const double defaultFat = 60.0; // g
  static const double defaultWater = 3000.0; // ml
}
