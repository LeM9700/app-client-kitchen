# Performance Audit Report

Date d'audit : 2026-07-22
Périmètre : `app-client/`.

## 1. Executive Summary

Verdict: MVP Usable With Performance Risks

Le client Flutter a plusieurs bonnes bases : listes construites avec builders, timeouts Dio, WebSocket avec backoff et polling espacé, images réseau avec `cacheWidth` dans certains composants, panier local et providers Riverpod. Aucun goulot critique purement algorithmique n'a été détecté dans le code inspecté.

La performance production reste néanmoins non mesurée : `flutter`, `dart`, Lighthouse, bundle analysis et profiling ne sont pas disponibles dans cette session. Il manque aussi monitoring, mesures de cold start, taille de bundle, crash/performance reporting, stratégie cache/offline et validation réelle mobile faible réseau.

Top 3 bottlenecks:

- Aucune mesure build/profile disponible localement.
- Images/API/OSM/Stripe/Firebase dépendent du réseau sans cache/offline robuste visible.
- Monitoring performance absent.

## 2. Project Performance Context

Project type: app Flutter mobile/web de commande restaurant.

Users: clients finaux sur mobile principalement.

Critical user journeys: catalogue, détail, panier, checkout, paiement, suivi.

Frontend framework: Flutter.

Backend framework: FastAPI présumé via `api-pizza`, hors périmètre.

Database: backend uniquement.

Deployment target: Android/iOS via CI ; web scaffold présent.

AI features: aucune.

Media-heavy features: images produits réseau, OpenStreetMap tiles.

Real-time features: WebSocket notifications + polling.

Expected traffic: non documenté.

## 3. Performance Scorecard

| Category | Score /10 | Status |
| -------- | --------: | ------ |
| Frontend Performance | 6 | Baseline correcte, non profilée |
| Core Web Vitals | 3 | Web shell générique, non mesuré |
| Rendering Strategy | 6 | Flutter client app cohérent |
| Backend Performance | Unknown | Hors périmètre |
| API Latency | 5 | Timeouts présents, métriques absentes |
| Database Performance | Unknown | Backend |
| Caching | 3 | Peu de cache explicite/offline |
| Media Optimization | 5 | `cacheWidth` partiel, assets vides |
| AI Performance | N/A | Pas d'AI |
| Vector Search Performance | N/A | Pas de vector search |
| Background Jobs | N/A | Pas côté client |
| Infrastructure | 4 | CI existe, prod inconnue |
| Mobile Performance | 5 | Flutter standard, non profilé |
| Real-Time Performance | 7 | Backoff + polling 35s raisonnables |
| Monitoring | 2 | Aucun monitoring détecté |
| Performance Testing | 1 | Aucun test perf détecté |

Global Performance Score:

5.5 / 10

## 4. Critical Bottlenecks

### Performance non mesurée en build/profile

Severity: High

Priority: P1

Affected Area: mobile/web release.

Evidence: `flutter --version` et `dart --version` non reconnus ; aucun rapport build size/profiling détecté.

Performance Impact: impossible de valider cold start, jank, taille APK/IPA/web.

User Impact: risque de lenteur ou crash non détecté avant release.

Business Impact: abandon checkout, mauvaise note store.

Technical Cause: tooling local absent et CI non exécutée dans cette session.

Recommended Fix: exécuter `flutter analyze`, `flutter test`, `flutter build apk --analyze-size`, profiling DevTools sur device.

Estimated Effort: 1/2 jour.

Production Blocker: no, mais requis avant go-live.

### Cache/offline limité pour catalogue et médias

Severity: Medium

Priority: P1

Affected Area: catalogue / images / réseau.

Evidence: usage `Image.network`, Dio sans cache HTTP client explicite, pas de `cached_network_image` ou stratégie offline visible.

Performance Impact: rechargements réseau répétés, UX faible en connexion lente.

User Impact: menu plus lent, images absentes, abandon.

Business Impact: baisse conversion mobile.

Recommended Fix: cache images robuste, cache court catalogue/branding, états offline plus explicites.

Estimated Effort: 1-2 jours.

Production Blocker: no for beta, risk for public.

### Monitoring performance absent

Severity: Medium

Priority: P1

Affected Area: observability.

Evidence: aucune dépendance/config Sentry, Crashlytics, Firebase Performance ou tracing détectée.

Performance Impact: aucun p95/p99, crash, jank ou latence visible après launch.

User Impact: incidents silencieux.

Business Impact: support réactif impossible.

Recommended Fix: ajouter Crashlytics/Sentry et Firebase Performance ou équivalent mobile.

Estimated Effort: 1 jour.

Production Blocker: no for controlled MVP, yes for public confidence.

## 5. Detailed Findings By Domain

Frontend:

Problem: UI Flutter modulaire, mais pas de profiling rebuild/jank.

Evidence: Riverpod/providers ; aucun rapport DevTools.

Impact: jank possible dans écrans riches fidélité/catalogue.

Fix: profiler ProductDetail, Home, Cart, Checkout.

Priority: P2.

API:

Problem: timeouts présents mais pas de retry/circuit breaker global.

Evidence: `ApiClient` connectTimeout 10s, receiveTimeout 30s.

Impact: UX bloquée sur réseau faible si actions longues.

Fix: retry contrôlé pour lectures idempotentes, messages offline.

Priority: P2.

Media:

Problem: images réseau non systématiquement dimensionnées/cache robustes.

Evidence: `ProductCard` note `cacheWidth`, autres `Image.network` présents.

Impact: consommation data et memory spikes.

Fix: widths cohérents, thumbnails côté backend/CDN, cache image.

Priority: P2.

Real-Time:

Problem: approche raisonnable.

Evidence: backoff 1/2/4/8/16/30s, polling 35s, arrêt états terminaux.

Impact: acceptable pour MVP.

Fix: mesurer charge serveur et battery impact.

Priority: P3.

Testing:

Problem: pas de tests de charge/perf.

Evidence: 19 fichiers tests unit/provider/intégration, aucun perf.

Impact: régressions non vues.

Fix: smoke perf manuel + build size CI.

Priority: P2.

## 6. Critical User Journey Performance

### Catalogue -> Détail Produit

Expected Performance: affichage rapide, images adaptées, recherche fluide.

Observed or Inferred Bottlenecks: images réseau, pas de cache explicite, metrics inconnues.

Risk: Risky.

Recommended Optimization: cache image, skeletons déjà partiels, mesurer temps d'ouverture.

Verdict: Acceptable.

### Panier -> Checkout

Expected Performance: interaction immédiate, API revalidation bornée.

Observed or Inferred Bottlenecks: revalidation boucle sur items avec appels `getProduct` séquentiels.

Risk: panier avec beaucoup d'items peut multiplier les appels.

Recommended Optimization: endpoint bulk revalidation ou parallélisation contrôlée.

Verdict: Risky.

### Paiement

Expected Performance: PaymentSheet rapide, erreurs visibles, pas de double intent.

Observed or Inferred Bottlenecks: Stripe natif non mesuré, backend non audité.

Risk: Unknown.

Recommended Optimization: mesurer p95 create intent/confirm, timeout UI, logs.

Verdict: Unknown.

### Tracking

Expected Performance: état initial rapide puis temps réel.

Observed or Inferred Bottlenecks: fetch initial + WS + polling 35s.

Risk: acceptable si backend tient.

Recommended Optimization: métriques WebSocket, reconnect success.

Verdict: Acceptable.

## 7. AI Performance Assessment

No AI features detected.

## 8. Database Performance Assessment

No database detected côté client. Les performances DB doivent être auditées dans `api-pizza`.

## 9. Core Web Vitals Assessment

Core Web Vitals audit limited. Le projet contient `web/`, mais il s'agit d'un shell Flutter web générique avec metadata par défaut. Si le web est public, il faut mesurer Lighthouse/WebPageTest et considérer une landing page séparée pour SEO/perf. Si mobile-only, CWV est secondaire.

## 10. P0 / P1 / P2 / P3

P0:

- No P0 performance blockers detected from code-only review.

P1:

- Exécuter builds/profiling release.
- Ajouter monitoring performance/crash.
- Mettre en place cache image/catalogue.

P2:

- Optimiser revalidation panier en bulk/parallèle contrôlé.
- Ajouter mesure taille APK/IPA/web en CI.
- Tester faible réseau et offline.

P3:

- Bundle analysis Flutter web si support web maintenu.
- Battery profiling tracking.

## 11. Quick Wins

- Ajouter une étape CI `flutter build apk --analyze-size` ou artefact size report.
- Ajouter `cacheWidth` cohérent sur toutes les images produit/recommandations.
- Ajouter logs de durée API côté client en debug/staging.
- Documenter scénario manuel faible réseau.

## 12. Suggested Performance Tests

Frontend tests:

- Profil DevTools sur Home/ProductDetail/Cart/Checkout sur device moyen.

Backend/API tests:

- Mesurer p95 `/catalog/products`, `/orders`, `/payments/intent`, `/orders/{id}` côté backend.

Database tests:

- Hors client ; audit backend.

Load tests:

- Scénario 100 clients suivant commande via WebSocket/polling.

Regression tests:

- Build size budget par release.

## 13. Recommended Monitoring

- Firebase Crashlytics ou Sentry Flutter pour crashes.
- Firebase Performance ou traces custom pour startup, catalogue, checkout, paiement.
- Logs backend corrélés par request/order ID.
- Stripe dashboard alerts pour payment failures.
- WebSocket connection/reconnect metrics.

## 14. Final Verdict

La performance peut être acceptable pour un MVP contrôlé, mais elle n'est pas prouvée. Avant production publique, il faut exécuter les builds release, profiler sur device, ajouter monitoring et renforcer cache/réseau.

Performance decision: MVP Usable With Performance Risks.
