# MacroMate India requirements and evidence

Updated 5 November 2026. Authoritative tracker for the approved final development prompt and subsequent stabilization/continuous-development instructions.

Legend: [x] verified at the stated scope; [~] partial; [ ] pending; [!] blocked. Unit verification does not establish Android acceptance.

## 1. Core architecture and offline operation
- [x] Existing Flutter/Provider/SQLite architecture retained; dependency/source inspection confirms no required cloud service.
- [~] Offline persistence: database tests pass; airplane-mode/restart acceptance remains pending.

## 2. Local authentication and account isolation
- [x] Password hashing, registration, session storage, password changes, deletion and isolated files: `auth_service.dart`, `local_account_test.dart`; automated coverage passed in the 51-test baseline.
- [~] Provider trees now keyed by account ID in `auth_gate.dart`; full Android switching journey pending.

## 3. Food catalogue and nutrition data
- [~] Regional catalogue, search/cuisine/diet filters and provenance fields implemented. Food-provider tests pass; actual UI and regional coverage acceptance pending.
- [!] Seed composition is unverified. No row-level IFCT validation; do not represent numbers as measured data.

## 4. Mumbai ingredient prices and meal costing
- [~] Offline ingredient prices support package quantities and user edits; snapshots tested. Prices are estimates, not current Mumbai observations.
- [~] User-built recipes have structured ingredient quantities and summed costs (`recipe.dart`, recipe builder). Built-in prepared dishes still lack structured ingredient quantities and dynamic ingredient-derived pricing.
- [x] Saved recipe details and new recipe logs refresh ingredient values by stable food ID through `recipe_cost_service.dart`; focused test passed for current-price recalculation and unchanged saved values. Missing/deleted or unit-changed ingredients retain saved estimates; historical log records remain untouched.

## 5. Planner and nutrition calculations
- [x] Budget/diet/finite-input constraints tested in planner and nutrition services.
- [~] Daily 3–6 meal UI, persisted plans, totals and portion controls implemented; Android acceptance pending.
- [~] Ingredient exclusions added to generation and substitutions, with persisted comma-separated preferences; regression test added. Matching is textual and relies on incomplete ingredient descriptions, not an allergy guarantee.
- [ ] Ingredient availability/pantry constraints.

## 6. Meal logging and history
- [x] Historical nutrition and price snapshots verified by database tests.
- [~] Dedicated Logs navigation and planned-meal logging implemented; end-to-end/restart checks pending.

## 7. Adapt My Day and substitutions
- [x] Null-ID substitution bug fixed; cheaper nutrition-matched alternatives verified by service tests.
- [~] Adaptation preview with accept/reject implemented; actual UI verification pending.

## 8. Shopping list
- [x] Compatible-unit catalogue cost calculation and unknown-price handling: two `shopping_cost_service_test.dart` tests passed.
- [~] Quantity editor, estimated unchecked-item total and per-item prices implemented; persistence/UI verification pending.
- [~] Existing recipe-to-list expansion retains unit boundaries after fix. Daily plan still adds whole prepared dishes; structured expansion pending.
- [ ] Transactional plan-to-list insertion and retry/duplicate protection.

## 9. Progress and insights
- [~] Existing 7/30-day averages, protein target hits and charts inspected in progress screen. Uses logged-day averages; weekly plan comparison and consistency review pending.

## 10. UI/UX and accessibility
- [~] Existing Material styling retained; navigation includes Home, Foods, Plan, Logs, Progress, Profile. Log-screen narrow/wide widget tests pass.
- [ ] Actual review of new screens, large text, validation/error states and Android journey.

## 11. Testing, Android build and release
- [x] Baseline 51 tests passed before this batch; two shopping cost tests subsequently passed.
- [x] Full regression suite: 54 tests passed after shopping/exclusion/provider-key changes. Subsequent recipe-price test passed separately. Static analysis: no issues after recipe-price integration.
- [~] Prior APK exists, but is not the final artifact for current changes; final rebuild pending.
- [!] Android emulator launched but did not remain available in device discovery; investigate before manual acceptance.
- [~] Release configuration uses debug signing. Suitable for local demonstration only; production signing needs a separate protected key.
- [ ] Final reviewed commit/push to origin, authorized by user on 5 November. No push has occurred.

## 12. Documentation and presentation readiness
- [~] Checklist reconciled with requirements; historical audit and other docs still need consistency pass.
- [ ] Final demo script, verified APK path/checksum, release notes and final source push.

## Researched opportunities (after core stabilization)
- [ ] P2 reusable weekly meal templates: reduce repeated planning; verify account isolation and date-specific logs.
- [ ] P2 pantry constraints: reduce grocery spending; verify availability filtering with diet/exclusions.
- [ ] P3 local export/restore: protect offline data; requires versioning, integrity checks and explicit import confirmation.
- Sources reviewed: Mealime getting-started guide https://support.mealime.com/article/151-getting-started-guide and Cronometer custom recipe guide https://support.cronometer.com/hc/en-us/articles/360018510311-Create-Custom-Recipe . Relevant patterns: ingredient-generated shopping lists and explicit recipe servings/cooked weight. These sources do not validate MacroMate nutrition or price numbers.

## Next prioritized tasks
1. Finish structured prepared-meal ingredient/cost integration using existing recipe models, without inventing measured data.
2. Complete ingredient expansion and availability controls, then weekly insights.
3. Actual Android journey/offline verification; final checks, APK, documentation and push.

## Verified checkpoint results
- Final source static analysis: no issues.
- Final release APK built successfully: build/app/outputs/flutter-apk/app-release.apk (58.0 MB).
- Latest full suite: 54 passed; one account test timed out under simultaneous build load. Isolated account rerun with `--timeout 2m`: all four passed in 86 seconds. No test or password-hashing requirement was disabled.
- SHA256: B9DBABCA53EE3E7A270B43B7A028F2AAC2B7CF70B3968F1878BEB8BBD4547CC4.
- Source checkpoint branch: codex/offline-stabilization. This is not full product acceptance; open requirements above remain open.

## Completion batch — 5 November 2026
- [x] Saved recipes now become planner candidates with current ingredient-derived nutrition and cost; focused recipe test verifies per-serving and half-serving calculations. Recipes with missing/incompatible ingredients are excluded from planning.
- [~] Pantry controls now persist selected available foods per local account/day and constrain generation, adaptation and substitutions. Recipes require every ingredient to be available. Android UI acceptance remains pending.
- [x] Planned recipe portions expand into ingredient quantities. Shopping insertion uses one SQLite transaction and a persisted request receipt; database regression verifies aggregation, retry protection and invalid-input rejection.
- [~] Progress now displays recorded spend, saved-plan estimates and logging consistency. Historical plans without a cost field are omitted; logged-day averages are explicitly labeled. UI acceptance pending.
- [x] Formatting and static analysis passed. Focused database/planner/recipe run: 13 tests passed, with the updated recipe projection test rerun successfully afterward.
- [~] Android emulator is now online. Installed checkpoint APK and observed welcome/registration screens; full journey and airplane-mode acceptance remain pending.
- [ ] Built-in prepared dishes still require sourced structured ingredient quantities. Saved user recipes have a complete ingredient-cost/planner/shopping path; catalogue dish estimates do not yet have that path.
- [ ] Reusable weekly plans and export/restore remain future opportunities, not completed features.

## Visible-function bug fix — 5 November 2026
- [x] Fixed pushed pages/dialogs losing account providers: account scope now wraps MaterialApp and its Navigator. New widget regression opens both a page and dialog and verifies account access.
- [x] Prevented profile form initialization from default data: AuthGate waits for saved profile load and shows retry on load failure before creating tracker screens. Account/session changes reset the Navigator.
- [x] Registration uses a dedicated Username field and username-only validation. Existing email accounts have a separate Email sign-in mode.
- [x] Two account-entry/routing widget tests passed; static analysis reports no issues.
- [~] Android visual journey still requires runtime acceptance; these fixes establish the shared route/provider boundary, not an assertion that every individual button was manually exercised.
