# app-client

Interface Flutter client pour O'Pizza : catalogue, panier, commande, paiement
Stripe, suivi temps reel et notifications push.

## Developpement

```bash
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx \
  --dart-define=TENANT_SLUG=pizza_test
```

Firebase est optionnel en developpement local. Si aucune configuration Firebase
n'est fournie, le boot continue et les notifications push restent desactivees.

## Configuration release obligatoire

Une release appelle `Env.validateForRelease()` avant Firebase, Stripe et toute
navigation. L'app echoue au demarrage si une valeur dangereuse reste presente :
HTTP/local API, tenant `demo`, Stripe test/placeholder, Apple merchant
placeholder, Google Pay test, Firebase manquant, ou liens legaux non HTTPS.

Utiliser `config/dart-defines.production.example.json` comme contrat de
configuration et injecter les vraies valeurs par CI/secrets :

```bash
flutter build apk --release \
  --dart-define-from-file=config/dart-defines.production.json
```

Ne pas versionner `config/dart-defines.production.json`.

## Compatibilite API

Cette app cible le backend `api-pizza` avec les contrats suivants :

- `X-Tenant-Slug` obligatoire sur toutes les requetes API.
- `POST /delivery/check` recoit `lat`, `lng` et peut recevoir `address`.
- `POST /orders` recoit `Idempotency-Key` en header, pas dans le body.
- Les commandes et les statuts utilisent des ids `int`.
- Le suivi live consomme `/ws/notifications` puis refetch `GET /orders/{id}`.

Avant de publier une version mobile, valider ces contrats contre la version de
backend de production visee.

Variables attendues :

- `APP_ENV=production`
- `API_BASE_URL=https://...`
- `STRIPE_PUBLISHABLE_KEY=pk_live_...`
- `APPLE_MERCHANT_IDENTIFIER=merchant....`
- `GOOGLE_PAY_TEST_ENV=false`
- `TENANT_SLUG=<tenant-prod>`
- `PRIVACY_POLICY_URL=https://...`
- `TERMS_OF_USE_URL=https://...`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_ANDROID_API_KEY` / `FIREBASE_ANDROID_APP_ID`
- `FIREBASE_IOS_API_KEY` / `FIREBASE_IOS_APP_ID` / `FIREBASE_IOS_BUNDLE_ID`
- `FIREBASE_WEB_*` si une build web publique est livree

## Firebase

La configuration Firebase est construite depuis `lib/core/config/firebase_env_options.dart`.
Les fichiers `google-services.json`, `GoogleService-Info.plist` et
`firebase_options.dart` ne sont pas requis dans le depot et restent ignores pour
eviter les ajouts manuels non relus.

Pour la production, utiliser des projets Firebase separes par environnement et
verifier que le package Android, le bundle id iOS et les apps Firebase
correspondent aux binaires publies.

## Android signing

La release Android n'utilise plus la cle debug. Fournir une vraie cle d'upload
via `android/key.properties`, base sur `android/key.properties.example` :

```properties
storeFile=app/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Les taches Gradle `assembleRelease`, `bundleRelease` et `packageRelease` echouent
si cette configuration manque.

## CI securite

Le workflow GitHub Actions execute :

- format + analyse Flutter ;
- generation Freezed/JSON via `build_runner` avant analyse/tests ;
- tests avec couverture ;
- scan OSV sur `pubspec.lock` ;
- scan secrets redige via Gitleaks ;
- validation des `dart-define` de release avec les secrets CI ;
- build Android signee et build iOS `--no-codesign` hors pull request.

Dependabot surveille aussi les packages Pub et les GitHub Actions.
Si le depot est porte par une organisation GitHub, `GITLEAKS_LICENSE` doit etre
fourni en secret CI pour que `gitleaks/gitleaks-action@v3` puisse s'executer.

Important : le depot Git effectif est le root `workspace/pizza`. La CI active
est donc definie dans `../.github/workflows/app-client-ci.yml`, avec
`working-directory: app-client`. Un workflow place dans `app-client/.github/`
ne serait pas execute par GitHub Actions dans cette topologie.

## Validation manuelle go-live

Les points suivants ne sont pas prouvables par les tests unitaires/widget locaux
et doivent etre executes sur simulateur/appareil avec backend et secrets de test
reels :

- Firebase : demarrage debug sans config, puis release avec `FIREBASE_*` reels.
- Stripe : PaymentSheet avec carte test, carte 3DS, annulation utilisateur et
  retry sans creation d'un second PaymentIntent.
- Google Pay : `GOOGLE_PAY_TEST_ENV=true` uniquement en test, `false` en release.
- Livraison : adresse texte obligatoire, point carte dans zone, point hors zone
  avec repli retrait.
- Push/tracking : notification ou event WebSocket ouvrant le suivi de la bonne
  commande.

## Hors perimetre client mais bloquant go-live

Avant mise en production publique, valider cote backend `api-pizza` :

- isolation tenant imposee serveur, pas seulement par `X-Tenant-Slug` ;
- ownership des commandes et sessions ;
- webhooks Stripe signes, anti-replay et idempotents ;
- idempotence serveur de `POST /payments/intent` par tenant/user/order ;
- reconciliation paiement/commande ;
- logs et monitoring sans donnees sensibles.

Voir aussi [RUNBOOK.md](RUNBOOK.md) pour les preuves a collecter avant une
publication store.
