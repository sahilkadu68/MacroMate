# MacroMate India — Product Requirements

**Status:** Baseline and next-release requirements, 28 October 2026

## Product

MacroMate helps Indian college students and beginner fitness users make everyday food decisions using their own nutrition goals, a food budget, and foods they can obtain locally. Its differentiator is the combination of affordable meal choices, transparent quantity calculations, editable local prices, and progress over time. It is a wellness and planning tool, not a medical product or dietitian replacement.

## Primary user and job

The first target user is a budget-conscious college student or beginner gym-goer who wants to eat in line with a fitness goal but cannot depend on expensive meal plans or supplements. The core job is: “Help me decide what I can eat today, what it may cost, and how that choice fits the targets I set.” This segment is a product hypothesis; no user interviews or usability study have yet been recorded in this repository.

## Main journey

1. Understand the product and its estimates.
2. Set editable nutrition targets, diet preference, and daily food budget.
3. Review practical options and prices; correct local prices before planning.
4. Log a food quantity and meal type with visible calculated totals.
5. Use a constrained suggestion or recipe, then create a shopping list.
6. Review logged nutrition and estimated spending over time.

The app supports device-local registration/login, profile setup, food browsing/editing, meal logging, a deterministic food-combination finder, recipes, shopping-list entries, and progress tracking. Each account uses an isolated local database file. It does not use cloud auth, backup, or synchronization. Browser fallback storage is temporary memory and must be disclosed as such.

## Requirements for a credible first release

### Local account status

Email/username and password account creation, login, session restoration, logout, profile onboarding, password changes, and account deletion are implemented locally. Passwords are salted PBKDF2-HMAC-SHA256 hashes. The first account on an existing installation uses the original local database so prior data remains available. This does not encrypt local nutrition records or protect data from someone with access to the device.

- Keep a clear Home, Plan, Log, Foods, Progress, and Profile/Settings journey; do not elevate every tool to primary navigation.
- Make nutrition and cost units explicit and calculate from quantity without silently treating missing price as free.
- Distinguish verified, user-entered, and unverified estimated food data. Provide source, date, geography, preparation basis, and confidence where supported.
- Explain recommendation constraints and ranking; never label an estimate as a guaranteed or clinically appropriate plan.
- Preserve historical meal snapshots if food or price records later change.
- Provide understandable empty, loading, validation, storage, and failure states.
- Support keyboard use, readable contrast and text scaling, and narrow mobile and desktop layouts.
- Do not claim cloud backup, multi-device sync, account isolation, deletion, subscriptions, or live billing unless implemented and verified.

## Product decisions and measures

Prioritize trustworthy food data and local-price correction before adding AI or broad feature count. Establish baselines before setting improvement targets. Measure task completion and time for first setup, food logging, plan review, and list creation; arithmetic against known fixtures; share of records with traceable sources; recommendation hard-constraint pass rate; storage persistence; and layout defects. See `TESTING_AND_EVALUATION.md`.
