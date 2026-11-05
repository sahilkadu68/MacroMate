# Security and Privacy

## Current posture

MacroMate has device-local accounts. Passwords are stored as salted PBKDF2-HMAC-SHA256 hashes, never plaintext, and the active account ID is persisted locally to restore a session. Account records are stored in a separate SQLite file per account. No authentication server, cloud database, email verification, or email password recovery is used.

This separation protects against accidental account switching inside the app. It is not a security boundary against someone who can access the unlocked device, application sandbox, backup, or a rooted device. Nutrition records are not encrypted by app code. No cloud sync, backup, export, or recovery exists. Clearing app data or uninstalling may delete records.

The first account created on an installation uses the original SQLite file, preserving data from earlier single-profile versions. Later accounts get their own files and seeded catalogue. Deleting an account requires its password and deletes its data file.

## Data stored locally

The account database contains normalized email/username and password hash. The app data database contains profile name, age, height, weight, diet/goals, meal snapshots, estimated food prices, water, activity, recipes, shopping items, favorites, and related records. Web SQLite fallback stores data in memory only and may lose it on reload/close.

## Remaining safeguards and gaps

- No platform key-store encryption or encrypted backup.
- No export or account recovery. Local account deletion is the only in-app account-data removal flow.
- PBKDF2 parameters and password handling should be covered by regression tests. A local account is not equivalent to server-side authentication.
- Food data and health targets are unverified estimates; avoid medical or outcome claims.
- Do not log passwords, hashes, or personal nutrition details. Keep application identifiers and signing keys out of public builds; release signing is not configured here.
- Validate finite ranges, units, and ownership consistently at database/repository write boundaries.
