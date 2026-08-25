# Feature Audit Report

Date d'audit : 2026-07-22
Périmètre : `app-client/`.

## 1. Executive Summary

Verdict: Core Features Broken

Le produit couvre bien les modules attendus d'une app de commande restaurant, mais le parcours utilisateur principal est bloqué au niveau UI : sur la fiche produit, le bouton "Ajouter au panier" n'ajoute rien au panier et affiche seulement un SnackBar. Les tests d'intégration contournent ce point en appelant directement `cartProvider.notifier.addItem`, donc ils ne valident pas encore le parcours utilisateur réel.

Les couches checkout, paiement, suivi, compte et fidélité montrent une vraie intention de production, mais plusieurs parcours restent partiellement vérifiés : PaymentSheet Stripe non testée en environnement natif, livraison par carte uniquement, config Firebase absente, build non exécuté localement car `flutter`/`dart` ne sont pas disponibles.

## 2. Project Context

Project type: application mobile Flutter de commande restaurant.

Business goal: commander et payer des pizzas/produits restaurant pour un tenant donné.

Target users: clients finaux.

Critical user journeys:

- Voir catalogue -> détail produit -> ajouter au panier.
- Panier -> checkout -> livraison/retrait -> commande.
- Commande -> paiement Stripe -> suivi.
- Login/register -> compte -> fidélité/promos.

Main modules: catalogue, panier, checkout, paiement, commandes, tracking, auth, compte, fidélité, promotions.

## 3. Feature Inventory

| Feature | Type | User | Status | Criticality | Score |
| ------- | ---- | ---- | ------ | ----------- | ----: |
| Catalogue public | Core | Client | Partiel, API et UI présentes | Haute | 6 |
| Détail produit | Core | Client | UI riche mais ajout panier non branché | Critique | 2 |
| Panier local | Core | Client | Provider et écran présents | Critique | 6 |
| Checkout | Core | Client | Revalidation, retrait/livraison, idempotency | Critique | 6 |
| Paiement Stripe | Core | Client | PaymentSheet présente, native non validée | Critique | 5 |
| Auth client | Core | Client | Login/register/forgot + token flow | Haute | 6 |
| Commandes/historique | Important | Client | Providers, écrans, pagination | Haute | 6 |
| Tracking WebSocket | Important | Client | WS + polling fallback | Haute | 6 |
| Promotions | Important | Client | Liste + validation panier | Moyenne | 5 |
| Fidélité | Important | Client | Solde, récompenses, transactions | Moyenne | 5 |
| Compte/sessions | Important | Client | Profil, mot de passe, révocation session | Moyenne | 6 |
| Push notifications | Secondary | Client | Service FCM présent | Moyenne | 4 |
| Web/PWA | Secondary | Client | Scaffold web par défaut | Basse | 3 |

## 4. Critical User Journeys

### Catalogue -> Panier

Flow: Home/catalogue -> ProductCard -> ProductDetailScreen -> bouton "Ajouter au panier" -> cartProvider -> CartScreen.

Expected behavior: le produit, variante, extras et quantité choisis doivent être ajoutés au panier.

Observed behavior: `ProductDetailScreen` ligne 107 contient `TODO Plan 09`; `onAddToCart` affiche `Ajouté au panier (Plan 09)` mais n'appelle pas `cartProvider.notifier.addItem`.

Issues: parcours d'achat bloqué pour un utilisateur réel.

Verdict: Fail.

### Panier -> Checkout -> Commande

Flow: panier local -> `/checkout` -> auth si nécessaire -> revalidation -> mode livraison/retrait -> `POST /orders`.

Expected behavior: commande créée avec données validées, idempotency et erreurs claires.

Observed behavior: provider et tests couvrent revalidation, retrait, hors zone, idempotency. Le test d'orchestration ajoute toutefois directement au provider.

Issues: dépend du P0 ajout panier ; livraison par carte tap-only ; test UI incomplet.

Verdict: Partial.

### Commande -> Paiement -> Suivi

Flow: orderId -> `PaymentScreen` -> PaymentIntent -> PaymentSheet Stripe -> `/payments/confirm` -> panier vidé -> tracking.

Expected behavior: paiement natif fiable, pas de double intent, redirection suivi.

Observed behavior: PaymentProvider réutilise clientSecret en mémoire, confirme via `provider_payment_id`, vide le panier. Tests déclarent que Stripe natif n'est pas exercé.

Issues: PaymentSheet non validée localement, Google Pay `testEnv: true`, backend webhook hors audit.

Verdict: Partial.

### Auth et Compte

Flow: login/register/forgot -> token -> compte/profil/sessions.

Expected behavior: accès protégé, refresh token, erreurs utilisateur.

Observed behavior: route guard, secure storage, tests repository/widgets.

Issues: interceptor refresh difficilement testable car `ApiClient` instancie son propre Dio/TokenStorage ; backend auth non vérifié ici.

Verdict: Partial.

## 5. Functional Findings

### Le bouton ajouter au panier ne modifie pas le panier

Priority: P0

Feature: catalogue / détail produit / panier.

Problem: le CTA critique indique un succès mais ne déclenche pas l'ajout.

Evidence: `lib/features/catalog/screens/product_detail_screen.dart:107` TODO, `:110` SnackBar ; `test/integration/golden_path_test.dart:96` ajoute directement au provider.

User Impact: l'utilisateur ne peut pas démarrer une commande depuis l'UI normale.

Business Impact: conversion impossible, coeur business bloqué.

Technical Cause: `ProductDetailScreen` n'importe pas `cartProvider` et ne construit pas l'appel `addItem(product, quantity, variant, extraIds)`.

Recommended Fix: brancher `onAddToCart` sur `cartProvider.notifier.addItem`, résoudre variante/extras sélectionnés, puis tester le widget.

Estimated Effort: 1-2 h.

Production Risk: blocker.

### Build probablement bloqué par Firebase options absentes

Priority: P0

Feature: démarrage app / notifications.

Problem: `main.dart` importe `firebase_options.dart` et utilise `DefaultFirebaseOptions`, mais le fichier généré n'est pas présent.

Evidence: `lib/main.dart:10-11`, `:23`; recherche `firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist` sans résultat.

User Impact: l'app risque de ne pas compiler ou démarrer.

Business Impact: impossible de livrer un binaire fiable.

Technical Cause: configuration FlutterFire non générée/committée ou non reconstruite en CI.

Recommended Fix: générer les configs Firebase par environnement ou conditionner l'initialisation.

Estimated Effort: 1/2-1 jour selon comptes Firebase.

Production Risk: blocker.

### Les tests d'intégration ne couvrent pas le parcours UI réel

Priority: P1

Feature: checkout / paiement.

Problem: le golden path est au niveau providers, pas widgets/app réelle.

Evidence: `test/integration/golden_path_test.dart` documente que Stripe et la carte sont hors périmètre ; l'ajout panier est direct via provider.

User Impact: bugs UI critiques non détectés.

Business Impact: faux sentiment de couverture.

Technical Cause: manque de widget/E2E tests pour catalogue -> panier -> checkout.

Recommended Fix: ajouter tests widget pour ProductDetailScreen et tests intégrés avec repositories mockés à travers la navigation.

Estimated Effort: 1-2 jours.

Production Risk: high.

### Livraison peu ergonomique pour usage réel

Priority: P1

Feature: checkout livraison.

Problem: l'adresse de livraison exige un tap sur carte ; le texte adresse est informatif et aucun géocodage n'est disponible.

Evidence: `lib/features/checkout/screens/steps/step_address.dart`.

User Impact: erreurs de localisation, UX faible pour clavier/screen reader/mobile.

Business Impact: livraisons mal placées ou abandons.

Technical Cause: absence de geocoding/places et validation adressée limitée.

Recommended Fix: MVP acceptable en démo, mais production devrait ajouter recherche adresse, confirmation du point et fallback.

Estimated Effort: 1-3 jours.

Production Risk: high.

## 6. Feature Scores

| Feature | Score /10 | Reason |
| ------- | --------: | ------ |
| Catalogue | 6 | API/UI présentes, mais ajout panier bloqué |
| Panier | 6 | Provider solide, entrée utilisateur manquante depuis détail produit |
| Checkout | 6 | Bonne logique provider, UX livraison limitée |
| Paiement | 5 | Implémenté, non validé en natif/prod |
| Auth | 6 | Flux présents, refresh interceptor peu testable |
| Commandes/tracking | 6 | WebSocket/polling présents, dépend du backend |
| Promotions/fidélité | 5 | Présents, tests partiels |
| Compte | 6 | Fonctionnel côté code, backend non vérifié |

Global Functional Score:

4 / 10

## 7. P0 - Production Blockers

- Brancher réellement "Ajouter au panier" depuis `ProductDetailScreen`.
- Résoudre la configuration Firebase manquante avant build/runtime.

## 8. P1 - High Priority Fixes

- Ajouter tests widget/E2E du parcours catalogue -> panier -> checkout.
- Valider Stripe PaymentSheet sur plateforme native avec clés test réelles.
- Remplacer `googlePay.testEnv: true` par une config dépendante de l'environnement.
- Améliorer l'adresse livraison ou limiter explicitement le lancement à retrait/démo.

## 9. P2 - Improvements

- Documenter la compatibilité backend/API par version.
- Ajouter analytics de funnel commande.
- Ajouter état de succès post-commande plus explicite.
- Nettoyer commentaires TODO/stale qui contredisent l'état actuel.

## 10. P3 - Nice To Have

- ASO/PWA metadata.
- Polissage empty states promotions/fidélité.
- Tests de screenshots/golden UI.

## 11. Quick Wins

- Importer `cartProvider` dans `ProductDetailScreen` et appeler `addItem`.
- Ajouter un test widget qui vérifie que le compteur panier augmente.
- Faire échouer le démarrage si `STRIPE_PUBLISHABLE_KEY` vaut `pk_test_REPLACE_ME` en release.
- Mettre à jour le README avec commandes build/test/env.

## 12. Missing Tests

Unit tests:

- Résolution variante/extras vers `CartItem`.
- Validation environnement release.

Integration tests:

- Interceptor 401 avec Dio injectable.
- Payment intent retry et confirmation avec repository mocké.

End-to-end tests:

- Catalogue -> détail -> ajout panier -> checkout.
- Checkout livraison avec point carte.
- Paiement Stripe test sur device/simulator.

Regression tests:

- Le bouton "Ajouter au panier" ne doit jamais afficher succès sans modifier le panier.

AI evaluation tests:

- Non applicable.

## 13. Suggested Manual QA Scenarios

### Ajouter un produit au panier

Precondition: backend catalogue mocké ou disponible.

Steps: ouvrir accueil, ouvrir un produit, choisir variante/extras, cliquer ajouter, aller au panier.

Expected result: item présent avec quantité/prix corrects.

Risk covered: P0 conversion.

### Checkout retrait

Precondition: panier non vide, utilisateur connecté.

Steps: checkout, choisir retrait, confirmer commande.

Expected result: orderId créé, navigation paiement.

Risk covered: commande sans livraison.

### Paiement test

Precondition: clés Stripe test et backend test.

Steps: ouvrir paiement, payer avec carte test 3DS, vérifier suivi.

Expected result: paiement confirmé, panier vidé, suivi accessible.

Risk covered: paiement et synchronisation.

## 14. Final Verdict

Des utilisateurs réels ne peuvent pas utiliser le coeur du produit aujourd'hui : le bouton principal d'ajout panier ne fait pas l'action attendue. Les modules internes sont prometteurs et plusieurs providers sont testés, mais la production doit attendre la correction du P0, une validation Firebase/build et une couverture UI minimale du parcours d'achat.

Feature decision: Core Features Broken.
