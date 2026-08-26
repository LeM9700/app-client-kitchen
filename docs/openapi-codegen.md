# POC — génération de client HTTP depuis OpenAPI

## Contexte

Aujourd'hui, tous les DTOs client (`lib/features/*/models/*.dart`) sont mappés à la main
depuis les schémas Pydantic d'`api-pizza`. Risque : dérive de contrat silencieuse (un champ
renommé/retiré côté serveur ne casse rien à la compilation côté client tant que le DTO à la
main n'a pas été mis à jour manuellement).

Ce POC valide qu'un pipeline **OpenAPI → client Dart généré** est réalisable dans ce projet,
sur un périmètre volontairement restreint : le module `favorites` (le plus récent, le plus
simple). Il ne remplace **pas** les 14+ autres repositories existants — c'est une décision de
scope explicite, pas un oubli (voir "Ce qui reste à faire" plus bas).

## Outillage retenu

[`swagger_dart_code_generator`](https://pub.dev/packages/swagger_dart_code_generator) — un
builder `build_runner` pur Dart (pas de dépendance à un JAR/CLI externe type
`openapi-generator`, contrairement à d'autres options courantes). Choisi précisément parce que
ce projet a déjà `build_runner`/`freezed`/`json_serializable` en place : moins de nouvel
outillage à maintenir.

- `pubspec.yaml` (dev_dependency) : `swagger_dart_code_generator`.
- `build.yaml` (racine) : config du builder, `build_only_models: true` — génère uniquement les
  modèles (`FavoriteCreate`, `FavoriteResponse`, `ValidationError`, `HTTPValidationError`), pas
  de client Chopper. Ce projet utilise Dio partout, pas Chopper (que ce générateur produit par
  défaut) — générer des requêtes Chopper aurait introduit une deuxième lib HTTP sans valeur
  ajoutée pour ce POC. Le repository HTTP (`FavoritesRepository`, déjà écrit à la main sur Dio)
  n'est **pas** remplacé.

## Schéma source

`lib/core/openapi/favorites.json` — sous-ensemble OpenAPI 3.0 des 3 endpoints `/favorites`,
extrait à la main depuis `api-pizza/app/modules/favorites/router.py` + `schemas.py` (le code
source réel, pas une supposition) car il n'a pas été possible de démarrer `uvicorn` en local
dans cet environnement d'exécution (le lifespan de l'app tente de joindre MongoDB/Redis, tous
deux absents du sandbox — timeout indéfini, pas d'erreur explicite).

**Sur un poste de dev normal**, la vraie procédure (documentée dans
`api-pizza/docs/local-testing.md` étape 6) est :

```bash
# depuis api-pizza/, avec Postgres/Mongo/Redis lancés
uvicorn app.main:app --reload
curl http://127.0.0.1:8000/openapi.json -o app-client/lib/core/openapi/openapi_full.json
# puis extraire le sous-ensemble voulu, ou pointer directement le generator
# sur le fichier complet si on élargit le périmètre au-delà de favorites.
```

Le fichier actuel étant écrit à la main, c'est une fidélité "au meilleur effort au moment de
l'écriture" — toute dérive future du router réel ne sera PAS détectée automatiquement tant que
ce schéma n'est pas régénéré depuis un `/openapi.json` réel. C'est une limite assumée du POC,
pas de la solution cible.

## Comment régénérer

```bash
cd app-client
dart run build_runner build --delete-conflicting-outputs
```

Génère `lib/core/generated/favorites_client/favorites.swagger.dart` (modèles).

## Point ouvert connu (à creuser avant d'élargir le périmètre)

Dans cet environnement, `json_serializable` détecte bien `favorites.swagger.dart` (visible
via `--build-filter`, `source_gen:combining_builder on 1 input`) mais le marque `skipped` sans
produire `favorites.swagger.g.dart`, y compris après un rebuild complet avec cache vidé
(`.dart_tool/build` supprimé). `flutter analyze` sur le fichier généré seul ne remonte qu'un
warning cosmétique (`unused_import`) — pas d'erreur d'analyse expliquant le skip. La partie
`.g.dart` de ce POC a donc été complétée à la main (mécanique et déterministe — c'est
exactement ce que `json_serializable` aurait produit) pour livrer une preuve de concept qui
compile et dont les tests passent réellement, plutôt que de la laisser cassée.

**Avant d'élargir ce POC à d'autres modules**, il faut comprendre cette régression :
reproduire sur un poste de dev standard (hors sandbox) pour confirmer si c'est un problème
spécifique à cet environnement d'exécution ou un vrai problème de compatibilité de versions
(`swagger_dart_code_generator` vs `json_serializable`/`build_runner` actuellement épinglés
dans ce projet).

## Preuve de valeur

`test/core/generated/favorites_client_test.dart` — 3 tests validant que les modèles générés
(dé)sérialisent correctement des payloads conformes au contrat réel serveur (y compris le
format d'erreur 422 standard FastAPI). Tous verts.

## Ce qui reste à faire pour un remplacement complet (hors scope de ce POC)

- Résoudre le point ouvert `json_serializable` ci-dessus.
- Décider génération de requêtes (Chopper généré vs Dio écrit à la main comme aujourd'hui) —
  un remplacement complet impliquerait soit d'adopter Chopper partout (gros changement
  d'architecture), soit de continuer à écrire les repositories à la main mais avec des DTOs
  générés (approche hybride, probablement la plus réaliste).
- Étendre `openapi/*.json` aux 14+ autres modules, un à la fois, avec tests de non-régression
  à chaque étape (ne pas tout migrer d'un coup).
- Décider d'un processus de régénération fiable (script `curl` + extraction automatisée plutôt
  que des fichiers écrits à la main comme celui-ci) avant de faire confiance au schéma comme
  source de vérité anti-dérive — c'est tout l'intérêt de la démarche, un schéma halluciné/périmé
  serait pire que les DTOs actuels.
