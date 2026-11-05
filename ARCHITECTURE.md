# Architecture

**Current architecture:** Flutter/Dart with Provider state, feature screens, services for calculations, repositories for persistence, and a singleton `DatabaseHelper`.

## Local account and storage flow

`main.dart` initializes the SQLite platform factory and starts `AuthGate`. `LocalAccountRepository` stores normalized email/username, PBKDF2-HMAC-SHA256 password hashes, onboarding state, and the active local session in a small local account database/preferences. The app does not contact an authentication server. Password recovery by email is not available.

Each local account opens a separate SQLite database file. Account 1 uses the original `macromate_india.db` path to preserve existing app data; later accounts use `macromate_india_account_<id>.db`. The first account created on an existing installation therefore claims the previous local profile and records. Account deletion removes that account's database after password confirmation. These are device-local boundaries, not protection against someone with access to the device or its app data. No sync, backup, or encryption of nutrition records is implemented.

The account gate routes new accounts to profile setup, then creates Provider instances for the active account's database. Signing out closes the active data connection and removes the saved session before showing the local login screen.

## Feature/data flow

- `features/` contains dashboard, foods, meal logging, plan hub, recipes, shopping list, progress, profile and auth/setup screens.
- `providers/` loads and mutates screen state through repositories.
- `services/` contains nutrition arithmetic, dietary eligibility, analytics and bounded food recommendations.
- `data/models/` contains typed records. `data/repositories/` wraps local persistence. `DatabaseHelper` owns SQLite schema, seed loading and CRUD.
- SQLite version 3 stores a local profile, foods, meal snapshots, water, weight, activity, recipes/ingredients, shopping items and favorites. The web fallback is in-memory and temporary.

Meal entries snapshot names, quantities, macros and cost at log time. This protects historical totals from later catalogue edits.

## Recommendations

`RecommendationService` filters by dietary preference and valid positive prices, builds a bounded candidate set, and enumerates food combinations with discrete serving steps. It enforces the budget and optional calorie ceiling and ranks combinations at/above 80% protein-target coverage; when none qualify, it returns partial options. Candidate bounds and rank weights are heuristics, not globally optimal planning or clinical nutrition advice.

## Known boundaries

Nutrition and price seed rows are unverified estimates without row-level citations/observations. Price editing is currently food-record based. No external analytics, notifications, AI, payments, export, or cloud synchronization exists. Provider constructors initiate loading, and UI/data dependency wiring is not fully isolated. Release Android signing must be configured before distribution; the checked-in build currently uses debug signing.
