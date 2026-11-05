# Implementation Status

**Updated:** 5 November 2026. This file describes code changes in progress; see `TESTING_AND_EVALUATION.md` for checks actually run.

## Current product

- Offline-first Flutter app with local account gate, profile setup/editing, food catalogue, meal logging, protein suggestions, recipes, shopping list, tracking, and progress views.
- Local accounts use a separate account registry, PBKDF2-HMAC-SHA256 password hashes, persisted active account IDs, and a separate SQLite data file per account. First account retains the original database path to preserve prior single-profile data.
- Password change, account deletion, and logout are available from Profile. Local accounts do not provide online identity, email verification, cloud recovery, encryption, backup, or sync.
- Main navigation includes Home, Foods, Plan, Logs, Progress, and Profile.
- Food records now carry cuisine, meal types, ingredients, entry kind, price region/confidence, and a user-price marker. The starter set includes regional prepared-food entries with explicitly low-confidence estimates.
- A deterministic daily planner can generate meal slots within budget, show remaining target/budget after the plan, log a planned meal, adapt unlogged slots, find lower-cost food substitutions, and add planned foods to the list.

## Data and limitations

- Existing food composition and prices are not verified against individual IFCT rows or current Mumbai market observations. Newly added dish macros and prices are approximate recipe/planning estimates, clearly labeled as unverified.
- Costs still use each food's unit price and quantity basis. Recipe builder ingredients have snapshots, but prepared-dish price totals are not yet dynamically derived from structured ingredient quantities.
- SQLite schema is version 4. The v2→v3 upgrade now retains existing rows and backfills package fields rather than deleting and replacing built-in foods. The v3→v4 upgrade adds food metadata and only inserts missing new records.
- Each account uses a separate database file. Existing account data is not encrypted by app code and remains accessible to someone with access to the unlocked device/app sandbox.
- Web SQLite failure uses a temporary in-memory fallback and cannot guarantee persistence.
- Planner constraints and substitutions are deterministic heuristics. Calorie/protein goals are ranking targets, not guaranteed outcomes or medical guidance.

## Research and data references

- Official MyFitnessPal and Cronometer support pages were reviewed for food search/detail/serving adjustment, repeat meals, plan swaps, plan-to-log flow, and data-source labels. MacroMate implements offline equivalents appropriate to its scope; no competitor database/assets are copied.
- ICMR-NIN IFCT 2017 and the Department of Consumer Affairs daily essential-commodity price reports remain reference sources. Current seeded rows do not yet contain row-level IFCT IDs or matched Mumbai price observations.

## Deferred

- Structured ingredient-level price records and dynamic prepared-meal costing.
- Plan history and multi-day generation; automated portion-scaled recipe-to-shopping conversion.
- Platform keystore encryption, encrypted backup/export, and app-store release signing.
- Live device testing, airplane-mode verification, and usability research.

## Stabilization batch

Shopping quantities can now be edited with validation and save errors. Outstanding groceries show an estimate based on matching catalogue prices with compatible units; unpriced items are explicitly counted. Recipe aggregation no longer combines incompatible units. Saved recipe details and future recipe logs refresh matching ingredient values; missing ingredients retain saved snapshots. Planner exclusions apply to generation and substitution, using case-insensitive text matching and account/day-scoped persistence. These changes do not provide certified allergy filtering or verified nutrition data.
