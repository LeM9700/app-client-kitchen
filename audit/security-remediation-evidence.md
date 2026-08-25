# Security remediation evidence

Date : 2026-07-22

## Corrige dans le depot

- CI activee au root Git via `../.github/workflows/app-client-ci.yml`.
- Codegen `build_runner` execute avant analyse, tests et builds release.
- Dependabot deplace au root avec `directory: /app-client`.
- Scan secrets Gitleaks ajoute au workflow root.
- Validation release Firebase renforcée : `FIREBASE_STORAGE_BUCKET` obligatoire.
- Stockage refresh token durci : Android `encryptedSharedPreferences` +
  `resetOnError`, backup Android desactive, Keychain iOS non synchronisable et
  attache a l'appareil.
- Sanitation commune des traces analytics/erreurs : tokens, secrets Stripe,
  Firebase API keys, emails et PaymentIntent IDs sont rediges.
- Notification push : `order_id` doit etre un entier positif avant navigation.
- Paiement backend : `POST /payments/intent` reutilise un paiement pending actif
  par tenant/user/order et verrouille la commande avec `SELECT FOR UPDATE`.

## Tests ajoutes

- `test/core/auth/token_storage_test.dart`
- `test/core/monitoring/error_reporter_test.dart`
- `test/features/tracking/push_notification_service_test.dart`
- `api-pizza/tests/test_payments.py` : reutilisation d'un PaymentIntent pending
  et refus d'une commande deja payee.

## Reste a prouver hors depot local

- CI GitHub verte avec secrets reels.
- OSV/Gitleaks executes dans GitHub Actions.
- Firebase/APNs/FCM sur appareils reels.
- Stripe webhook staging signe et rejoue sans double effet.
- Audit backend complet authz/tenant/JWT/logs/privacy.
- Re-audit final via `.claude/commands/audit-security.md`.
