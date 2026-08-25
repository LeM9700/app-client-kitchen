import 'package:flutter/foundation.dart';

/// Compile-time configuration injected with `--dart-define`.
///
/// Development defaults are intentionally convenient, but release builds must
/// call [validateForRelease] before any network, Firebase or Stripe setup.
abstract final class Env {
  static const String appEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// API base URL for api-pizza.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  /// Stripe publishable key. Production builds must use a `pk_live_...` key.
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_REPLACE_ME',
  );

  /// Apple Pay merchant identifier registered in Apple Developer and Stripe.
  static const String appleMerchantIdentifier = String.fromEnvironment(
    'APPLE_MERCHANT_IDENTIFIER',
    defaultValue: 'merchant.com.opizza.placeholder',
  );

  /// Google Pay test flag. Default stays true for local development.
  static const bool googlePayTestEnv = bool.fromEnvironment(
    'GOOGLE_PAY_TEST_ENV',
    defaultValue: true,
  );

  /// Tenant slug. One build targets one restaurant in v1.
  static const String tenantSlug = String.fromEnvironment(
    'TENANT_SLUG',
    defaultValue: 'pizza_test',
  );

  /// Public legal document URLs shown in the account area.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: '',
  );

  static const String termsOfUseUrl = String.fromEnvironment(
    'TERMS_OF_USE_URL',
    defaultValue: '',
  );

  /// Shared Firebase project configuration.
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );

  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: '',
  );

  /// Optional generic Firebase values, useful when a build target has its own
  /// CI job and therefore only needs one app id/key at a time.
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );

  /// Platform-specific Firebase values. These take precedence over the generic
  /// values above when present.
  static const String firebaseAndroidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
    defaultValue: '',
  );

  static const String firebaseAndroidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '',
  );

  static const String firebaseIosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
    defaultValue: '',
  );

  static const String firebaseIosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: '',
  );

  static const String firebaseIosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.opizza.appClient',
  );

  static const String firebaseWebApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: '',
  );

  static const String firebaseWebAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '',
  );

  static const String firebaseWebAuthDomain = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
    defaultValue: '',
  );

  static const String firebaseWebMeasurementId = String.fromEnvironment(
    'FIREBASE_WEB_MEASUREMENT_ID',
    defaultValue: '',
  );

  static const String firebaseWebVapidKey = String.fromEnvironment(
    'FIREBASE_WEB_VAPID_KEY',
    defaultValue: '',
  );

  static String get currentFirebaseApiKey {
    if (kIsWeb) return _firstNonEmpty(firebaseWebApiKey, firebaseApiKey);
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        _firstNonEmpty(firebaseAndroidApiKey, firebaseApiKey),
      TargetPlatform.iOS => _firstNonEmpty(firebaseIosApiKey, firebaseApiKey),
      _ => firebaseApiKey,
    };
  }

  static String get currentFirebaseAppId {
    if (kIsWeb) return _firstNonEmpty(firebaseWebAppId, firebaseAppId);
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        _firstNonEmpty(firebaseAndroidAppId, firebaseAppId),
      TargetPlatform.iOS => _firstNonEmpty(firebaseIosAppId, firebaseAppId),
      _ => firebaseAppId,
    };
  }

  static bool get isFirebaseConfigured =>
      firebaseProjectId.trim().isNotEmpty &&
      firebaseMessagingSenderId.trim().isNotEmpty &&
      currentFirebaseApiKey.trim().isNotEmpty &&
      currentFirebaseAppId.trim().isNotEmpty;

  /// Throws in release if any production blocker is still configured with a
  /// dev value or missing placeholder.
  static void validateForRelease({bool? releaseMode}) {
    if (!(releaseMode ?? kReleaseMode)) return;

    final errors = releaseValidationErrors();
    if (errors.isNotEmpty) {
      throw EnvironmentConfigException(errors);
    }
  }

  /// Pure validation helper used by tests and by [validateForRelease].
  static List<String> releaseValidationErrors({
    String? appEnvironmentOverride,
    String? apiBaseUrlOverride,
    String? stripePublishableKeyOverride,
    String? appleMerchantIdentifierOverride,
    bool? googlePayTestEnvOverride,
    String? tenantSlugOverride,
    String? privacyPolicyUrlOverride,
    String? termsOfUseUrlOverride,
    String? firebaseProjectIdOverride,
    String? firebaseMessagingSenderIdOverride,
    String? firebaseStorageBucketOverride,
    String? firebaseApiKeyOverride,
    String? firebaseAppIdOverride,
  }) {
    final errors = <String>[];
    final environment = (appEnvironmentOverride ?? appEnvironment).trim();
    final apiUrl = (apiBaseUrlOverride ?? apiBaseUrl).trim();
    final stripeKey =
        (stripePublishableKeyOverride ?? stripePublishableKey).trim();
    final appleMerchantId =
        (appleMerchantIdentifierOverride ?? appleMerchantIdentifier).trim();
    final googlePayIsTest = googlePayTestEnvOverride ?? googlePayTestEnv;
    final tenant = (tenantSlugOverride ?? tenantSlug).trim();
    final privacyUrl = (privacyPolicyUrlOverride ?? privacyPolicyUrl).trim();
    final termsUrl = (termsOfUseUrlOverride ?? termsOfUseUrl).trim();
    final firebaseProject =
        (firebaseProjectIdOverride ?? firebaseProjectId).trim();
    final firebaseSender =
        (firebaseMessagingSenderIdOverride ?? firebaseMessagingSenderId).trim();
    final firebaseBucket =
        (firebaseStorageBucketOverride ?? firebaseStorageBucket).trim();
    final firebaseKey =
        (firebaseApiKeyOverride ?? currentFirebaseApiKey).trim();
    final firebaseApp = (firebaseAppIdOverride ?? currentFirebaseAppId).trim();

    if (environment != 'production') {
      errors.add('APP_ENV must be production in release.');
    }

    final parsedApiUrl = Uri.tryParse(apiUrl);
    if (parsedApiUrl == null ||
        !parsedApiUrl.hasScheme ||
        !parsedApiUrl.hasAuthority) {
      errors.add('API_BASE_URL must be an absolute HTTPS URL.');
    } else {
      if (parsedApiUrl.scheme != 'https') {
        errors.add('API_BASE_URL must use https in release.');
      }
      final host = parsedApiUrl.host.toLowerCase();
      const forbiddenHosts = {
        '10.0.2.2',
        '127.0.0.1',
        '0.0.0.0',
        'localhost',
      };
      if (forbiddenHosts.contains(host) || host.endsWith('.local')) {
        errors.add('API_BASE_URL must not target local or emulator hosts.');
      }
    }

    if (!stripeKey.startsWith('pk_live_') || stripeKey.contains('REPLACE_ME')) {
      errors.add('STRIPE_PUBLISHABLE_KEY must be a live publishable key.');
    }

    if (!appleMerchantId.startsWith('merchant.') ||
        appleMerchantId.contains('placeholder')) {
      errors.add('APPLE_MERCHANT_IDENTIFIER must be a real merchant id.');
    }

    if (googlePayIsTest) {
      errors.add('GOOGLE_PAY_TEST_ENV must be false in release.');
    }

    final tenantPattern = RegExp(r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$');
    const forbiddenTenants = {'demo', 'dev', 'test', 'default'};
    if (!tenantPattern.hasMatch(tenant) ||
        forbiddenTenants.contains(tenant.toLowerCase())) {
      errors.add('TENANT_SLUG must be a real production tenant slug.');
    }

    if (!_isHttpsUrl(privacyUrl)) {
      errors.add('PRIVACY_POLICY_URL must be an HTTPS URL.');
    }
    if (!_isHttpsUrl(termsUrl)) {
      errors.add('TERMS_OF_USE_URL must be an HTTPS URL.');
    }

    if (firebaseProject.isEmpty) {
      errors.add('FIREBASE_PROJECT_ID is required.');
    }
    if (firebaseSender.isEmpty) {
      errors.add('FIREBASE_MESSAGING_SENDER_ID is required.');
    }
    if (firebaseBucket.isEmpty) {
      errors.add('FIREBASE_STORAGE_BUCKET is required.');
    }
    if (firebaseKey.isEmpty) {
      errors.add(
        'FIREBASE_API_KEY or platform-specific Firebase API key is required.',
      );
    }
    if (firebaseApp.isEmpty) {
      errors.add(
        'FIREBASE_APP_ID or platform-specific Firebase app id is required.',
      );
    }

    return errors;
  }

  static bool _isHttpsUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.hasAuthority &&
        uri.host.isNotEmpty;
  }

  static String _firstNonEmpty(String first, String fallback) =>
      first.trim().isNotEmpty ? first : fallback;
}

class EnvironmentConfigException implements Exception {
  const EnvironmentConfigException(this.errors);

  final List<String> errors;

  @override
  String toString() => 'Invalid release configuration:\n'
      '${errors.map((error) => '- $error').join('\n')}';
}
