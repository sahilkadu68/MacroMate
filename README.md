# MacroMate India

MacroMate is an offline-first Flutter prototype for Indian students and beginner fitness users who want to compare food choices against self-set nutrition goals and a food budget.

## Current capabilities

- Home dashboard with daily nutrition totals, budget estimate, meal diary, and water log.
- Searchable food catalogue with editable food records, preparation basis, and price inputs.
- Plan hub that groups affordable food combinations, recipe building, shopping list, and catalogue access.
- Meal logging with quantity-based nutrition and cost calculations; meal entries retain snapshots of values at the time they were logged.
- Local profile targets, weight/activity/water tracking, and progress charts.
- Deterministic, bounded food-combination suggestions with dietary, budget, and optional calorie constraints.
- Light theme by default; web and Android build targets.

## Data and limitations

The bundled food catalogue is starter data. Its macro and price values are **unverified estimates**: rows do not have individual IFCT table citations or price observations with location/date. Do not treat them as official ICMR-NIN values or current local market prices. Review food details and update prices before relying on a plan. See [RESEARCH_AND_DATA_SOURCES.md](RESEARCH_AND_DATA_SOURCES.md).

MacroMate uses device-local accounts. Passwords are stored as salted PBKDF2-HMAC-SHA256 hashes, and each account uses a separate SQLite database file. On an existing install, the first account created uses the existing database so local records are preserved. Accounts do not sync or back up online. On web, SQLite persistence is attempted; if initialization fails, the app switches to temporary in-memory storage and displays a warning. Data in that fallback can be lost when the tab reloads or closes.

Recommendation results use a bounded candidate pool, discrete serving steps, an 80% target-coverage threshold, and a heuristic score. They are planning suggestions, not medical advice or globally optimal plans. Nutrition targets are estimates that users can review and adjust.

## Run locally

```powershell
flutter pub get
flutter run -d chrome
```

No cloud account or network connection is required. Register a local account in the app, then complete profile setup to open the dashboard.

## Checks and builds

```powershell
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
flutter build apk --release
```

The test suite uses serial execution because current test files share a local SQLite database. Widget tests still emit SQLite lock-duration warnings; see [TESTING_AND_EVALUATION.md](TESTING_AND_EVALUATION.md) for current results and limitations.

## Project documents

- [Product requirements](PRODUCT_REQUIREMENTS.md)
- [Architecture](ARCHITECTURE.md)
- [Research and data sources](RESEARCH_AND_DATA_SOURCES.md)
- [Data dictionary](DATA_DICTIONARY.md)
- [Security and privacy](SECURITY_AND_PRIVACY.md)
- [Business model hypotheses](BUSINESS_MODEL.md)
- [Implementation status](IMPLEMENTATION_STATUS.md)
- [Testing and evaluation](TESTING_AND_EVALUATION.md)
