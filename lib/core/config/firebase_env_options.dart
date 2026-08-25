import 'package:firebase_core/firebase_core.dart';

import 'package:app_client/core/config/env.dart';

/// Firebase options built from compile-time environment values.
///
/// This replaces the generated `firebase_options.dart` file so CI/release
/// builds can validate the exact project/app ids supplied for each target.
abstract final class FirebaseEnvOptions {
  static FirebaseOptions? get currentPlatform {
    if (!Env.isFirebaseConfigured) return null;

    return FirebaseOptions(
      apiKey: Env.currentFirebaseApiKey,
      appId: Env.currentFirebaseAppId,
      messagingSenderId: Env.firebaseMessagingSenderId,
      projectId: Env.firebaseProjectId,
      authDomain: _emptyToNull(Env.firebaseWebAuthDomain),
      storageBucket: _emptyToNull(Env.firebaseStorageBucket),
      measurementId: _emptyToNull(Env.firebaseWebMeasurementId),
      iosBundleId: _emptyToNull(Env.firebaseIosBundleId),
    );
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
