# Security Audit Report

Date d'audit : 2026-07-22
Perimetre : `workspace/pizza/app-client/`
Instruction appliquee : `.claude/skills/security-audit.md`
Rapport de discovery utilise : `app-client/audit/audit-discovery.md` ; confiance annoncee 8/10, mais plusieurs points ont ete revalides car le rapport est anterieur a des remediations recentes.

## 1. Executive Summary

Verdict strict : Not Production Ready pour une mise en production produit complete.

Le client Flutter dispose maintenant d'une bonne base securite dans son propre perimetre : validation release avant Firebase/Stripe/reseau, access token en memoire, refresh token dans `flutter_secure_storage` durci par plateforme, API client centralisee, injection tenant systematique, idempotency key pour creation de commande, configuration Firebase par `dart-define`, Stripe PaymentSheet, CI root configuree, Dependabot, OSV et Gitleaks prevus.

Ce constat ne suffit pas pour declarer l'application production-safe. Les risques qui peuvent exposer les utilisateurs, paiements et tenants dependent majoritairement du backend, de Stripe, de Firebase et de la CI/CD reelle. Aucun controle backend critique ne doit etre suppose securise sans preuve.

Top 3 risks :

- Autorisation objet et isolation tenant serveur Unknown : les guards Flutter et `X-Tenant-Slug` ne sont pas une autorisation reelle.
- Paiement Stripe incompletement prouvable cote client : le client appelle `/payments/confirm` avec un `provider_payment_id`, mais la verification backend/webhook Stripe reste hors perimetre et Unknown.
- CI/scans/builds release configures mais non prouves : `flutter`, `dart`, `osv-scanner` et `gitleaks` sont absents du shell local, et les workflows root sont encore vus comme non suivis par le `git status` local.

Score client-only : 7.2 / 10.

Score produit complet : Unknown tant que backend, Stripe webhooks, Firebase, secrets CI et validations appareil ne sont pas audites.

## 2. Project Security Context

Project type : application Flutter mobile, avec support web present dans le scaffold.

Users : clients finaux de restaurants/pizzerias : catalogue, panier, compte, commandes, paiement, suivi de commande, notifications push.

Auth system : login email/password via backend `api-pizza`, JWT access token en memoire Riverpod, refresh token persiste localement dans `flutter_secure_storage`.

Database : aucune base locale detectee dans `app-client/`. Les donnees persistantes vivent cote backend.

Storage : refresh token en secure storage ; panier et etat applicatif principalement en memoire. Aucun upload fichier client detecte.

External services : API `api-pizza`, Stripe PaymentSheet, Firebase Core/Messaging, WebSocket backend, tuiles OpenStreetMap.

AI features : aucune fonctionnalite IA detectee.

Payment/webhook features : paiement Stripe cote client via PaymentSheet ; aucun webhook dans `app-client/`. Les webhooks Stripe sont necessairement backend.

Multi-tenant status : build configuree par `TENANT_SLUG`, envoye dans `X-Tenant-Slug`, dans le body login et dans la query WebSocket. L'isolation reelle doit etre imposee serveur.

Data sensitivity : email, nom, telephone optionnel, adresse de livraison, coordonnees de livraison, commandes, statuts de paiement, tokens, identifiants PaymentIntent, tokens FCM.

## 3. Security Scorecard

| Category | Score /10 | Status |
| -------- | --------: | ------ |
| Authentication | 8 | Bonne hygiene client ; validation JWT/refresh/revocation backend Unknown |
| Authorization | 5 | Routes protegees cote UI ; object-level authorization backend Unknown |
| Data Access Control | 5 | Pas de DB client ; controle d'acces API/backend Unknown |
| Multi-Tenant Isolation | 5 | Tenant slug injecte ; isolation serveur non prouvee |
| Secrets Management | 8 | Gitignore et placeholders corrects ; scan Gitleaks non execute localement |
| API Security | 7 | Dio centralise, timeouts, refresh 401 ; rate limit/CORS/validation serveur Unknown |
| Webhook Security | Unknown | Aucun webhook client ; Stripe webhook backend non audite |
| AI Security | N/A | Aucune IA detectee |
| File & Storage Security | 8 | Secure storage durci ; tests appareils logout/restore non prouves |
| Database Security | N/A | Aucune base locale client |
| Frontend Security | 8 | Release guard, routes legales, push route hardening ; web headers Unknown |
| Backend Security | Unknown | Hors perimetre `app-client/` |
| Dependency Security | 7 | Lockfile, Dependabot, OSV CI ; scan local impossible |
| Cloud/Deployment Security | 6 | CI root configuree mais non prouvee/possiblement non commitee |
| Logging & Monitoring | 6 | Redaction client presente ; reporter production noop tant qu'aucun outil n'est branche |
| Privacy | 5 | URLs legales exigees ; contenu legal, retention, export/suppression Unknown |

Global Security Score:

7.2 / 10 pour `app-client/` strict.

## 4. Critical Findings

### Autorisation objet et isolation tenant serveur non verifiees

Severity: Critical

Priority: P0

Affected Area: authorization, multi-tenant isolation, commandes, sessions, paiements.

Evidence: le client ne fait qu'injecter `X-Tenant-Slug` via `ApiClient.setTenantSlug` (`lib/core/api/api_client.dart:108`) et proteger quelques routes par presence d'access token (`lib/core/router/app_router.dart:74-86`). Le login envoie aussi `tenant_slug` dans le body (`lib/features/auth/repositories/auth_repository.dart:45`). Le WebSocket envoie `tenant_slug` en query (`lib/features/tracking/providers/tracking_provider.dart:176-178`). Aucun test ou code `app-client/` ne peut prouver que le backend scope toutes les ressources au tenant et a l'utilisateur.

Risk: un attaquant qui appelle l'API directement peut modifier un ID de commande/session/paiement ou un tenant slug si le backend fait confiance au client.

Exploit Scenario: un utilisateur authentifie remplace `orderId` dans `/orders/{id}` ou `/payments/confirm`, ou modifie `X-Tenant-Slug`, pour tenter d'acceder a une ressource d'un autre utilisateur/tenant.

Business Impact: fuite de donnees personnelles, commandes visibles par un autre client, fuite inter-tenant, erreur de facturation, incident RGPD.

Recommended Fix: auditer `api-pizza` endpoint par endpoint : ownership, tenant scope, role, session ownership, payment ownership. Toute ressource privee manipulee doit retourner `403/404`.

Example Fix or Implementation Direction: tests backend negatifs pour chaque endpoint prive : user A ne peut pas lire commande B, tenant A ne peut pas acceder a tenant B, session B ne peut pas etre revoquee par A, paiement B ne peut pas etre confirme par A.

Estimated Effort: 2-4 jours.

Production Blocker: Yes.

### Validation finale de paiement Stripe et webhooks Unknown

Severity: Critical

Priority: P0

Affected Area: payments, Stripe, order/payment consistency.

Evidence: le client cree un intent via `/payments/intent` (`lib/features/payment/repositories/payment_repository.dart:26-31`), initialise PaymentSheet avec `paymentIntentClientSecret` (`lib/features/payment/services/stripe_payment_sheet_client.dart:37-45`), puis appelle `/payments/confirm` avec `provider_payment_id` (`lib/features/payment/repositories/payment_repository.dart:43-48`) apres `presentPaymentSheet` (`lib/features/payment/providers/payment_provider.dart:81-82`). Aucun endpoint webhook n'existe dans `app-client/`, donc signature Stripe, anti-replay et source finale du statut paiement sont hors perimetre et Unknown.

Risk: si le backend fait confiance a la confirmation client ou ne verifie pas Stripe, un paiement peut etre marque paye alors que le statut Stripe, le montant, la devise, l'ordre ou le tenant ne correspondent pas.

Exploit Scenario: appel direct a `/payments/confirm` avec un `provider_payment_id` manipule, replay d'un webhook Stripe ou double traitement d'un evenement.

Business Impact: commandes liberees sans paiement valide, double finalisation, litiges, pertes financieres, rapprochement comptable unreliable.

Recommended Fix: backend : verifier PaymentIntent Stripe cote serveur, montant/devise/order/tenant/user, transitions d'etat, signature webhook sur raw body, idempotence par event id, replay sans double effet. Le webhook Stripe doit etre la source finale du statut paye.

Example Fix or Implementation Direction: tests Stripe CLI/staging : signature invalide rejetee, body modifie rejete, meme event rejoue sans double effet, PaymentIntent d'un autre tenant/order refuse.

Estimated Effort: 1-3 jours.

Production Blocker: Yes.

### Pipeline CI/CD et scans non prouves

Severity: High

Priority: P1

Affected Area: cloud/deployment security, dependency security, release integrity.

Evidence: la CI root existe et utilise `working-directory: app-client` (`.github/workflows/app-client-ci.yml:25`), OSV (`.github/workflows/app-client-ci.yml:64`), Gitleaks (`.github/workflows/app-client-ci.yml:82`) et builds release (`.github/workflows/app-client-ci.yml:149`, `:214`). Cependant `flutter --version`, `dart --version`, `osv-scanner --version` et `gitleaks version` echouent dans ce shell. De plus `git status --short -- .github/workflows/app-client-ci.yml .github/dependabot.yml` retourne des fichiers `??`, donc la CI n'est pas encore prouvee comme versionnee/activee dans le depot.

Risk: un code non analyse, non teste, vulnerable ou contenant un secret peut etre livre si la CI n'est pas effective dans le depot distant.

Exploit Scenario: un commit ajoute une dependance vulnerable ou un fichier de secret ; le workflow n'etant pas actif ou pas vert, l'anomalie n'est pas bloquee avant release.

Business Impact: fuite de secrets, build release invalide, vulnerabilite supply chain, impossibilite de produire une preuve d'audit.

Recommended Fix: committer/activer la CI au root Git effectif, executer un run GitHub Actions vert, archiver logs et artefacts, traiter toute alerte OSV/Gitleaks.

Example Fix or Implementation Direction: branch protection exigeant `Format, Analyze, Test`, OSV, Gitleaks, build Android/iOS avant merge/release.

Estimated Effort: 0.5-1 jour hors resolution d'alertes.

Production Blocker: Yes for production evidence.

### Firebase production, FCM et App Check non verifies

Severity: High

Priority: P1

Affected Area: Firebase, push notifications, mobile platform configuration.

Evidence: Firebase est initialise seulement si `FirebaseEnvOptions.currentPlatform` retourne une config (`lib/main.dart:37-39`, `lib/core/config/firebase_env_options.dart:9-21`). La release exige plusieurs valeurs Firebase (`lib/core/config/env.dart:262-275`) et FCM demande la permission puis enregistre un token via `/notifications/devices` (`lib/features/tracking/services/push_notification_service.dart:33`, `:69-92`). Aucun `FirebaseAppCheck`, regle Firebase, preuve console, certificat APNs ou test appareil n'est present dans `app-client/`.

Risk: mauvais projet Firebase, mauvais package/bundle id, token push non delivre, notification mal routee ou absence d'attestation contre l'abus des endpoints publics.

Exploit Scenario: build production pointe vers un projet Firebase non attendu ou un attaquant automatise des appels backend si aucun mecanisme d'attestation/verrouillage serveur n'existe.

Business Impact: notifications client perdues ou envoyees au mauvais environnement, tracking degrade, cout/abus backend, confiance utilisateur reduite.

Recommended Fix: valider console Firebase par environnement, package Android, bundle iOS, APNs, FCM, VAPID web si publie ; activer App Check seulement si backend/Firebase verifient les tokens.

Example Fix or Implementation Direction: tests appareils reels : permission, token, refresh token, notification ouvrant uniquement `/orders/<id>/tracking`, requete sans App Check refusee si App Check est declare applicable.

Estimated Effort: 0.5-2 jours selon acces Firebase/Apple.

Production Blocker: Yes for push-enabled release.

## 5. Detailed Findings By Domain

### Authentication

Problem: bonne hygiene client, mais securite JWT/session backend Unknown.

Evidence: access token en memoire (`lib/core/providers/auth_token_provider.dart:10`), refresh token sauvegarde en secure storage (`lib/features/auth/repositories/auth_repository.dart:51`, `:86`), refresh automatique sur 401 (`lib/core/api/api_client.dart:135-144`), logout efface localement le storage meme si POST echoue (`lib/features/auth/repositories/auth_repository.dart:146-152`). La validation signature/exp/audience/revocation JWT est hors `app-client/`.

Risk: JWT forge, expire ou revoque accepte si backend mal configure ; session volee exploitable jusqu'a expiration/revocation serveur.

Fix: tests backend sur tokens expires, invalides, mauvais tenant, refresh revoque, logout/change-password.

Priority: P1.

### Authorization

Problem: la protection route Flutter ne vaut pas autorisation.

Evidence: `protectedPrefixes` redirige checkout/payment/orders/account/loyalty vers login (`lib/core/router/app_router.dart:74-86`). `SessionActions.revoke` peut appeler la revocation de n'importe quel `sessionId` fourni (`lib/features/account/providers/account_provider.dart:38-43`) ; le commentaire indique que le blocage de la session courante est UI, pas provider (`lib/features/account/providers/account_provider.dart:29-35`).

Risk: IDOR sur commandes, sessions, paiements si le backend ne controle pas l'ownership.

Fix: backend doit refuser toute ressource non possedee ; ajouter tests API directes.

Priority: P0 produit.

### API Security

Problem: client API structure, mais controles serveur Unknown.

Evidence: timeouts Dio (`lib/core/api/api_client.dart:44-48`), Bearer header (`lib/core/api/api_client.dart:119-122`), refresh 401 (`lib/core/api/api_client.dart:135-144`), tenant header (`lib/core/api/api_client.dart:108`). Les erreurs backend `detail` peuvent etre reprises comme message utilisateur (`lib/core/api/api_client.dart:212-255`).

Risk: absence eventuelle de rate limit, validation serveur, CORS explicite, body size limit, ou messages backend trop detailles.

Fix: tester backend sur validation negative, rate limiting login/register/reset/payment, erreurs sans stack trace/secret, CORS prod explicite.

Priority: P1.

### Database

Problem: aucune base locale client ; securite DB backend Unknown.

Evidence: aucune dependance `sqflite`, Hive ou shared database dans `pubspec.yaml`; recherche locale ne trouve que `flutter_secure_storage`.

Risk: isolation schema, contraintes, transactions, backups et droits DB non prouvables depuis Flutter.

Fix: audit backend/migrations/DB tenant.

Priority: P1 hors perimetre.

### Storage

Problem: stockage token client durci, mais preuves appareils manquantes.

Evidence: Android `encryptedSharedPreferences` et `resetOnError` (`lib/core/auth/token_storage.dart:21-24`), iOS `first_unlock_this_device` et `synchronizable: false` (`lib/core/auth/token_storage.dart:26-28`), backup Android desactive (`android/app/src/main/AndroidManifest.xml:8-9`). Tests unitaires presents (`test/core/auth/token_storage_test.dart:8-22`) mais non executes localement.

Risk: persistance inattendue apres restore/reinstall, session utilisable apres logout si backend ne revoque pas.

Fix: executer tests Flutter en CI et tests appareils logout/reinstall/restore ; verifier revocation refresh serveur.

Priority: P2.

### Webhooks

Problem: aucun webhook dans `app-client/`, mais paiement production en depend.

Evidence: aucun endpoint serveur dans le client ; paiement client s'arrete a PaymentSheet + `/payments/confirm`.

Risk: replay, spoofing ou double effet Stripe si backend incomplet.

Fix: audit Stripe webhook backend.

Priority: P0 produit.

### AI Security

Problem: aucune fonctionnalite IA detectee.

Evidence: aucune dependance/provider/prompt/tool/RAG/endpoint IA detecte dans `app-client/`.

Risk: N/A.

Fix: N/A.

Priority: N/A.

### Secrets

Problem: pas de secret complet detecte, mais scan professionnel non execute.

Evidence: `config/dart-defines.production.example.json` contient des placeholders (`config/dart-defines.production.example.json:1-22`). `.gitignore` exclut `config/dart-defines.production.json`, fichiers Firebase, `android/key.properties`, keystores et `.env` (`.gitignore:33-51`). Les fichiers production sensibles testes n'existent pas localement : `dart-defines.production.json`, `key.properties`, `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`. `gitleaks` est absent du shell local.

Risk: fuite future de secret si CI non active ou fichier sensible ajoute hors gitignore.

Fix: Gitleaks bloquant en CI, revue secrets, aucune cle Stripe secrete/webhook/service account dans le client.

Priority: P1.

### Frontend

Problem: release guard solide ; quelques surfaces restent a durcir.

Evidence: `Env.validateForRelease()` est appele avant Firebase et Stripe (`lib/main.dart:31-44`). La release refuse HTTP/local, Stripe test, Google Pay test, tenant demo/dev/test/default, URLs legales non HTTPS et Firebase manquant (`lib/core/config/env.dart:213-275`). Les routes d'ordre/paiement convertissent les IDs en `int` et affichent un ecran neutre si invalide (`lib/core/router/app_router.dart:187-216`, `:266-277`). En revanche l'errorBuilder affiche `state.error` (`lib/core/router/app_router.dart:296-301`).

Risk: fuite de detail de routing en production, et headers web absents si la build web est publiee.

Fix: message generique pour `errorBuilder` en release ; config CSP/HSTS/frame-ancestors/referrer-policy cote hosting web si applicable.

Priority: P2.

### Backend

Problem: backend hors perimetre et globalement Unknown.

Evidence: README liste explicitement les points backend bloquants : isolation tenant, ownership, webhooks Stripe, idempotence paiement, reconciliation, logs (`README.md:128-136`). Le client ne peut pas verifier ces garanties.

Risk: les controles les plus critiques du produit peuvent manquer malgre un client durci.

Fix: audit complet `api-pizza` avec tests negatifs authz/tenant/payment/webhook.

Priority: P0 produit.

### Deployment

Problem: CI root configuree mais preuve distante absente.

Evidence: workflow root present avec format/analyze/test (`.github/workflows/app-client-ci.yml:44-53`), OSV (`:64`), Gitleaks (`:82`), signing Android (`:117-125`) et builds release (`:149`, `:214`). Les outils locaux Flutter/Dart/OSV/Gitleaks sont absents, et les fichiers `.github/...` sont `??` dans le statut git local.

Risk: controles non executes avant release, secrets CI manquants, artefacts non signes ou non reproductibles.

Fix: committer/activer workflow root, branch protection, run vert archive.

Priority: P1.

### Dependencies

Problem: lockfile et automation presents, vulnerabilites non scannees localement.

Evidence: dependances critiques : `flutter_stripe` (`pubspec.lock:417-424`), `firebase_messaging` (`pubspec.lock:308-315`), `flutter_secure_storage` (`pubspec.lock:369-376`), `dio` (`pubspec.lock:244-251`). Dependabot Pub/root configure (`.github/dependabot.yml:1-10`). OSV local impossible car commande absente.

Risk: dependance vulnerable ou action CI compromise non detectee.

Fix: OSV vert, Dependabot actif, mise a jour des vulnerabilites Critical/High ; optionnellement pinning SHA des actions sensibles.

Priority: P1.

### Privacy

Problem: presence de liens legaux, mais politique RGPD non prouvee.

Evidence: URLs privacy/terms exigees en release (`lib/core/config/env.dart:255-259`) et routes legales presentes (`lib/core/router/app_router.dart:122-130`). L'ecran legal affiche l'URL ou `Non configure` (`lib/features/legal/screens/legal_document_screen.dart:23-51`). Aucune preuve d'export, suppression, retention ou DPA fournisseurs dans `app-client/`.

Risk: non-conformite RGPD et manque de droits utilisateur malgre collecte d'adresses, telephone, commandes et push tokens.

Fix: valider contenu legal, consentement push, retention, suppression/export compte cote backend.

Priority: P1.

### Logging

Problem: redaction locale presente, mais monitoring production non branche.

Evidence: `ErrorReporting.reporter` vaut `DebugPrintErrorReporter` en debug et `NoopErrorReporter` en release (`lib/core/monitoring/error_reporter.dart:13-14`). Le sanitizer redige tokens, email, secrets, PaymentIntent IDs et cles Firebase (`lib/core/monitoring/error_reporter.dart:79-160`). `main.dart` capture erreurs Flutter/platform/root zone (`lib/main.dart:16-55`). Aucune dependance Crashlytics/Sentry dans `pubspec.yaml`.

Risk: incidents auth/paiement/crash non visibles en production ; si un outil est ajoute sans redaction, fuite PII possible.

Fix: connecter Crashlytics/Sentry ou equivalent via `ErrorReporter`, verifier redaction en staging.

Priority: P2.

## 6. OWASP Mapping

| OWASP Category | Relevant Issues | Risk |
| -------------- | --------------- | ---- |
| A01 Broken Access Control | Guards UI seulement ; ownership/tenant backend Unknown | High |
| A02 Cryptographic Failures | HTTPS force en release ; secure storage durci ; crypto/JWT backend Unknown | Medium |
| A03 Injection | Pas de SQL/eval/shell client ; payload push filtre ; validation backend Unknown | Low/Unknown |
| A04 Insecure Design | Payment confirm client-triggered ; source finale webhook Unknown | High |
| A05 Security Misconfiguration | Release guard present ; Firebase/App Check/web headers non prouves | Medium |
| A06 Vulnerable Components | Lockfile + Dependabot + OSV CI ; scan non execute | Medium |
| A07 Auth Failures | Refresh client couvert ; JWT/revocation/rate limit backend Unknown | Medium |
| A08 Integrity Failures | CI/scans/builds configures mais non prouves ; actions non pinnees SHA | Medium/High |
| A09 Logging Failures | Redaction presente ; monitoring prod noop | Medium |
| A10 SSRF | Pas de fetch URL serveur dans client ; backend Unknown | Low/Unknown |

## 7. AI Security Assessment

No AI features detected.

## 8. Multi-Tenant Assessment

Tenant model : un build cible un tenant via `TENANT_SLUG`.

Isolation mechanism : cote client, `TENANT_SLUG` est envoye dans `X-Tenant-Slug`, le body login et la query WebSocket. Cote serveur : Unknown.

Weak points : toute valeur fournie par un client mobile peut etre manipulee hors app officielle. Le tenant slug n'est pas une preuve d'autorisation.

Cross-tenant risks : commandes, paiements, promotions, fidelite, sessions, branding et notifications peuvent fuiter si le backend ne scope pas chaque requete au tenant authentifie.

Required fixes : backend doit resoudre le tenant depuis une source fiable, verifier l'appartenance user/tenant, scoper chaque requete DB, et refuser toute ressource cross-tenant par `403/404`.

## 9. Webhook Assessment

No webhook endpoints detected.

Les webhooks Stripe sont hors `app-client/` et leur statut est Unknown. Une release paiement ne doit pas etre approuvee sans preuve backend de signature Stripe sur raw body, tolerance timestamp, idempotence event id, anti-replay, validation montant/devise/order/tenant/user et logs rediges.

## 10. Secrets Exposure Assessment

Committed secrets detected : aucun secret complet evident detecte par recherche locale de motifs courants ; les seules occurrences sont des noms de variables, placeholders ou documentation. Ce n'est pas equivalent a un scan Gitleaks execute.

Risky environment variables : les defaults dev existent (`API_BASE_URL` local, Stripe test placeholder, tenant `demo`, merchant Apple placeholder), mais `Env.validateForRelease()` les bloque en release.

Unsafe frontend exposure : les cles Stripe publishable et Firebase API keys sont exposees cote client par nature. Elles doivent rester restreintes par environnement/projet/package/bundle et ne jamais etre remplacees par des cles secretes serveur.

Missing `.env.example` : non bloquant pour Flutter ; le contrat production est `config/dart-defines.production.example.json`.

Recommended secret management : secrets uniquement dans CI/backend ; `config/dart-defines.production.json`, keystores, fichiers Firebase natifs, service accounts et webhook secrets non versionnes ; Gitleaks bloquant avant merge.

## 11. P0 — Must Fix Before Production

- Prouver backend authorization/ownership sur commandes, sessions, profil, fidelite, promotions privees et paiements.
- Prouver isolation tenant serveur ; ne jamais faire confiance a `X-Tenant-Slug` seul.
- Prouver Stripe webhooks signes, anti-replay et idempotents ; webhook comme source finale du statut paye.
- Prouver que `/payments/confirm` valide ownership, tenant, montant, devise, statut Stripe et statut commande.
- Activer une CI root verte et versionnee avant release.

## 12. P1 — High Priority Hardening

- Executer et archiver `flutter analyze --fatal-infos`, `flutter test --coverage`, builds Android/iOS release, OSV et Gitleaks.
- Verifier que tous les secrets GitHub Actions attendus par `.github/workflows/app-client-ci.yml` existent et sont masques.
- Valider Firebase/FCM/APNs sur appareils reels avec projet/package/bundle de production.
- Tester rate limiting backend sur login/register/forgot-password/payment/order.
- Valider privacy/legal : contenu, consentement push, retention, export et suppression compte.
- Corriger ou documenter toute vulnerabilite OSV Critical/High.

## 13. P2 — Security Improvements

- Brancher Crashlytics/Sentry ou equivalent via `ErrorReporter`, avec test de redaction.
- Remplacer l'affichage `state.error` du router par un message generique en release.
- Tester logout/reinstall/restore Android/iOS pour prouver l'effacement de session.
- Ajouter headers web si Flutter Web est publie : CSP, HSTS, frame-ancestors, referrer-policy, permissions-policy.
- Ajouter App Check seulement si backend/Firebase verifient reellement les tokens.
- Considerer certificate pinning seulement apres decision threat model mobile.

## 14. P3 — Nice Hardening

- Pinning SHA des actions GitHub critiques ou politique Dependabot stricte sur actions.
- Completer le runbook avec proprietaires, periodicite de rotation et preuve signee.
- Ajouter matrice dev/staging/prod pour API, Stripe, Firebase, tenant, package/bundle id.
- Ajouter tests de non-regression sur payload push, redaction telemetry, release guard et idempotency key.

## 15. Quick Wins

- Committer les fichiers root `.github/workflows/app-client-ci.yml` et `.github/dependabot.yml`, puis lancer un run CI.
- Supprimer le dossier vide `app-client/.github/workflows` ou documenter qu'il est volontairement vide.
- Ajouter un test release config avec toutes les valeurs Firebase platform-specific attendues.
- Remplacer en release l'erreur router detaillee par un texte neutre.
- Archiver une sortie Gitleaks/OSV redigee.
- Verifier manuellement que `config/dart-defines.production.json`, keystore Android et fichiers Firebase natifs ne sont pas suivis.

## 16. Suggested Security Tests

### Unit Tests

- Goal: bloquer les configs dangereuses en release.
  Scenario: `APP_ENV` non production, API HTTP/local, Stripe test, Google Pay test, tenant demo, Firebase incomplet, legal URLs non HTTPS.
  Expected result: `Env.releaseValidationErrors` retourne une erreur par controle.

- Goal: verifier stockage token.
  Scenario: inspecter options `TokenStorage.androidOptions` et `TokenStorage.iosOptions`.
  Expected result: chiffrement Android, reset on error, iOS device-local non synchronisable.

- Goal: verifier redaction telemetry.
  Scenario: contexte contenant email, Bearer, JWT, refresh token, PaymentIntent, Firebase key.
  Expected result: valeurs sensibles remplacees par `[redacted]`.

- Goal: verifier deep link push.
  Scenario: `order_id` absent, zero, negatif ou chaine path-like.
  Expected result: aucune route produite.

### Integration Tests

- Goal: refresh 401.
  Scenario: requete protegee retourne 401, refresh token present, `/auth/refresh` retourne un nouvel access token.
  Expected result: requete rejouee une seule fois avec nouveau Bearer et meme `X-Tenant-Slug`.

- Goal: creation commande idempotente.
  Scenario: deux tentatives apres timeout utilisent le meme `Idempotency-Key`.
  Expected result: backend retourne une seule commande.

- Goal: paiement retry.
  Scenario: PaymentSheet echoue puis retry.
  Expected result: le client reutilise le meme client secret, backend ne cree pas de second intent actif.

### End-to-End Tests

- Goal: parcours commande complet.
  Scenario: catalogue, login, panier, checkout, creation commande, PaymentSheet staging, historique, tracking.
  Expected result: commande visible uniquement par le bon utilisateur/tenant, aucun token dans les logs.

- Goal: Firebase appareil.
  Scenario: installation Android/iOS production-like, permission push, token FCM/APNs, notification order.
  Expected result: token enregistre, notification ouvre la bonne route, mauvais payload ignore.

### Authorization Tests

- Goal: IDOR commande.
  Scenario: user A appelle detail/paiement/tracking de commande B.
  Expected result: `403/404`.

- Goal: isolation tenant.
  Scenario: modifier `X-Tenant-Slug`, body `tenant_slug` ou query WebSocket vers un autre tenant.
  Expected result: acces refuse ou tenant ignore selon source d'autorite serveur.

- Goal: sessions.
  Scenario: user A tente de revoquer une session de user B.
  Expected result: `403/404`.

### Webhook Tests

- Goal: signature Stripe.
  Scenario: webhook sans signature, signature invalide, body modifie.
  Expected result: rejet.

- Goal: replay Stripe.
  Scenario: meme event valide envoye deux fois.
  Expected result: un seul effet metier.

- Goal: mapping paiement.
  Scenario: event reference un PaymentIntent d'un autre tenant/order/user.
  Expected result: aucune transition payee.

### AI Security Tests

N/A. Aucune fonctionnalite IA detectee.

### Regression Tests

- Goal: eviter retour de valeurs dev en release.
  Scenario: chercher Google Pay test, tenant demo, API locale, Stripe test, fichiers secrets commites.
  Expected result: aucun match dans code release actif ou echec release guard.

- Goal: eviter logs sensibles.
  Scenario: forcer erreurs auth/paiement/push en debug et en staging.
  Expected result: aucun token, email, adresse ou PaymentIntent complet dans traces.

## 17. Manual Penetration Test Scenarios

- Construire une release sans `dart-define` production : l'app doit echouer avant reseau/Firebase/Stripe.
- Construire avec `API_BASE_URL` local ou HTTP : l'app doit echouer.
- Construire avec Stripe test key ou Google Pay test en release : l'app doit echouer.
- Intercepter une requete API et modifier `X-Tenant-Slug` : backend doit refuser l'acces cross-tenant.
- Modifier `orderId` dans `/checkout/payment?orderId=...` : backend doit refuser si la commande n'appartient pas au user courant.
- Appeler `/payments/confirm` avec un `provider_payment_id` d'un autre ordre : backend doit refuser.
- Rejouer creation commande avec meme `Idempotency-Key` : une seule commande doit exister.
- Rejouer `/payments/intent` pour une commande pending : un seul intent actif doit etre conserve.
- Envoyer payload FCM avec `order_id` path-like/negatif : aucune navigation.
- Verifier logs pendant login, refresh, paiement, push : aucun token/PII/payment secret complet.
- Publier build web staging et scanner headers : CSP/HSTS/clickjacking/referrer doivent etre controles.

## 18. Final Verdict

`app-client/` a une base client correcte et nettement plus mature qu'un scaffold : release guard, secure storage, API centralisee, tests unitaires de securite, CI/scans configures et flux paiement via Stripe PaymentSheet.

Le projet complet n'est pas safe a deployer sans preuves externes. Le plus grand risque est de confondre les controles Flutter avec l'autorisation reelle : les donnees, tenants, commandes, sessions et paiements doivent etre proteges par le backend. Le premier travail a faire est donc de produire l'audit backend authz/tenant/payment/webhook, puis une CI root verte avec scans et artefacts.

Ce qui peut attendre : certificate pinning, App Check si non verifie serveur, headers web si aucune build web publique, pinning SHA des actions GitHub.

Chemin le plus court vers une release sure : committer/activer CI root, executer Flutter analyze/tests/builds + OSV/Gitleaks, valider Firebase/Stripe sur appareils/staging, auditer backend authz/tenant/JWT/payment/webhook, puis relancer `.claude/commands/audit-security.md` avec les preuves archivees.

Security decision: Not Production Ready
