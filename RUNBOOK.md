# app-client security runbook

Ce runbook complete l'audit `audit/audit-security.md`. Il liste les preuves
attendues avant publication, sans supposer l'existence de secrets ou d'acces
externes dans le depot.

## Preuves CI

Ce depot est standalone (remote `LeM9700/app-client-kitchen`) ; la preuve CI
valide est le workflow de ce depot lui-meme, `.github/workflows/ci.yml`
(jobs `analyze-and-test`, `gitleaks`, `osv-scan`, `android-release-build`,
`ios-build`).

Pour une release candidate, archiver :

- run `analyze-and-test` vert ;
- run `osv-scan` vert sur `pubspec.lock` ;
- run `gitleaks` vert ;
- run `android-release-build` vert avec artefact `.aab` signe produit (pas
  seulement "skipped" — verifier que le job n'a pas juste affiche
  l'avertissement "signing secrets not configured") ;
- run `ios-build` (`--no-codesign`) vert ;
- log du test `env_release_runtime_test.dart` avec secrets masques par GitHub.

Secrets CI requis dans les parametres du depot GitHub (Settings > Secrets and
variables > Actions) :

- `GITLEAKS_LICENSE` si le depot est dans une organisation GitHub.
- `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
  `ANDROID_KEY_PASSWORD` pour que `android-release-build` produise un
  artefact signe reel plutot que d'etre saute.

Tant que ces secrets ne sont pas configures, la CI reste verte (le job
signing se saute proprement) mais **ne prouve pas** un artefact release
signe — ne pas confondre "CI verte" avec "release verifiee" avant que ces
secrets existent.

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
- `SENTRY_DSN` renseigné avec un projet Sentry réel ; une erreur de test
  declenchee manuellement (ex. bouton debug ou `throw` temporaire) apparait
  bien dans le dashboard Sentry avant publication.

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
