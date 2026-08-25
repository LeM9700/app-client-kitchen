# Accessibility Audit Report

Date d'audit : 2026-07-22
Périmètre : revue code `app-client/`; aucune validation manuelle TalkBack/VoiceOver/clavier exécutée.

## 1. Executive Summary

Verdict: Not Production Ready

L'application bénéficie d'une base Material/Flutter avec labels visibles, formulaires `TextFormField`, boutons natifs et quelques tooltips. Mais plusieurs parcours critiques restent risqués ou bloquants pour l'accessibilité : composants interactifs en `GestureDetector`, sélection d'adresse uniquement par tap sur carte, spinners/status sans annonce explicite, icon buttons sans noms accessibles visibles partout, absence de tests a11y, web HTML sans `lang`.

Le verdict ne prétend pas une non-conformité WCAG complète ; il indique que la production ne doit pas être approuvée sans corrections et validation manuelle. Requires manual validation.

## 2. Project Context

Project type: app Flutter mobile de commande restaurant, web/PWA possible.

Target users: clients finaux, potentiellement grand public.

Public/private status: client public si publié stores/web.

France/RGAA relevance: contexte français probable (`FR`, euros, RGPD) ; RGAA strict seulement si secteur public/marché public, non établi.

Critical user journeys: catalogue, panier, checkout, paiement, suivi, compte.

Frontend framework: Flutter Material 3.

UI library/design system: composants Material + widgets custom.

Mobile relevance: forte.

Admin/SaaS relevance: non côté client.

AI features: aucune.

## 3. Accessibility Scorecard

| Category | Score /10 | Status |
| -------- | --------: | ------ |
| Semantic HTML | 3 | Flutter web générique, `lang` absent |
| Keyboard Navigation | 4 | Risques `GestureDetector` et carte |
| Focus Management | 4 | Non validé, dialogs natifs partiels |
| Screen Reader Support | 4 | Peu de `Semantics`/labels explicites |
| ARIA Quality | N/A | Flutter, pas ARIA direct |
| Color & Contrast | 5 | Thème clair, contrastes non mesurés |
| Forms | 6 | Labels/validators présents, annonces inconnues |
| Navigation | 6 | NavigationBar + tooltips, route focus inconnu |
| Modals & Overlays | 5 | AlertDialog natif, focus non validé |
| Tables & Data Grids | N/A | Pas de table critique |
| Mobile Accessibility | 4 | Tap targets probables, carte/tap-only risquée |
| SaaS/Admin Accessibility | N/A | Non applicable |
| AI Feature Accessibility | N/A | Pas d'AI |
| Error & Status Feedback | 4 | SnackBars/spinners non annoncés explicitement |
| Cognitive Accessibility | 6 | Texte globalement clair |
| Automated Testing | 1 | Aucun test a11y détecté |
| RGAA Readiness | 3 | Non prêt pour audit formel |

Global Accessibility Score:

4.5 / 10

## 4. Critical User Journey Accessibility

### Catalogue -> Panier

Flow: catalogue -> carte produit -> détail -> variantes/extras/quantité -> ajouter.

Keyboard Usability: Risky ; plusieurs cartes/selecteurs utilisent `GestureDetector`.

Screen Reader Usability: Unknown/Risky ; peu de `Semantics`, images/états non systématiquement labellisés.

Mobile Accessibility: Risky ; bouton panier non fonctionnel côté feature, composants custom à valider.

Error Recovery: faible sur ajout panier car succès visuel faux.

Observed or Inferred Barriers: `ProductCard`, `CategoryChip`, `VariantSelector`, recommandations en `GestureDetector`.

Verdict: Risky.

Recommended Fixes: utiliser `InkWell`/Material avec semantics ou ajouter `Semantics(button: true, label: ...)`, tester TalkBack/VoiceOver.

### Checkout Livraison

Flow: choisir livraison -> placer point carte -> vérifier zone -> récap.

Keyboard Usability: Blocked/Risky ; action principale exige `FlutterMap.onTap`.

Screen Reader Usability: Risky ; pas d'alternative textuelle permettant de saisir/confirmer coordonnées.

Mobile Accessibility: Risky ; précision du tap et zoom non validés.

Error Recovery: message SnackBar si aucun point.

Observed or Inferred Barriers: carte tap-only, champ adresse informatif seulement.

Verdict: Blocked for some users.

Recommended Fixes: ajouter recherche/saisie adresse accessible ou alternative latitude/longitude/choix retrait clair.

### Auth / Compte

Flow: login/register/forgot/profile/password.

Keyboard Usability: Mostly Accessible via `TextFormField`/buttons natifs.

Screen Reader Usability: Unknown ; erreurs en SnackBar/champs pas forcément annoncées ou associées.

Mobile Accessibility: Mostly Accessible.

Error Recovery: validators présents.

Verdict: Mostly Accessible, manual validation required.

### Paiement

Flow: PaymentScreen -> Stripe PaymentSheet.

Keyboard Usability: Unknown native.

Screen Reader Usability: Unknown, dépend SDK Stripe.

Mobile Accessibility: Unknown.

Verdict: Unknown.

## 5. Findings By Domain

Keyboard:

Problem: plusieurs interactions utilisent `GestureDetector` avec `onTap`.

Evidence: `category_chip.dart`, `variant_selector.dart`, `product_card.dart`, `recommended_products_row.dart`, `step_delivery_mode.dart`, promotions/order tiles.

Impact: activation clavier/focus/role button non garantis.

Fix: préférer `InkWell`/`ListTile`/`ChoiceChip` ou ajouter `Semantics` + focus/keyboard actions.

Priority: P1.

Screen reader:

Problem: très peu de `Semantics`/`semanticLabel` détectés.

Evidence: recherche `Semantics(` et `semanticLabel` sans occurrences pertinentes ; nombreux `IconButton`/images.

Impact: actions, images produits, états sélectionnés peuvent être mal compris.

Fix: labels explicites, états sélectionnés, descriptions d'images utiles.

Priority: P1.

Forms:

Problem: labels visibles et validators existent, mais erreurs ne sont pas reliées programmatiquement et sont souvent en SnackBar.

Evidence: login/register/checkout/profile/password utilisent `TextFormField` + `validator`, SnackBars pour erreurs API.

Impact: screen reader peut ne pas annoncer l'erreur au bon champ.

Fix: messages sous champ, focus premier champ invalide, tests TalkBack/VoiceOver.

Priority: P2.

Modals:

Problem: `AlertDialog` natif utilisé, mais focus retour/trap non validés.

Evidence: dialogs sessions, compte, commandes, fidélité.

Impact: risque clavier/screen reader sur confirmations.

Fix: validation manuelle et titres/actions explicites.

Priority: P2.

Mobile:

Problem: delivery par carte uniquement.

Evidence: `StepAddress` demande "Touchez la carte" et lit `onTap`.

Impact: utilisateurs moteur/lecteur d'écran peuvent être bloqués.

Fix: alternative accessible.

Priority: P0/P1 selon lancement livraison.

Web:

Problem: `web/index.html` n'a pas `lang`, title/description génériques.

Evidence: `<html>` sans `lang`, `title app_client`, description "A new Flutter project."

Impact: accessibilité/langue et SEO faibles si web public.

Fix: `lang="fr"`, title/description, landing web si nécessaire.

Priority: P2.

## 6. WCAG 2.2 Mapping

| WCAG Area | Relevant Issues | Risk |
| --------- | --------------- | ---- |
| Perceivable | images/status/spinners sans labels/annonces garanties | Medium |
| Operable | `GestureDetector`, carte tap-only, focus non validé | High |
| Understandable | checkout carte peu clair pour certains utilisateurs | Medium |
| Robust | Flutter semantics non explicités/testés | Medium |

Criterion mapping requires manual validation.

## 7. RGAA Assessment If Relevant

RGAA readiness verdict: audit partiellement prêt, pas conforme déclarable.

Likely high-risk themes: navigation clavier, scripts/widgets custom Flutter web, formulaires, couleurs, éléments obligatoires, langue, alternatives à la carte.

Missing declaration elements: pas de déclaration accessibilité, pas d'échantillon d'audit, pas de tests documentés.

Limitation: un audit RGAA complet ne peut pas être conclu depuis le code seul.

## 8. P0 - Must Fix Before Production

- Si la livraison est lancée publiquement, fournir une alternative accessible à la sélection de point par carte. Sinon limiter clairement le périmètre à retrait ou démo.

## 9. P1 - High Priority Fixes

- Remplacer/compléter les `GestureDetector` critiques par des composants accessibles.
- Ajouter labels sémantiques aux icon buttons/selecteurs/états sélectionnés.
- Tester manuellement catalogue -> panier -> checkout avec TalkBack/VoiceOver.
- Vérifier Stripe PaymentSheet avec lecteurs d'écran natifs.

## 10. P2 - Improvements

- Ajouter `lang="fr"` et metadata web si web public.
- Relier erreurs de formulaires aux champs.
- Ajouter libellés accessibles aux loaders/status.
- Mesurer contrastes tenant dynamique.

## 11. P3 - Nice To Have

- Support reduced motion.
- Tests golden/accessibilité sur composants custom.
- Documentation QA a11y.

## 12. Quick Wins

- Ajouter tooltips aux IconButtons +/- quantité.
- Ajouter `Semantics(button: true, selected: ...)` aux chips/variants custom.
- Ajouter texte de chargement aux spinners importants.
- Ajouter `lang="fr"` dans `web/index.html`.

## 13. Suggested Manual Testing

Keyboard-only pass:

- Naviguer catalogue, ouvrir produit, changer variante, essayer ajout panier, checkout.

Screen reader pass:

- TalkBack Android et VoiceOver iOS sur login, détail produit, panier, checkout, paiement Stripe.

Zoom/reflow:

- Tester tailles texte système élevées et petits écrans.

Mobile:

- Vérifier touch targets, carte, dialogs, bottom CTA.

## 14. Final Verdict

L'application a une base Material correcte, mais elle n'est pas prête accessibilité production. Le plus gros risque est la livraison par carte sans alternative accessible, suivi des widgets `GestureDetector` et de l'absence de validation manuelle screen reader/clavier.

Accessibility decision: Not Production Ready.
