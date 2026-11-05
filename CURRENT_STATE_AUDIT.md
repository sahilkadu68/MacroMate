# MacroMate India — Current-State Audit

> Historical snapshot from 4 November 2026, before the local-account implementation. Supabase descriptions below are obsolete. Use `REQUIREMENTS_CHECKLIST.md` for the current authoritative status and verification evidence.

**Audit date:** 4 November 2026
**Method:** Read-only source, dependency, schema, migration, test, and documentation inspection. Tests and builds were not run during this audit.

## 1. Executive Summary

- MacroMate is a Flutter nutrition and food-budget planning prototype for Indian students and beginner fitness users. The active product includes meal logging, daily targets, food catalogue, protein suggestions, recipes, shopping list, water and body tracking, and progress charts.
- The app now has a Supabase email/password sign-in gate, registration, password-reset request, profile onboarding, and sign-out code. These paths require an externally configured Supabase project and have not been exercised against one in this audit.
- Supabase is used only for the onboarding profile. Foods, meals, targets, recipes, lists, favorites, water, weight, and activity remain in one local SQLite database per installation. They have no account ownership boundary and are not synchronized.
- The catalogue seeds 66 food records. Its nutrition and price values are explicitly labeled unverified estimates; row-level source citations and measured local price observations are absent.
- Recommendations are deterministic, bounded combinations with dietary, budget, optional calorie, and protein-coverage rules. They are heuristics, not a validated nutrition optimizer.
- The project has model/service/database/widget tests, but the current audit did not run them. Previous documentation reports successful checks, but those documents contain stale and conflicting auth status statements.
- The repository has Android and web project configuration. Android release signing currently uses the debug key; no production deployment or store-ready signing setup is present.
- There is no implemented AI feature, notification/reminder system, subscription entitlement, payment flow, analytics integration, export, or account-deletion workflow.

## 2. Feature Inventory

| Feature | Status | Data source/storage | Limits |
|---|---|---|---|
| Startup and account gate | Implemented, configuration-dependent | Supabase Auth session | Without URL and publishable key, the app shows setup instructions and does not enter the tracker. Live session restoration was not tested here. |
| Registration/login/logout | Implemented, configuration-dependent | Supabase email/password Auth | Email confirmation behavior depends on project settings. No live provider, redirect, or email delivery verified. |
| Password reset | Partial | Supabase reset email request | Request UI exists; no in-app recovery callback/deep-link flow to set a new password was found. |
| First-time profile setup | Implemented, configuration-dependent | Supabase `profiles` row | Stores name, diet, goal, daily budget. Existing local profile and targets are not populated from this row. |
| Home dashboard | Functional, local-only | SQLite meal snapshots, local profile, water logs | Daily calories/macros, cost, budget, meal section, water. No cloud sync or verified source quality. |
| Food catalogue/search/filters | Functional, local-only | SQLite seeded/custom foods and favorites | 66 bundled records; search, category/dietary filters, sorting, favorites, and food editing are present. User edits do not make seed provenance authoritative. |
| Meal logging | Functional, local-only | SQLite meal entries | Quantity-based totals and meal-type/date logging; entries preserve nutrient and cost snapshots. |
| Meal history/edit/repeat | Partial, local-only | SQLite snapshots | Dashboard supports date-based entries and meal actions; no separate history module or clearly verified one-tap repeat workflow was found. |
| Protein Finder | Functional, local-only | Local catalogue + recommendation service | Uses bounded combinations and preference constraints; output is heuristic and depends on estimates. |
| Recipes | Partial, local-only | SQLite recipe and ingredient tables | Recipe builder/detail flow exists. Recipe ingredients are locally stored; no sharing or provenance management. |
| Meal planning | Partial, local-only | Protein recommendations and local records | Plan tab groups finder, recipes, shopping list, and catalogue; no multi-day optimizer or persisted generated meal plan was established. |
| Shopping list | Functional, local-only | SQLite shopping items | Basic items and purchased state; no costed cart, vendor integration, or cross-device list. |
| Progress/analytics | Functional, local-only | SQLite meal, weight, activity, and water data | Charts and aggregates are local descriptive summaries; no event analytics service. |
| Profile and nutrition goals | Functional, local-only after onboarding | SQLite `user_profile` | Editable targets, dietary choice, and Mifflin-St Jeor estimate. The Supabase onboarding profile is separate and not synchronized into this local record. |
| Water/weight/activity tracking | Functional, local-only | SQLite tables | Manual entry. Activity calories are estimates; no device sensor integration. |
| Alerts/reminders | Missing | — | No notification package, scheduling code, or reminder flow found. |
| AI | Missing | — | No model/API integration or AI workflow found. Suggestions are deterministic. |
| Billing/premium | Planned only | — | Business document contains pricing hypotheses; no purchase SDK, entitlements, or transaction verification. |

## 3. Authentication & Supabase Status

**Implemented in source:** `main.dart` reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` Dart defines and initializes Supabase when the URL is HTTPS and the key is nonempty. `AuthGate` waits for auth state, routes signed-out users to the auth form, checks the remote onboarding flag, and routes incomplete profiles to onboarding. The form supports sign-in, registration, password confirmation, and password-reset email request. Profile screen has sign-out. The checked-in SQL migration creates `public.profiles`, enables RLS, grants authenticated access, and constrains select/insert/update/delete to `id = auth.uid()`.

**Configuration-dependent or unverified:** No project configuration file or credentials were found in the inspected project root/Supabase folder; values were not displayed. A real Supabase project, enabled email provider, confirmation/redirect settings, and email delivery configuration are required. This audit did not apply the migration, connect to a project, exercise signup/login/reset/logout, or verify policy behavior against a database. Confirmation UI handles the `session == null` signup case, but actual confirmation behavior depends on project settings.

**Not implemented:** Remote storage/policies for nutrition records, account-scoped local databases, data sync/import, profile synchronization to the local tracker, account deletion, and data export. Signing out changes the auth session, but another account on the same installation can still encounter the same SQLite records. Do not treat the app as multi-user private or cloud-synced.

## 4. Architecture & Data Flow

The project uses feature-oriented Flutter screens, Provider `ChangeNotifier` state, calculation/dietary/analytics services, repository wrappers, typed model classes, and a singleton `DatabaseHelper`. Startup initializes the platform SQLite factory, then the auth gate admits the main navigation and its providers. Main navigation has Home, Foods, Plan, Progress, and Profile tabs; meal logging is opened contextually from Home.

SQLite schema version is **3**. It stores a single local profile plus foods, meal entries, water, weight, activity, recipes/ingredients, shopping items, and favorites. Native platforms use sqflite; web uses `sqflite_common_ffi_web`, with an in-memory fallback that can lose data on reload/close. Supabase stores only the remote profile row. Repositories/providers do not take an authenticated user ID, so local records are not isolated across accounts.

The source separates UI, state, calculation, and persistence concerns, but dependency wiring remains direct: providers construct repositories and trigger loads, while screens also call Supabase directly. Error handling varies by flow. Auth/profile setup has user-facing busy/error messages; local provider/database error handling is less consistent.

## 5. Calculation & Food Data Audit

- **Food data:** 66 seeded `FoodItem` records. Nutrition fields are stored per 100 g/ml (or matching piece basis); package price and price quantity basis support estimated serving cost. Seed rows label both nutrition and prices as unverified starter estimates, with no row-level IFCT identifier/citation, price source record, observation location, or measured date.
- **Nutrient amount:** `per100 × quantity / 100`. Non-finite, zero, negative nutrient inputs or quantities return `0` in the calculation helper; this can make invalid input look like a valid zero result.
- **Serving cost:** `unitPrice / priceBasis × quantity`; invalid/non-positive inputs return `0`. Price basis and quantity units must match for the result to mean anything.
- **Protein efficiency:** `protein grams / rupees`, with `null` for non-positive or non-finite values. Daily totals sum stored snapshots; protein-per-rupee is total protein divided by total cost when both are positive.
- **Recommendations:** filter by dietary class and finite/nonnegative nutrients plus positive price/basis, consider a bounded candidate pool, enumerate up to three foods with discrete portions, enforce budget and optional calorie ceiling, and rank combinations meeting at least 80% of remaining protein target. No global optimality or nutritional validation is claimed. Included food IDs are prioritized into the candidate set; exclusions are filtered.
- **Profile targets:** Mifflin-St Jeor BMR estimate, activity multiplier for TDEE, goal adjustment, weight-based protein/fat and residual carbohydrate split, and water estimate. These are estimates and not individualized medical guidance.
- **Historical values:** meal rows retain food name, quantity, macros, unit-price and cost snapshots. They do not capture structured source/version provenance for the underlying values.
- **Validation:** the recommendation service rejects many invalid criteria and food values; nutrition primitives guard many arithmetic inputs. Validation is not universal across aggregation, profile calculations, models, and database write paths. No repository-wide proof was found for NaN/infinity, negative values, or unit mismatch at every boundary.

## 6. Technical Quality & Testing

**Tests present:** database persistence and CRUD, food/diet providers, meal logging widget behavior, nutrition arithmetic, recommendation constraints, and recipe/model serialization. Auth widget coverage checks the missing-configuration gate; there is no live Supabase integration or RLS test in the repository.

**Verification in this audit:** source and configuration inspection only. No tests, analyzer, or builds were run. Earlier `TESTING_AND_EVALUATION.md` claims 44 tests, analysis, web release, and Android APK builds passed, but that document also describes auth as unimplemented and includes prior checks. Those results are historical claims, not a current reproducible result from this audit.

**Notable technical issues:** Android release build config signs with debug signing; no iOS project is present in the checked-in file inventory. Web storage fallback is temporary. Local SQLite data is shared across authenticated identities. Auth profile and local tracker profiles can diverge. Reset completion, export/deletion, backend error recovery, and complete account-scoped data tests are absent. Existing docs conflict: README says no sign-in/backend while also documenting an auth scaffold; implementation/testing docs retain pre-auth status in places.

## 7. Business/Product Readiness

The intended value proposition is practical nutrition and cost comparison for Indian students/beginner fitness users, combining budget-aware food suggestions with tracking. This is more than a calorie counter in feature breadth, but its key differentiator depends on the accuracy and local relevance of currently unverified food and price data. No customer research or market validation is evidenced. Business documents correctly label prices and premium concepts as hypotheses. There is no production deployment, live analytics, payment, subscription, or operational support setup in the inspected project.

## 8. Top 10 Gaps or Risks

1. **Account privacy boundary:** authenticated users share installation-wide local nutrition records; account switching does not isolate data.
2. **No reliable food provenance:** the differentiating nutrition and cost comparisons use unverified estimates without per-row traceability.
3. **No durable multi-device data system:** only onboarding profile is remote; core records have no sync, backup, or conflict model.
4. **Profile split:** onboarding's remote preferences/budget are not loaded into or kept in sync with the local profile powering features.
5. **Auth lifecycle incomplete/unverified:** real provider setup, email confirmation, reset completion/deep links, and live session/policy behavior remain unverified.
6. **No account data export/deletion workflow:** users cannot review or remove all local and remote data through the app.
7. **Validation gaps at data boundaries:** model, aggregation, and persistence paths do not consistently reject invalid ranges, non-finite values, or unit mismatches.
8. **Web durability uncertainty:** in-memory fallback explicitly risks loss; SQLite web persistence behavior was not tested in this audit.
9. **Release readiness gap:** Android release signing uses the debug key; deployment and store configuration are not evidenced.
10. **Limited product evidence and monetization:** no documented user testing, analytics, payments, subscription entitlements, or validated willingness to pay.

## 9. Files Inspected

- Entry/auth/navigation: `lib/main.dart`, `lib/app.dart`, `lib/services/auth_service.dart`, `lib/features/auth/auth_gate.dart`, `lib/features/auth/auth_screen.dart`, `lib/features/auth/onboarding_screen.dart`, `lib/features/navigation/main_scaffold.dart`.
- Feature screens: dashboard, food catalogue/detail/edit, meal logging, Protein Finder, planning hub, recipe builder/detail, shopping list, progress, profile, and tracking widgets under `lib/features/`.
- Data/calculations: `lib/data/database/database_helper.dart`, `lib/data/database/database_factory_helper.dart`, `lib/data/seed/indian_foods_seed.dart`, models and repositories under `lib/data/`, providers under `lib/providers/`, and nutrition/recommendation/dietary/analytics services under `lib/services/`.
- Backend: `supabase/migrations/202610280001_profiles.sql`, `supabase/README.md`.
- Tests: `test/widget_test.dart`, `test/widget/log_meal_screen_test.dart`, database tests, and unit tests under `test/unit/`.
- Configuration/docs: `pubspec.yaml`, Android Gradle files, web entry files, `README.md`, `ARCHITECTURE.md`, `DATA_DICTIONARY.md`, `SECURITY_AND_PRIVACY.md`, `IMPLEMENTATION_STATUS.md`, `TESTING_AND_EVALUATION.md`, `PRODUCT_REQUIREMENTS.md`, `RESEARCH_AND_DATA_SOURCES.md`, and `BUSINESS_MODEL.md`.

## 10. Unverified Claims

- No Supabase project connection, applied migration, account flow, email delivery, session restoration, or live RLS result was verified.
- No tests, static analysis, or release build were run for this audit. Previously recorded test/build outcomes were not reproduced.
- No manual visual check, device/emulator check, web persistence reload check, or deployment check was performed.
- Nutrition/price correctness, local market representativeness, user usefulness, health outcomes, business demand, and revenue potential are not established by the source code.
- Android/web are represented in the checked-in project structure; support/build behavior for other platforms was not verified.
