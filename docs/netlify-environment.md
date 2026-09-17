# Netlify environment for app-client

The client app is built from environment variables. Do not commit
`config/dart-defines.production.json` and do not paste secrets in issues,
chat, or commits.

## Required variables

| Variable | User-facing purpose |
| --- | --- |
| `APP_ENV` | Enables production safeguards so users do not load a dev/local app by accident. Use `production`. |
| `API_BASE_URL` | Lets users load the catalog, auth, cart, orders, favorites, notifications, delivery, and tenant data from the production API. |
| `TENANT_SLUG` | Loads the right restaurant data. For KOD MOME, use `kod-mome`. |
| `STRIPE_PUBLISHABLE_KEY` | Initializes Stripe in the browser so users can pay by card. Use the platform/super-admin publishable key, never a secret key. |
| `APPLE_MERCHANT_IDENTIFIER` | Enables Apple Pay for compatible users. |
| `GOOGLE_PAY_TEST_ENV` | Keeps Google Pay out of test mode in production. Use `false`. |
| `PRIVACY_POLICY_URL` | Lets users access the privacy policy from the app. |
| `TERMS_OF_USE_URL` | Lets users access terms/conditions from the app. |
| `FIREBASE_PROJECT_ID` | Identifies the Firebase project used by browser push notifications. |
| `FIREBASE_MESSAGING_SENDER_ID` | Enables Firebase Cloud Messaging token registration for push notifications. |
| `FIREBASE_STORAGE_BUCKET` | Completes Firebase web app configuration. |
| `FIREBASE_WEB_API_KEY` | Public Firebase web key used to initialize Firebase in the browser. |
| `FIREBASE_WEB_APP_ID` | Identifies this web app inside the Firebase project. |
| `FIREBASE_WEB_AUTH_DOMAIN` | Firebase web domain required by the Firebase web SDK. |
| `FIREBASE_WEB_MEASUREMENT_ID` | Enables Firebase/Google measurement if configured. |
| `FIREBASE_WEB_VAPID_KEY` | Enables real browser push permission and web push token generation. |
| `SENTRY_DSN` | Sends frontend errors to Sentry so production crashes and white screens can be diagnosed. |

## Set variables in Netlify

Use the Netlify dashboard:

`Site configuration` -> `Environment variables` -> `Add variable`

Recommended base values:

```text
APP_ENV=production
API_BASE_URL=https://api-kitchen-production.up.railway.app/api/v1
TENANT_SLUG=kod-mome
GOOGLE_PAY_TEST_ENV=false
```

Then add the real Stripe publishable key, Apple merchant id, Firebase web
values, legal URLs, and Sentry DSN.

## GitHub Actions production deploy

The workflow `.github/workflows/netlify-production.yml` builds the Flutter web
app and deploys `build/web` to Netlify on every push to `main`, and can also be
started manually from the GitHub Actions tab.

Add these repository secrets in GitHub:

```text
API_BASE_URL
STRIPE_PUBLISHABLE_KEY
APPLE_MERCHANT_IDENTIFIER
TENANT_SLUG
PRIVACY_POLICY_URL
TERMS_OF_USE_URL
FIREBASE_PROJECT_ID
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_STORAGE_BUCKET
FIREBASE_WEB_API_KEY
FIREBASE_WEB_APP_ID
FIREBASE_WEB_AUTH_DOMAIN
FIREBASE_WEB_MEASUREMENT_ID
FIREBASE_WEB_VAPID_KEY
SENTRY_DSN
NETLIFY_AUTH_TOKEN
NETLIFY_SITE_ID
```

Recommended fixed values:

```text
API_BASE_URL=https://api-kitchen-production.up.railway.app/api/v1
TENANT_SLUG=kod-mome
```

The workflow sets these non-secret values itself:

```text
APP_ENV=production
GOOGLE_PAY_TEST_ENV=false
```

`NETLIFY_SITE_ID` is visible in `npx netlify status` for the linked project.
`NETLIFY_AUTH_TOKEN` is a Netlify personal access token created locally from
Netlify user settings.

## Set variables with the Netlify CLI

Run commands locally so values are not exposed in chat or Git:

```bash
npx netlify env:set APP_ENV production --context production
npx netlify env:set API_BASE_URL https://api-kitchen-production.up.railway.app/api/v1 --context production
npx netlify env:set TENANT_SLUG kod-mome --context production
npx netlify env:set GOOGLE_PAY_TEST_ENV false --context production
```

For sensitive-looking values, let the CLI prompt you instead of putting them in
shell history:

```bash
npx netlify env:set STRIPE_PUBLISHABLE_KEY --context production
npx netlify env:set FIREBASE_WEB_API_KEY --context production
npx netlify env:set FIREBASE_WEB_APP_ID --context production
npx netlify env:set FIREBASE_WEB_AUTH_DOMAIN --context production
npx netlify env:set FIREBASE_WEB_MEASUREMENT_ID --context production
npx netlify env:set FIREBASE_WEB_VAPID_KEY --context production
npx netlify env:set SENTRY_DSN --context production
```

## Stripe Connect note

The client uses the platform publishable key. Tenants complete Stripe Connect
onboarding in the backend/admin flow. Secret keys and webhook secrets stay on
the backend only.

Never expose:

- `sk_live_...`
- `sk_test_...`
- `whsec_...`
- connected account secret keys
