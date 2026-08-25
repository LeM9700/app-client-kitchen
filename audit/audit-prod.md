# Pre-Production Audit Report

Date d'audit : 2026-07-22
Périmètre : `app-client/`.

## 1. Final Go/No-Go Decision

Decision: Do not deploy yet

Reason: l'app présente des bloqueurs avant production : configuration Firebase absente, parcours principal d'ajout panier cassé, release Android signée debug, defaults dev/test non bloquants, build/test/analyze non exécutables localement dans cette session.

## 2. Production Context

Project type: application Flutter mobile/web client.

Target users: clients finaux de restaurant.

Critical user journeys: catalogue -> panier -> checkout -> paiement -> suivi.

Deployment target: Android/iOS via GitHub Actions ; web possible mais non prêt public.

Runtime: Flutter >= 3.22 / Dart >= 3.4.

Database: backend `api-pizza`.

Auth: JWT access token mémoire, refresh token secure storage.

AI: aucune.

Payment/webhooks: Stripe PaymentSheet côté client ; webhooks backend hors périmètre.

Data sensitivity: PII client, commandes, adresse/coordonnées, tokens.

## 3. P0 - Must Fix Before Production

### Firebase config manquante

Evidence: `lib/main.dart` importe `firebase_options.dart` et initialise Firebase ; aucun fichier Firebase généré trouvé.

Risk: build/runtime impossible ou configuration non contrôlée.

Fix: générer `firebase_options.dart` et configs natives par environnement ou rendre Firebase optionnel selon build.

### Parcours d'achat cassé à l'ajout panier

Evidence: `ProductDetailScreen` TODO "ajouter l'item au CartNotifier" et SnackBar fictif.

Risk: utilisateur incapable de composer une commande.

Fix: brancher `cartProvider.notifier.addItem` et tester l'UI.

### Release Android signée debug

Evidence: `android/app/build.gradle.kts:31-32`.

Risk: binaire non acceptable production/store.

Fix: config signing release via keystore sécurisé CI.

### Defaults dev/test non bloqués

Evidence: `API_BASE_URL=http://10.0.2.2:8000`, `pk_test_REPLACE_ME`, tenant `demo`, merchant placeholder.

Risk: mauvaise build, trafic non TLS, paiement inutilisable.

Fix: validation release obligatoire.

## 4. P1 - High Priority Before Launch

- Exécuter et archiver `flutter analyze`, `flutter test`, builds Android/iOS avec configs réelles.
- Valider Stripe en test natif et backend webhook.
- Ajouter monitoring crash/performance.
- Documenter env vars, build, signing, Firebase, release.
- Ajouter privacy/terms si app publique.

## 5. Build & Runtime

Status: Not Ready.

Evidence:

- CI déclare format/analyze/test/build Android/iOS.
- Localement, `flutter` et `dart` ne sont pas reconnus dans cette session.
- `firebase_options.dart` absent alors qu'importé.

Required action: faire passer CI avec artefacts, corriger Firebase, documenter version Flutter.

## 6. Environment & Secrets

Status: Not Ready.

Evidence: variables injectées par `--dart-define` en CI via secrets, mais defaults faibles dans code.

Risk: release accidentelle avec valeurs dev.

Required action: guard release + `.env.example`/README mobile + séparation dev/staging/prod.

## 7. Tests & CI/CD

Status: Partial.

Evidence: `.github/workflows/ci.yml` exécute format, analyze, tests coverage, build Android/iOS no-codesign. 19 fichiers tests existent.

Gaps:

- Pas d'E2E UI catalogue -> panier -> checkout.
- Stripe natif et carte hors scope des tests.
- Interceptor refresh 401 partiellement non testable.
- CI non exécutée dans cette session.

## 8. Monitoring, Logs & Health Checks

Status: Not Ready.

Evidence: aucune config Sentry, Crashlytics, Firebase Performance ou health/smoke release côté client détectée.

Required action: crash reporting mobile, logs non sensibles, smoke tests post-release, monitoring backend lié.

## 9. Database, Migrations, Backups & Rollback

Status: Backend dependency / Unknown.

Client: pas de DB locale critique, panier en mémoire.

Backend: commandes, paiements, utilisateurs et fidélité nécessitent backups/migrations/rollback côté `api-pizza`, hors cet audit.

Mobile rollback: non documenté ; stores imposent stratégie version/backend compatible.

## 10. Privacy/RGPD

Status: Not Ready / Unknown.

Evidence: aucune page privacy/terms détectée dans `app-client`; collecte indirecte email, téléphone, adresse/coordonnées, commandes.

Required action: politique de confidentialité, droits utilisateur, suppression/export côté backend, liens dans app/store.

## 11. Manual Pre-Launch Checklist

Before Deploy:

- [ ] Corriger ajout panier UI.
- [ ] Générer configs Firebase dev/staging/prod.
- [ ] Ajouter validation release env.
- [ ] Configurer keystore Android release.
- [ ] Exécuter `flutter analyze` et `flutter test`.
- [ ] Tester build APK/IPA release.
- [ ] Tester Stripe test cards + 3DS.
- [ ] Vérifier backend webhooks/payments.
- [ ] Ajouter crash/perf monitoring.
- [ ] Ajouter privacy/terms.

During Deploy:

- [ ] Utiliser secrets prod.
- [ ] Vérifier `https`/`wss`.
- [ ] Smoke test catalogue/panier/checkout/paiement/suivi.
- [ ] Vérifier logs backend et Stripe.

After Deploy:

- [ ] Surveiller crashes, payment failures, API errors.
- [ ] Vérifier notifications push.
- [ ] Contrôler taux d'abandon checkout.

Rollback Preparedness:

- [ ] Plan rollback backend.
- [ ] Version mobile compatible ancienne/nouvelle API.
- [ ] Feature flags pour paiement/livraison si possible.

## 12. 48-Hour Stabilization Plan

Hour 0-4: corriger ajout panier, ajouter test widget minimal, ajouter validation release env.

Hour 4-8: générer Firebase config dev/staging, documenter secrets, vérifier build local/CI.

Hour 8-16: config signing Android, passer analyze/tests/build, corriger failures.

Hour 16-24: smoke test checkout + Stripe test natif, vérifier backend webhook.

Hour 24-48: monitoring crash/perf, privacy links, checklist release et QA accessibilité minimale.

## 13. Final Verdict

L'app ne doit pas être déployée aujourd'hui. Elle peut redevenir candidate à un MVP contrôlé après correction des P0, preuve de build/test CI, validation Stripe/Firebase et smoke tests du parcours commande.

Final decision: Do not deploy yet.
