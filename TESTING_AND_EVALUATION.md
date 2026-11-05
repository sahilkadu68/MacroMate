# Testing and Evaluation

**Status:** validation in progress. Results in this file must be updated only from commands actually run against the current source.

## Automated coverage

Existing tests cover nutrition arithmetic, recommendation constraints, dietary rules, recipe/model serialization, food-provider filtering, SQLite CRUD and meal snapshots, and meal-log widgets. New tests cover local account password hashing/session restoration, wrong/weak credential validation, account-specific food/profile/meal/shopping isolation, password change and account deletion, planner budget/diet constraints, invalid targets, and lower-cost substitutions.

These tests do not prove resistance to device compromise, Android keystore encryption, full local migration compatibility, actual device behavior, or real-world price/nutrition accuracy.

## Manual acceptance checks still required

- Fresh install: register → profile setup → dashboard → plan → swap/skip/adapt → log → shopping list → progress → logout.
- Existing v3 database: upgrade with profile, custom food, edited price, meal snapshots, and list records preserved.
- Two local accounts: each keeps separate profile, foods/prices, meal logs, recipes, tracking and shopping data after switching/restarting.
- Update a local food price and confirm only future calculations use it; earlier meal snapshots stay unchanged.
- Confirm airplane-mode operation and persisted session on a physical Android device.
- Review layouts at common Android sizes and text scaling. No device/browser visual check has yet been recorded for the latest UI changes.

## Current-run command results

Pending. Do not reuse previous-session test/build outputs as verification for the current source. Release APK output path and tool versions will be added after successful reproduction.

## Stabilization checkpoint — 5 November 2026

- Formatting completed; flutter analyze reports no issues.
- Earlier regression run: 54 tests passed, plus the new recipe-cost regression passed separately.
- Latest full run alongside APK compilation: 54 passed, one password-change/deletion test hit its default 30-second timeout. Account suite rerun separately with --timeout 2m; result recorded in REQUIREMENTS_CHECKLIST.md.
- flutter build apk --release succeeded after final code changes (58.0 MB). APK: build/app/outputs/flutter-apk/app-release.apk.
- SHA256: B9DBABCA53EE3E7A270B43B7A028F2AAC2B7CF70B3968F1878BEB8BBD4547CC4.
- Android toolchain emits future-support warnings for Gradle/AGP/Kotlin. No dependency validation was bypassed.
- This APK is a development checkpoint, not full acceptance of the requirements. Debug signing remains configured; manual Android journey, restart and airplane-mode checks remain outstanding.
