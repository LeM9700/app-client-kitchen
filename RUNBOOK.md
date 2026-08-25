# app-client security runbook

Ce runbook complete l'audit `audit/audit-security.md`. Il liste les preuves
attendues avant publication, sans supposer l'existence de secrets ou d'acces
externes dans le depot.

## Preuves CI

La preuve CI valide est le workflow root
`../.github/workflows/app-client-ci.yml`.

Pour une release candidate, archiver :

- run `Format, Analyze, Test` vert ;
- run OSV vert sur `app-client/pubspec.lock` ;
- run Gitleaks vert ;
- artefact Android signe ;
- build iOS `--no-codesign` vert ;
- log du test `env_release_runtime_test.dart` avec secrets masques par GitHub.

Si le depot est dans une organisation GitHub, ajouter aussi
`GITLEAKS_LICENSE` aux secrets CI.

Un run CI n'est pas une preuve si le workflow vient de `app-client/.github/`
dans le depot root actuel.

## Rotation secrets et signing

Stripe :

- `STRIPE_PUBLISHABLE_KEY` cote client uniquement, jamais `sk_*` ni `whsec_*` ;
- rotation des `sk_*` et `whsec_*` uniquement cote backend/CI ;
- apres rotation webhook, rejouer un event Stripe staging et verifier un seul
  effet metier.

Firebase :

- projets separes par environnement ;
- verifier package Android, bundle iOS, APNs/FCM et VAPID web si publie ;
- aucune service account JSON dans le client.

Android signing :

- stocker le keystore en secret CI base64 ;
- ne jamais versionner `android/key.properties`, `*.jks` ou `*.keystore` ;
- apres rotation, verifier que `validateReleaseSigning` bloque sans secret et
  que le build signe produit un artefact.

## Checklist store release

- CI root verte sur le commit livre.
- `APP_ENV=production`.
- `API_BASE_URL` HTTPS, non local.
- `STRIPE_PUBLISHABLE_KEY=pk_live_...`.
- `APPLE_MERCHANT_IDENTIFIER=merchant...`.
- `GOOGLE_PAY_TEST_ENV=false`.
- `TENANT_SLUG` reel, ni `demo`, ni `dev`, ni `test`.
- URLs legales HTTPS et contenu valide.
- Firebase Android/iOS teste sur appareil reel.
- Stripe PaymentSheet teste en staging : paiement, 3DS, annulation, retry.
- Push notification ouvre uniquement `/orders/<id>/tracking` avec `id` entier
  positif.

## Preuves hors client

Avant go-live public, archiver un rapport backend couvrant :

- ownership commandes, paiements et sessions ;
- isolation tenant serveur ;
- JWT expiration/signature/revocation ;
- idempotence `POST /payments/intent` ;
- webhooks Stripe signes, anti-replay et sources finales du statut paiement ;
- logs backend sans tokens, adresses completes ni secrets.

Sans ces preuves, le client peut etre considere durci dans son perimetre, mais
le produit complet ne peut pas etre note `10/10`.
