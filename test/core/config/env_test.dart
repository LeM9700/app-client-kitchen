import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/core/config/env.dart';

void main() {
  group('Env.releaseValidationErrors', () {
    test('rejects dangerous development defaults for release', () {
      final errors = Env.releaseValidationErrors(
        appEnvironmentOverride: 'development',
        apiBaseUrlOverride: 'http://10.0.2.2:8000',
        stripePublishableKeyOverride: 'pk_test_REPLACE_ME',
        appleMerchantIdentifierOverride: 'merchant.com.opizza.placeholder',
        googlePayTestEnvOverride: true,
        tenantSlugOverride: 'demo',
        privacyPolicyUrlOverride: '',
        termsOfUseUrlOverride: '',
        firebaseProjectIdOverride: '',
        firebaseMessagingSenderIdOverride: '',
        firebaseStorageBucketOverride: '',
        firebaseApiKeyOverride: '',
        firebaseAppIdOverride: '',
      );

      expect(errors, contains('APP_ENV must be production in release.'));
      expect(errors, contains('API_BASE_URL must use https in release.'));
      expect(
        errors,
        contains('API_BASE_URL must not target local or emulator hosts.'),
      );
      expect(
        errors,
        contains('STRIPE_PUBLISHABLE_KEY must be a live publishable key.'),
      );
      expect(
        errors,
        contains('APPLE_MERCHANT_IDENTIFIER must be a real merchant id.'),
      );
      expect(errors, contains('GOOGLE_PAY_TEST_ENV must be false in release.'));
      expect(
        errors,
        contains('TENANT_SLUG must be a real production tenant slug.'),
      );
      expect(errors, contains('PRIVACY_POLICY_URL must be an HTTPS URL.'));
      expect(errors, contains('TERMS_OF_USE_URL must be an HTTPS URL.'));
      expect(errors, contains('FIREBASE_PROJECT_ID is required.'));
      expect(errors, contains('FIREBASE_MESSAGING_SENDER_ID is required.'));
      expect(errors, contains('FIREBASE_STORAGE_BUCKET is required.'));
    });

    test('accepts a production-safe configuration', () {
      final errors = Env.releaseValidationErrors(
        appEnvironmentOverride: 'production',
        apiBaseUrlOverride: 'https://api.opizza.example',
        stripePublishableKeyOverride: 'pk_live_123',
        appleMerchantIdentifierOverride: 'merchant.com.opizza.restaurant',
        googlePayTestEnvOverride: false,
        tenantSlugOverride: 'opizza-paris',
        privacyPolicyUrlOverride: 'https://opizza.example/privacy',
        termsOfUseUrlOverride: 'https://opizza.example/terms',
        firebaseProjectIdOverride: 'opizza-prod',
        firebaseMessagingSenderIdOverride: '1234567890',
        firebaseStorageBucketOverride: 'opizza-prod.appspot.com',
        firebaseApiKeyOverride: 'AIza-prod',
        firebaseAppIdOverride: '1:1234567890:android:abcdef',
      );

      expect(errors, isEmpty);
    });
  });

  group('Env.validateForRelease', () {
    test('does not throw outside release mode', () {
      expect(
        () => Env.validateForRelease(releaseMode: false),
        returnsNormally,
      );
    });
  });
}
