# Mise en production - Menus client phase 6

Ce guide couvre l'affichage, la composition et la commande des menus dans
l'application client. Il suppose que l'interface admin de phase 5 est deja
disponible pour preparer les menus du tenant.

## Prerequis

- Deployer l'API menus phases 1 a 4 avant l'application client.
- Verifier qu'Alembic est a la revision `0081`.
- Disposer d'au moins un menu actif, publiable et visible via
  `GET /catalog/menus` avec le header `X-Tenant-Slug` du tenant pilote.
- Verifier que chaque groupe propose assez de produits disponibles pour son
  minimum de choix.
- Utiliser une version de l'application admin incluant la phase 5 pour corriger
  rapidement un menu incomplet.

## Verification avant livraison

Depuis `app-client/` :

```powershell
C:\Users\melbo\flutter\bin\flutter.bat pub run build_runner build --delete-conflicting-outputs
C:\Users\melbo\flutter\bin\flutter.bat analyze --no-pub
C:\Users\melbo\flutter\bin\flutter.bat test --no-pub test\features\catalog\menu_phase6_test.dart test\features\checkout\menu_checkout_phase6_test.dart
```

Construire ensuite l'artefact avec les `dart-define` habituels de
l'environnement cible. Cette phase n'ajoute aucune variable d'environnement ni
migration.

## Ordre de deploiement

1. Sauvegarder la base et verifier la revision `0081`.
2. Deployer l'API compatible avec `menu_items`.
3. Tester les endpoints publics listing et detail sur le tenant pilote.
4. Publier un menu pilote depuis l'application admin.
5. Deployer l'application client en recette ou sur un canal interne.
6. Tester un panier mixte produit + menu en retrait puis en livraison.
7. Verifier le paiement, le recu et l'historique parent/composants.
8. Promouvoir le meme artefact vers la production.

## Smoke tests production

- La section `Menus` apparait sur l'accueil uniquement quand un menu public
  existe.
- Un menu indisponible explique la raison et ne peut pas etre ajoute.
- Les minimums et maximums de chaque groupe sont respectes.
- Les variantes et extras restent inclus dans le prix fixe affiche.
- Le panier et le recapitulatif montrent le menu parent puis ses composants.
- Le payload de commande contient `menu_items`, sans prix fourni par le client.
- Une modification ou indisponibilite detectee au checkout bloque la commande et
  conserve le panier.
- Le recu affiche la ligne menu et ses composants sans erreur de parsing.

## Surveillance

Surveiller les codes `MENU_NOT_AVAILABLE`, `INVALID_MENU_SELECTION` et
`MENU_PRODUCT_UNAVAILABLE`, ainsi que les `404`, `409`, `422` et `5xx` sur
`/catalog/menus` et `/orders`. Comparer aussi le taux d'abandon entre ouverture
de la fiche menu, ajout panier et creation de commande.

Une hausse de `INVALID_MENU_SELECTION` indique generalement un client ancien,
un menu modifie pendant la composition ou un contrat API non aligne. Le serveur
reste autoritaire et aucun prix recu du client ne doit etre utilise.

## Retour arriere

Retirer ou desactiver tous les menus dans l'admin masque immediatement la section
client sans redeployer l'API. L'application client peut ensuite revenir a sa
version precedente ; les commandes deja creees gardent leurs snapshots.

Ne pas downgrader Alembic `0081` apres la creation de commandes menus. En cas
d'incident limite au client, conserver l'API et les donnees, desactiver les menus
publies puis restaurer le binaire client precedent.
