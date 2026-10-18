# MacroMate India — Nutrition on a Student Budget

A complete, offline-first mobile and cross-platform nutrition application designed specifically for Indian college students and fitness enthusiasts living on tight budgets. MacroMate India combines meal logging with cost-per-gram protein optimization, scientific energy expenditure calculations, and progress analytics.

---

## 🌟 Key Features

### 1. 🏠 Daily Nutrition & Budget Dashboard (Home)
- **Real-Time Macro Rings & Progress**: Live tracking of calories, protein, carbohydrates, and fats against personalized targets.
- **Dynamic Student Budget Meter**: Tracks daily food expenditure in Indian Rupees (₹), warning when the daily budget limit is approached or exceeded.
- **Chronological Meal Diary**: Meal entries neatly categorized into **Breakfast**, **Lunch**, **Dinner**, and **Snack**.
- **Protein-Per-Rupee Spotlight**: Highlights the most economical protein source consumed each day.
- **Quick Logging Actions**: Direct access to meal logging, rapid water incrementation, and weight tracking.

### 2. 🍲 Indian Food Catalogue (53+ Pre-Seeded Items)
- **Local Indian Staples**: Accurate nutritional profiles for paneer, soya chunks, boiled eggs, dal tadka, hung curd, sattu, roasted chana, rajma, oats, chicken breast, fish, and more.
- **Raw vs. Cooked Distinction**: Clarifies nutritional shifts (e.g., raw lentils vs. water-expanded cooked dal; raw soya chunks vs. cooked soya).
- **Protein Efficiency Ranking ($g/₹$)**: Ranks every food item by how many grams of protein it delivers per Indian Rupee spent.
- **Search & Multi-Filter**: Filter by category (*Dairy*, *Plant Protein*, *Eggs & Meat*, *Staples*, *Nuts & Seeds*, *Vegetables & Fruits*, *Other*) and dietary classification (*Vegetarian*, *Eggetarian*, *Non-Vegetarian*).
- **Custom Food Creator**: Add homemade hostel meals or local kirana items with automatic real-time protein efficiency calculation.

### 3. ⚡ Protein Finder (Recommendation Engine)
- **Bounded Optimization Knapsack Algorithm**: Computes the optimal combination of 1, 2, or 3 food items that hits remaining protein needs without exceeding remaining daily budget.
- **Multi-Criteria Ranking**: Scores candidate plans based on protein target proximity, total cost minimization, and average protein efficiency.
- **Calorie Ceiling Support**: Optional constraint to ensure recommendations fit within remaining caloric budget.
- **Graceful Infeasibility Handling**: When budget is too tight to hit target protein, the engine delivers the highest possible protein outcome within budget and clearly explains the deficit.
- **One-Click Diary Addition**: Instantly logs all recommended items into today's meal diary as an atomic batch.

### 4. 📈 Health Tracking & Analytics (Progress)
- **Interactive Trend Charts (`fl_chart`)**: 7-day and 30-day views for daily calorie consumption, protein intake, and expenditure against user targets.
- **Weight History**: Chronological log of weigh-ins with milestone notes and automatic trend analysis.
- **Physical Activity Logger**: Logs workouts (gym, running, walking, sports) and calculates estimated calorie burn.
- **Hydration Tracker**: Daily water intake monitoring against scientific body-weight hydration goals.

### 5. 👤 Profile & Scientific Energy Estimator (Profile)
- **Mifflin–St Jeor BMR Calculator**: Clinically recognized formula tailored to sex, age, height, and weight.
- **TDEE & Fitness Objectives**: Automatically scales maintenance calories, fat-loss cut (-20%), or muscle-building bulk (+15%) using activity multipliers.
- **Editable Student Targets**: Override daily budget (default: ₹150/day), macro targets, and water targets at any time.

---

## 📐 Mathematical Formulas & Business Logic

### 1. Serving Nutrient Scaling
Nutrient values are stored per 100g/ml base:
$$\text{Nutrient}_{\text{serving}} = \frac{\text{Nutrient}_{\text{per 100}}}{100} \times \text{Quantity}$$

### 2. Serving Cost Calculation (INR)
$$\text{Cost}_{\text{serving}} = \frac{\text{Estimated Unit Price}}{\text{Price Quantity Basis}} \times \text{Quantity}$$

### 3. Protein Efficiency Metric ($P/C$)
Measures protein yield per rupee spent:
$$\text{Cost}_{\text{per 100}} = \frac{\text{Estimated Unit Price}}{\text{Price Quantity Basis}} \times 100$$
$$\text{Protein Per Rupee} = \frac{\text{Protein}_{\text{per 100}}}{\text{Cost}_{\text{per 100}}} \quad (\text{grams of protein per } ₹1)$$
*Zero-division safeguard: If unit price or cost is zero, efficiency returns `null` or `0.0`.*

### 4. Mifflin–St Jeor Energy Expenditure
$$\text{BMR}_{\text{male}} = 10 \times \text{weight (kg)} + 6.25 \times \text{height (cm)} - 5 \times \text{age (yr)} + 5$$
$$\text{BMR}_{\text{female}} = 10 \times \text{weight (kg)} + 6.25 \times \text{height (cm)} - 5 \times \text{age (yr)} - 161$$

$$\text{TDEE} = \text{BMR} \times \text{Activity Multiplier}$$
- *Sedentary*: $1.2$
- *Lightly Active*: $1.375$
- *Moderately Active*: $1.55$
- *Very Active*: $1.725$
- *Extra Active*: $1.9$

### 5. Objective Fitness Function (Protein Finder)
For candidate plan $x$ with items $\{i_1, \dots, i_k\}$:
$$\text{Fit}(x) = 100 \times \min\left(\frac{P_{\text{total}}}{P_{\text{target}}}, 1.0\right) + 20 \times \left(1.0 - \frac{C_{\text{total}}}{B_{\text{remaining}}}\right) + 10 \times \text{Eff}_{\text{avg}}$$
Subject to:
$$C_{\text{total}} \le B_{\text{remaining}}$$
$$\text{Cal}_{\text{total}} \le \text{Cal}_{\text{max}} \quad (\text{if specified})$$

### 6. Historical Snapshot Immutability
When a meal is logged, exact calories, protein, carbs, fat, unit price, and cost are snapshotted into `meal_entries`. If food prices inflate or a food's recipe is modified later, past meal entries remain 100% frozen and reflect true historical data.

---

## 🏗️ Architecture & Codebase Structure

```
lib/
├── core/
│   ├── constants/       # AppConstants (slots, goals, categories, defaults)
│   ├── theme/           # AppTheme, AppColors (Material 3 Emerald/Amber)
│   ├── utils/           # Formatters (INR currency, macros, dates)
│   └── validators/      # InputValidators (numbers, realistic limits)
├── data/
│   ├── database/        # DatabaseHelper (SQLite tables, indexes, seeding)
│   │                    # DatabaseFactoryHelper (Web/Desktop/Mobile abstraction)
│   ├── models/          # UserProfile, FoodItem, MealEntry, Tracking models
│   ├── repositories/    # Profile, Food, Meal, Tracking Repositories
│   └── seed/            # IndianFoodsSeed (53 verified Indian staples)
├── features/
│   ├── dashboard/       # DashboardScreen & metric cards
│   ├── foods/           # FoodCatalogueScreen, AddEditFoodScreen, detail sheet
│   ├── meal_logging/    # LogMealScreen (live macro & cost preview)
│   ├── navigation/      # MainScaffold (Material 3 navigation bar)
│   ├── profile/         # ProfileScreen & MifflinCalculatorDialog
│   ├── progress/        # ProgressScreen & fl_chart cards
│   └── protein_finder/  # ProteinFinderScreen & RecommendationCard
├── providers/           # ProfileProvider, FoodProvider, MealProvider, TrackingProvider, ProteinFinderProvider
├── services/            # NutritionService, RecommendationService, AnalyticsService
├── shared/              # Reusable badges, dialogs, empty state views
├── app.dart             # Root MultiProvider & MaterialApp
└── main.dart            # App entrypoint & pre-warmed SQLite
```

---

## 🧪 Testing & Quality Assurance

The codebase includes comprehensive unit, widget, and database integration tests.

### Running Tests
```bash
flutter test
```

### Running Static Analysis & Linter
```bash
flutter analyze
```

### Running Dart Code Formatter
```bash
dart format --set-exit-if-changed .
```

### Verified Test Suite:
- `test/unit/nutrition_service_test.dart`: 7 tests passing (scaling, cost math, zero-division protection, Mifflin–St Jeor, TDEE).
- `test/unit/recommendation_service_test.dart`: 4 tests passing (dietary filters, budget knapsack constraints, calorie ceiling, infeasible fallback notes).
- `test/database/database_test.dart`: 7 tests passing (SQLite schema, 50+ item seed, CRUD, historical snapshot immutability, water/weight/activity logs).
- `test/widget_test.dart`: End-to-end navigation test across all 5 destinations.

---

## 🌐 Running on Chrome / Web

The application features full web support with persistent IndexedDB SQLite storage via `sqflite_common_ffi_web`.

```bash
flutter run -d chrome
```
Or build the production web bundle:
```bash
flutter build web
```

---

## 📱 Future Android Setup & Deployment Guide

When ready to test or deploy on an Android emulator or a physical phone, follow these steps:

### Step 1: Install Android Studio & Android SDK
1. Download and install **[Android Studio](https://developer.android.com/studio)**.
2. Open Android Studio and complete the Setup Wizard:
   - Select **Standard** install type.
   - Ensure **Android SDK**, **Android SDK Platform-Tools**, and **Android SDK Build-Tools** are checked.
3. Open **SDK Manager** (*Settings > Languages & Frameworks > Android SDK*):
   - In the **SDK Platforms** tab, install **Android 14.0 (API 34)** or **Android 15 (API 35)**.
   - In the **SDK Tools** tab, verify **Android SDK Command-line Tools (latest)** and **Android Emulator** are installed.

### Step 2: Configure Environment Variables (Windows)
Add the following to your System Environment Variables:
- `ANDROID_HOME`: `C:\Users\<YourUsername>\AppData\Local\Android\Sdk`
- Add to `PATH`:
  - `%ANDROID_HOME%\platform-tools`
  - `%ANDROID_HOME%\cmdline-tools\latest\bin`
  - `%ANDROID_HOME%\emulator`

### Step 3: Accept Android Licenses
In PowerShell / Command Prompt, run:
```powershell
flutter doctor --android-licenses
```
Press `y` to accept each license.

### Step 4: Verify with Flutter Doctor
Run:
```powershell
flutter doctor
```
Ensure `[√] Android toolchain` shows all checkmarks.

### Step 5: Run on an Android Emulator
1. Open Android Studio > **Virtual Device Manager** (Device Manager).
2. Click **Create Device** > Select **Pixel 8** or **Pixel 7**.
3. Download a system image (e.g., **API 34 - UpsideDownCake - x86_64**).
4. Launch the emulator, then run:
   ```powershell
   flutter run
   ```

### Step 6: Deploy to a Physical Android Phone
1. **Enable Developer Options on Phone**:
   - Go to *Settings > About Phone*.
   - Tap **Build Number** 7 times until you see *"You are now a developer!"*.
2. **Enable USB Debugging**:
   - Go to *Settings > System > Developer Options*.
   - Toggle **USB Debugging** to ON.
3. **Connect Device via USB**:
   - Plug phone into PC.
   - On the phone, accept the prompt: *"Allow USB debugging from this computer"*.
4. **Verify Detection**:
   ```powershell
   flutter devices
   ```
   Your phone model will appear in the device list.
5. **Install & Run**:
   ```powershell
   flutter run -d <your-phone-id>
   ```

### Step 7: Build Standalone Release APK
To build an APK for direct installation without an IDE:
```powershell
flutter build apk --release
```
The output file is generated at:
`build\app\outputs\flutter-apk\app-release.apk`
Copy this APK to your phone via USB or WhatsApp/Drive and tap to install!

---

## 🔒 Privacy & Local-First Guarantee

- **No Cloud Accounts**: MacroMate India requires no account creation, no Google Sign-In, and no external tracking.
- **Zero API Telemetry**: All nutrition calculations and recommendations run 100% on-device.
- **Persistent Local Database**: All meal logs, custom food items, personal weights, and goals remain stored securely in your local device's SQLite database.