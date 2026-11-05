# Data Dictionary

Current SQLite schema: version 3 (`lib/data/database/database_helper.dart`). Each local account uses a different SQLite database file; account 1 keeps the original `macromate_india.db` filename so existing user data is preserved. A separate local account database stores identifiers and password hashes; it does not contain nutrition logs.

| Table | Purpose and key fields | Data caveat |
|---|---|---|
| `user_profile` | One local profile: display name, age, height, weight, activity, goal, diet, daily budget, calorie/macros/water targets, gender, timestamps. | Targets are user settings or estimates; not medical prescriptions. |
| `foods` | Food catalogue, category/diet, macros per 100 base units, measurement unit and preparation basis, package price/quantity/unit, serving size, price source, last price update, estimate flag, source note, custom flag. | Seed rows have no row-level source citation and are unverified estimates. Legacy `last_price_update` is set to a catalog placeholder date for seed rows, not a measured-price observation date. Price basis and measurement basis must agree. No formal source ID, geography, confidence, or observation record yet. |
| `meal_entries` | Food reference plus immutable name/date/type/quantity/unit/preparation and calorie, macro, unit-price and cost snapshots. Food deletion sets `food_id` null. | Snapshot values preserve historic calculations but do not preserve a structured citation/version. |
| `water_logs` | Date, quantity in ml, created timestamp. | Local only. |
| `weight_logs` | Measurement date, weight, optional notes, timestamp. | Sensitive personal data stored unencrypted in local SQLite by application code. |
| `activity_logs` | Date, activity type, minutes, estimated calorie burn, notes. | Burn is an estimate; no sensor validation. |
| `recipes` | Name, description, servings and timestamps. | Recipe ownership is local; not shared or synced. |
| `recipe_ingredients` | Recipe/food references, ingredient name and quantity/unit, nutrient and cost snapshots. | Snapshot provenance is not structured; totals depend on current calculation assumptions. |
| `shopping_items` | Name, quantity, unit, purchased flag and created timestamp. | No normalized food reference or estimated unit/total cost. |
| `favorite_foods` | Unique local food ID and created timestamp. | Food deletion cascades favorite deletion. |

## Calculation units

- Food composition values are stored per 100 g or 100 ml (piece entries require the matching piece quantity basis).
- `quantity` uses the food's `measurement_unit`; nutrient amount = per-100 value × quantity / 100.
- `package_price` is INR for `package_quantity` in `purchase_unit`; cost = package price × logged quantity / package quantity when quantity bases match.
- `meal_entries.unit_price_snapshot` stores the food's package price field (legacy field name); `cost_snapshot` stores calculated cost for the logged quantity.
- Nutrition, cost and protein-per-rupee are arithmetic estimates, not laboratory or medical measurements.

## Migration notes

`onCreate` creates all tables and indexes and seeds one profile plus foods. v1→v2 creates recipes, ingredients, shopping and favorite tables. v2→v3 adds food packaging/provenance columns and reseeds built-in foods while retaining `is_custom = 1` rows. Existing meal logs are not recreated; foreign keys set deleted food IDs to null. Test migration on copies of real v1/v2 databases before a further schema change.
