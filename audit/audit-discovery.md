# Project Discovery Report

Date d'audit : 2026-07-22
Périmètre : `app-client/` uniquement.

## 1. Executive Summary

`app-client` est une application Flutter client pour O'Pizza : consultation du catalogue, panier, tunnel de commande, paiement Stripe, compte client, fidélité, promotions, historique et suivi temps réel. Elle consomme le backend `api-pizza` via `Dio`, avec un header tenant `X-Tenant-Slug`, des JWT Bearer, Firebase Messaging et un canal WebSocket.

Le projet est plus avancé qu'un scaffold Flutter : 90 fichiers Dart sous `lib/`, 19 fichiers de tests sous `test/`, des providers Riverpod, des repositories API et une CI GitHub Actions. En revanche, plusieurs éléments de production restent incomplets ou inconnus : configuration Firebase absente du dépôt inspecté, documentation README encore générique, configuration release Android signée avec la clé debug, variables de compilation par défaut dev/test.

## 2. Project Type

Primary: Mobile App / E-commerce local de commande restaurant.

Secondary: Flutter Web/PWA possible, client multi-tenant par build.

Confidence: 8 / 10.

## 3. Business Goal

Permettre aux clients d'un restaurant/pizzeria de consulter le menu, composer un panier, créer une commande en retrait ou livraison, payer via Stripe, suivre l'état de la commande et utiliser des promotions/fidélité.

## 4. Target Users

- Clients finaux de restaurants/pizzerias.
- Restaurants/tenants via une build configurée par `TENANT_SLUG`.
- Equipe opérationnelle en dépendance indirecte du backend `api-pizza`.

## 5. Tech Stack

Frontend: Flutter >= 3.22, Dart >= 3.4, Material 3.

State/navigation: Riverpod, riverpod_generator, go_router.

Backend: API externe `api-pizza` en HTTP/JSON, non auditée ici.

Database: Non présente côté client ; données persistantes côté backend.

Infrastructure: GitHub Actions pour format/analyze/test/build Android/iOS.

Authentication: JWT access token en mémoire, refresh token via `flutter_secure_storage`.

Payments: `flutter_stripe`, PaymentSheet, Apple Pay/Google Pay configurés côté client.

Notifications/realtime: Firebase Messaging, WebSocket via `web_socket_channel`.

Maps: `flutter_map`, OpenStreetMap tiles, sélection manuelle d'un point de livraison.

AI: Aucune fonctionnalité AI détectée.

Monitoring: Aucun Sentry/Crashlytics/Firebase Performance détecté.

## 6. Architecture

Architecture client modulaire par features :

Client Flutter
-> Riverpod providers / state notifiers
-> Repositories
-> `ApiClient` Dio
-> Backend `api-pizza`
-> Stripe / Firebase / WebSocket selon les parcours

Modules détectés :

- `core/api` : client HTTP, endpoints, gestion erreurs.
- `core/auth` : stockage refresh token.
- `core/router` : routes publiques/protégées.
- `core/theme` : thème tenant dynamique.
- `features/auth` : login, register, forgot password.
- `features/catalog` : accueil, catégories, recherche, détail produit.
- `features/cart` : panier local, promos, preview fidélité.
- `features/checkout` : revalidation panier, livraison/retrait, création commande.
- `features/payment` : PaymentSheet Stripe.
- `features/orders` : historique, détail, recommander.
- `features/tracking` : suivi WebSocket + polling.
- `features/account` : profil, mot de passe, sessions.
- `features/loyalty` et `features/promotions`.

## 7. Main Features

- Branding tenant au splash.
- Catalogue public, recherche et filtres allergènes.
- Détail produit avec variantes, extras, quantité.
- Panier local avec code promo et preview fidélité pour utilisateurs connectés.
- Auth inline dans le checkout.
- Livraison par sélection de point sur carte ou retrait.
- Création de commande avec `Idempotency-Key`.
- Paiement Stripe avec PaymentSheet.
- Historique commandes, détail, suivi temps réel par WebSocket, polling fallback.
- Gestion compte, sessions, changement mot de passe.
- Notifications push via Firebase Messaging.

## 8. User Journey

Splash et chargement branding
-> catalogue
-> détail produit
-> ajout panier
-> panier
-> checkout avec auth si nécessaire
-> revalidation prix/disponibilité
-> retrait ou livraison
-> création commande
-> paiement Stripe
-> suivi commande
-> historique/compte/fidélité.

## 9. Deployment Context

Le contexte exact de déploiement n'est pas documenté dans `README.md`. Les indices observés :

- CI Android : `flutter build apk --release` avec secrets `API_BASE_URL`, `STRIPE_PUBLISHABLE_KEY`, `TENANT_SLUG`.
- CI iOS : `flutter build ios --no-codesign`.
- Web présent, mais `web/index.html` et `web/manifest.json` gardent les valeurs Flutter par défaut.
- Aucune config `.env.example`, runbook mobile, store release checklist, Firebase config générée, privacy/terms ou monitoring détectés.
- `flutter` et `dart` ne sont pas disponibles dans le PATH local de cette session, donc aucune validation locale build/test/analyze n'a pu être exécutée.

## 10. Risks

- `lib/main.dart` importe `firebase_options.dart`, mais le fichier n'a pas été trouvé dans `app-client/`; build/runtime probablement bloqué sans génération FlutterFire.
- Le bouton "Ajouter au panier" du détail produit affiche un SnackBar mais ne modifie pas `cartProvider`.
- Les valeurs par défaut de `Env` pointent vers `http://10.0.2.2:8000`, `pk_test_REPLACE_ME`, `TENANT_SLUG=demo`, merchant Apple placeholder.
- Android release utilise la signature debug.
- README encore scaffold Flutter, peu utile pour production.
- Tests existants utiles mais principalement provider/unit, sans vraie exécution Stripe/Firebase/carte ni E2E UI.

## 11. Missing Information

- Plateforme cible prioritaire : Android, iOS, web ou les trois.
- Environnement de production réel et stratégie de secrets.
- Existence de configs Firebase hors dépôt.
- Politique stores, signature Android/iOS, App Store/Play Store.
- Monitoring/crash reporting.
- Politique RGPD, privacy, suppression/export de données côté produit.
- Résultats réels de `flutter analyze`, `flutter test`, `flutter build`.
- Contrôles backend réels pour auth, tenant, paiement et webhooks.

## 12. Confidence Score

Project understanding:

8 / 10

La structure, les routes, les repositories et les tests permettent une bonne compréhension du client. La confiance ne monte pas plus haut car le backend, les secrets de CI, Firebase et les builds réels ne sont pas vérifiables depuis cette session.

Discovery confidence: 8 / 10.
