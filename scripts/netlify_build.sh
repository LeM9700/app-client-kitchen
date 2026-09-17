#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.7}"
FLUTTER_HOME="${NETLIFY_CACHE_DIR:-$HOME/.cache}/flutter-$FLUTTER_VERSION"

required_vars=(
  APP_ENV
  API_BASE_URL
  STRIPE_PUBLISHABLE_KEY
  APPLE_MERCHANT_IDENTIFIER
  GOOGLE_PAY_TEST_ENV
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
)

missing=()
for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    missing+=("$var_name")
  fi
done

if (( ${#missing[@]} > 0 )); then
  echo "Missing required Netlify environment variables:"
  printf ' - %s\n' "${missing[@]}"
  echo "See docs/netlify-environment.md for the value purpose and setup commands."
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  if [[ ! -x "$FLUTTER_HOME/bin/flutter" ]]; then
    rm -rf "$FLUTTER_HOME"
    git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

flutter --version
flutter config --enable-web
flutter pub get
dart run build_runner build --delete-conflicting-outputs

flutter build web --release \
  --dart-define=APP_ENV="$APP_ENV" \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=STRIPE_PUBLISHABLE_KEY="$STRIPE_PUBLISHABLE_KEY" \
  --dart-define=APPLE_MERCHANT_IDENTIFIER="$APPLE_MERCHANT_IDENTIFIER" \
  --dart-define=GOOGLE_PAY_TEST_ENV="$GOOGLE_PAY_TEST_ENV" \
  --dart-define=TENANT_SLUG="$TENANT_SLUG" \
  --dart-define=PRIVACY_POLICY_URL="$PRIVACY_POLICY_URL" \
  --dart-define=TERMS_OF_USE_URL="$TERMS_OF_USE_URL" \
  --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
  --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
  --dart-define=FIREBASE_WEB_API_KEY="$FIREBASE_WEB_API_KEY" \
  --dart-define=FIREBASE_WEB_APP_ID="$FIREBASE_WEB_APP_ID" \
  --dart-define=FIREBASE_WEB_AUTH_DOMAIN="$FIREBASE_WEB_AUTH_DOMAIN" \
  --dart-define=FIREBASE_WEB_MEASUREMENT_ID="$FIREBASE_WEB_MEASUREMENT_ID" \
  --dart-define=FIREBASE_WEB_VAPID_KEY="$FIREBASE_WEB_VAPID_KEY" \
  --dart-define=SENTRY_DSN="$SENTRY_DSN"
