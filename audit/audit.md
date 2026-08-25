# Global Project Audit Report

Date d'audit : 2026-07-22
Périmètre : `app-client/`.

## 1. Executive Summary

`app-client` est une application Flutter client pour O'Pizza : catalogue, panier, checkout, paiement Stripe, fidélité, promotions, compte et suivi temps réel. L'architecture est cohérente et plusieurs modules sont déjà testés au niveau provider/repository.

La production n'est pas approuvable. Trois risques dominent : le bouton "Ajouter au panier" ne fait pas l'ajout réel, Firebase est initialisé via un fichier généré absent du dépôt inspecté, et la configuration release peut rester en valeurs dev/test. Ces points bloquent un lancement public.

Recommended decision: Not Production Ready.

## 2. Project Understanding

Project type: Flutter mobile app / e-commerce restaurant.

Business goal: permettre à un client de commander et payer chez un restaurant tenant.

Target users: clients finaux.

Critical user journeys: catalogue -> panier -> checkout -> paiement -> suivi ; auth/compte/fidélité.

Tech stack: Flutter, Riverpod, GoRouter, Dio, Freezed, Stripe, Firebase Messaging, WebSocket, flutter_map.

Architecture: client modulaire par feature -> repositories -> `ApiClient` -> backend `api-pizza`.

Deployment context: CI Android/iOS présente ; web scaffold ; production réelle inconnue.

Data sensitivity: PII, commandes, adresse/localisation, tokens, paiement via Stripe.

AI features: aucune.

Payment/webhook features: Stripe client ; webhooks backend hors audit.

Public/private status: public si publié stores/web.

Discovery confidence: 8 / 10.

## 3. Global Scorecard

| Audit Area | Score /10 | Status | Weight | Notes |
| ---------- | --------: | ------ | -----: | ----- |
| Discovery Confidence | 8 | Good | 10% | Projet lisible, prod inconnue |
| Feature Readiness | 4 | Blocked | 20% | Ajout panier UI cassé |
| Security | 5 | Not ready | 20% | Defaults dev/test, backend inconnu |
| Performance | 5.5 | Risky | 10% | Non mesuré, baseline acceptable |
| SEO | N/A | Limited | 5% | Mobile app ; web shell générique |
| GEO | N/A | Limited | 5% | Pas de contenu public utile |
| Accessibility | 4.5 | Not ready | 10% | Carte tap-only, widgets custom |
| Production Readiness | 3 | Blocked | 20% | Firebase/signing/env/build |

Global Readiness Score:

4.5 / 10

Numeric score overridden by production blocker.

## 4. Final Production Decision

Decision: Not Production Ready

Reason: P0 fonctionnel et P0 production/configuration détectés.

Deployment recommendation: Do not deploy yet.

Conditions for approval:

- Ajouter réellement les produits au panier depuis l'UI.
- Corriger/générer la configuration Firebase.
- Bloquer les builds release avec valeurs dev/test.
- Configurer signature Android release.
- Prouver `flutter analyze`, `flutter test`, build Android/iOS.
- Valider Stripe/Firebase/backend webhooks en environnement test/staging.

## 5. P0 - Must Fix Before Production

### P0 - Ajouter au panier non branché

Area: Features.

Evidence: `ProductDetailScreen` TODO et SnackBar fictif ; golden path ajoute directement via provider.

Risk: parcours d'achat impossible.

Business Impact: aucune commande depuis l'UI standard.

Required Fix: appeler `cartProvider.notifier.addItem` avec variante/extras/quantité.

Estimated Effort: 1-2 h.

Owner Role: Frontend Developer.

### P0 - Firebase config absente

Area: Build & Runtime.

Evidence: `main.dart` importe `firebase_options.dart`; fichier/configs natives non trouvés.

Risk: build/runtime bloqué.

Business Impact: binaire non livrable.

Required Fix: générer/configurer Firebase par environnement.

Estimated Effort: 1 jour.

Owner Role: Mobile/DevOps.

### P0 - Release env non protégée

Area: Security/Production.

Evidence: defaults `http://10.0.2.2`, `pk_test_REPLACE_ME`, tenant `demo`, merchant placeholder.

Risk: mauvaise API, pas de TLS, mauvais tenant, paiement cassé.

Business Impact: fuite/erreur commandes, app inutilisable.

Required Fix: validation release bloquante.

Estimated Effort: 2-4 h.

Owner Role: Frontend/DevOps.

### P0 - Android release signée debug

Area: Deployment.

Evidence: `android/app/build.gradle.kts` utilise `signingConfigs.getByName("debug")` en release.

Risk: app non publiable.

Business Impact: lancement store bloqué.

Required Fix: keystore release sécurisé en CI.

Estimated Effort: 1/2-1 jour.

Owner Role: DevOps/Mobile.

## 6. P1 - High Priority Before Launch

### P1 - Tests UI/E2E insuffisants

Area: QA.

Evidence: tests provider ; Stripe/carte/UI complète hors scope.

Risk: bugs critiques non détectés.

Recommended Fix: widget/E2E catalogue -> panier -> checkout, Stripe test natif.

Estimated Effort: 1-3 jours.

Owner Role: QA/Frontend.

### P1 - Paiement production non durci

Area: Payments.

Evidence: `googlePay.testEnv: true`; webhooks backend non audités.

Risk: paiement live cassé ou incohérent.

Recommended Fix: env-specific payment config + audit backend Stripe.

Estimated Effort: 1-3 jours.

Owner Role: Frontend/Backend.

### P1 - Monitoring absent

Area: Production.

Evidence: pas de Crashlytics/Sentry/Performance détecté.

Risk: incidents silencieux.

Recommended Fix: crash/perf reporting et alerting backend.

Estimated Effort: 1 jour.

Owner Role: DevOps/Mobile.

## 7. P2 - Production Hardening

- Cache images/catalogue et tests faible réseau.
- Privacy/terms/RGPD links.
- Accessibilité widgets custom et carte.
- Dependency scanning.
- Documentation release/runbook mobile.

## 8. P3 - Nice Improvements

- Metadata web/PWA/ASO.
- Reduced motion.
- Versioning mobile/API.
- Analytics funnel commande.

## 9. Critical User Journey Verdicts

### Catalogue -> Panier

Status: Blocked.

Evidence: bouton "Ajouter au panier" ne modifie pas `cartProvider`.

Risks: conversion impossible.

Required Fixes: brancher provider et test widget.

### Panier -> Checkout -> Commande

Status: Risky.

Evidence: provider/test partiels ; dépend du P0 panier.

Risks: UX livraison et E2E non validés.

Required Fixes: tests UI et validation backend staging.

### Commande -> Paiement -> Suivi

Status: Risky/Unknown.

Evidence: PaymentSheet codée, native non testée ; Google Pay testEnv.

Risks: paiement live et webhooks inconnus.

Required Fixes: QA Stripe test/live-mode contrôlée.

### Auth/Compte/Fidélité

Status: Almost Ready.

Evidence: screens/providers/tests présents.

Risks: backend permissions non vérifiées.

Required Fixes: tests backend contract/auth.

## 10. Security Summary

Authentication status: bonne base côté client.

Authorization status: guards frontend présents, backend enforcement inconnu.

Secrets status: pas de secret prod observé, defaults dangereux.

API security status: timeouts/Bearer centralisés, release HTTP possible si mal configuré.

Database/storage status: pas de DB client ; secure storage refresh token.

Multi-tenant status: tenant slug client, backend isolation inconnue.

Webhook/payment status: webhooks backend non audités ; client Stripe non prêt prod.

AI security status: N/A.

Biggest security risk: release mal configurée avec valeurs dev/test.

Security verdict: Not Production Ready.

## 11. Functional Summary

Core feature status: bloqué par ajout panier.

Broken flows: catalogue -> panier.

Validation quality: correcte dans plusieurs forms/providers.

Error handling: AppException et messages présents ; E2E incomplet.

External integration status: Stripe/Firebase/WS présents mais non prouvés prod.

Biggest functional risk: succès visuel sans effet réel sur le panier.

Functional verdict: Core Features Broken.

## 12. Performance Summary

Frontend performance: baseline Flutter correcte, non profilée.

Backend/API performance: hors périmètre, timeouts client présents.

Database performance: backend.

Caching: faible.

AI latency/cost: N/A.

Mobile performance: non mesurée.

Biggest performance bottleneck: absence de mesures release/profiling.

Performance verdict: MVP Usable With Performance Risks.

## 13. SEO & GEO Summary

SEO/GEO est peu applicable si le produit est mobile-only. Si le web/PWA est public, il n'est pas prêt : `web/index.html` et `manifest.json` gardent `app_client` et "A new Flutter project", pas de sitemap/robots/structured data détectés.

Biggest SEO/GEO gap: aucune surface publique optimisée ou ASO documentée.

SEO/GEO verdict: Not Applicable for mobile app, Not Search Ready for public web.

## 14. Accessibility Summary

WCAG readiness: non démontrée.

RGAA relevance: possible contexte FR, pas assez pour conformité.

Keyboard navigation: risques `GestureDetector` et carte.

Screen reader support: peu de semantics explicites, non testé.

Forms: labels/validators présents, erreurs à renforcer.

Modals: `AlertDialog` natif, focus non validé.

Mobile accessibility: carte tap-only risquée.

Biggest accessibility blocker: sélection de livraison uniquement par carte.

Accessibility verdict: Not Production Ready.

## 15. Production Readiness Summary

Build/runtime status: bloqué/inconnu par Firebase et tooling local absent.

Environment status: defaults dev/test.

CI/CD status: workflow présent, non exécuté ici.

Tests: nombreux tests unit/provider, E2E incomplet.

Logs/monitoring: absent côté client.

Health checks: backend hors audit.

Backups/rollback: backend/mobile strategy inconnue.

Deployment: Android debug signing ; iOS no-codesign.

Privacy/RGPD: incomplet.

Documentation: README scaffold.

Biggest production risk: app non livrable ou mauvais build.

Production verdict: Do not deploy yet.

## 16. Quick Wins

Security:

- Ajouter guard release env.

Features:

- Brancher ajout panier.

Performance:

- Ajouter build size/profiling step.

Accessibility:

- Labels/tooltips/semantics sur widgets custom.

SEO/GEO:

- Corriger title/description web si web maintenu.

Production:

- Générer Firebase config et README env.

## 17. 48-Hour Stabilization Plan

### Hour 0-4

Corriger ajout panier, test widget, guard release env.

### Hour 4-8

Générer Firebase configs, documenter dart-defines, corriger CI si besoin.

### Hour 8-16

Passer analyze/tests/builds, config Android signing, corriger blockers.

### Hour 16-24

QA checkout + Stripe test natif + backend webhook staging.

### Hour 24-48

Monitoring crash/perf, privacy links, accessibilité critique, release checklist.

## 18. 7-Day Launch Plan

### Day 1

P0 fonctionnel/config/build.

### Day 2

Paiement/Firebase/signing.

### Day 3

E2E UI et QA manuelle.

### Day 4

Accessibilité checkout/carte/widgets.

### Day 5

Monitoring, privacy, runbook.

### Day 6

Staging full smoke test.

### Day 7

Go/no-go et build candidate.

## 19. 30-Day Maturity Roadmap

### Week 1

Stabilisation production MVP.

### Week 2

Cache/offline/perf monitoring, dependency scanning.

### Week 3

Accessibilité mobile complète, UX adresse.

### Week 4

Analytics funnel, ASO/web landing, versioning API/mobile.

## 20. Go / No-Go Matrix

| Condition | Status | Decision Impact |
| --------- | ------ | --------------- |
| App builds successfully | Unknown/Blocked | No-Go |
| Core user journeys work | Blocked | No-Go |
| Authentication safe | Partial | Conditional |
| Authorization safe | Unknown backend | Conditional |
| Secrets safe | Partial | No-Go until guard |
| Database protected | Unknown backend | Conditional |
| Webhooks safe if present | Unknown backend | Conditional |
| AI safety acceptable if present | N/A | No impact |
| Performance acceptable | Unknown | Conditional |
| Accessibility acceptable | Not ready | Conditional/P1 |
| Monitoring enabled | No | Conditional |
| Backups ready if data exists | Unknown backend | Conditional |
| Rollback ready | Unknown | Conditional |
| Privacy/RGPD acceptable | Not ready | Conditional |

Final Go/No-Go: No-Go.

## 21. Owner-Based Action Plan

### Frontend Developer

- Corriger ajout panier.
- Ajouter tests widgets/E2E.
- Améliorer widgets accessibility.

### Backend Developer

- Confirmer auth/tenant/order/payment/webhook sécurité.
- Fournir staging stable.

### DevOps / Deployment

- Firebase configs, Android signing, CI artifacts, release secrets.

### Security

- Env guards, dependency scanning, review paiement/backend.

### Product / QA

- Smoke tests commandes, Stripe, livraison, tracking.

### SEO / Content

- Si web public : landing/meta/manifest/robots/sitemap.

### Accessibility

- Manual TalkBack/VoiceOver/clavier.

## 22. Final Recommendation

Je n'approuverais pas ce déploiement aujourd'hui. Le plus court chemin vers un lancement sûr est de corriger l'ajout panier, rendre Firebase/build reproductible, bloquer les mauvaises configs release, puis valider paiement et parcours complet en staging.

Final decision: Not Production Ready.
