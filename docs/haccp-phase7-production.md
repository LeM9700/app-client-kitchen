# HACCP strict — phase 7 : parcours client et commande

## Objet

Cette phase rend le parcours client compatible avec le gate HACCP strict côté
API. Le catalogue reste consultable, mais le panier est revalidé juste avant
la création de commande. Un produit devenu indisponible bloque la commande,
conserve le panier et indique l'action attendue. Les codes serveur
`HACCP_ORDERING_BLOCKED` et `HACCP_STOCK_UNAVAILABLE` sont affichés comme un
refus sanitaire explicite.

## Mise en production

1. Déployer d'abord l'API contenant le gate HACCP strict et ses migrations,
   puis vérifier que chaque établissement ciblé possède sa configuration et
   ses contrôles journaliers.
2. Publier le binaire client de cette phase avec la même base API. Le client
   ne décide jamais de la conformité : le `POST /orders` reste l'autorité.
3. Vérifier sur un établissement de recette : catalogue visible, ajout au
   panier possible, produit désactivé refusé avant paiement, panier conservé,
   puis commande possible après régularisation HACCP.
4. Vérifier les journaux et métriques des réponses `HACCP_ORDERING_BLOCKED` et
   `HACCP_STOCK_UNAVAILABLE` avant d'élargir le déploiement.

## Retour arrière

Le rollback consiste à republier le binaire client précédent. Ne pas annuler
les migrations ni désactiver le gate API pour contourner un blocage sanitaire.
Les paniers locaux restent sans effet serveur.

## Vérifications post-déploiement

- [ ] La revalidation finale se produit avant chaque `POST /orders`.
- [ ] Un stock à plat ne vide pas le panier et empêche le passage au paiement.
- [ ] Un refus HACCP conserve le panier et expose un message compréhensible.
- [ ] Les clés d'idempotence existantes restent réutilisées après une erreur
      réseau ou un refus métier.
- [ ] Aucun détail de DLC, température ou checklist privée n'est exposé au
      client.

## Limites connues

La sélection multi-établissements et l'affichage d'un statut HACCP détaillé
public restent hors de cette phase : le client est mono-tenant et l'API de
statut strict est réservée au staff habilité. La décision serveur demeure
donc la seule source de vérité.
