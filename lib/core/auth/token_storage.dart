import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper autour de [FlutterSecureStorage] pour les tokens d'authentification.
///
/// Seul le **refresh token** est persisté ici.
/// L'access token vit en mémoire dans [accessTokenProvider] (Riverpod) —
/// il disparaît à l'arrêt de l'app, ce qui limite la surface d'exposition
/// sur un appareil rooté.
///
/// [🔒 SÉCURITÉ] Sur Android, [AndroidOptions.encryptedSharedPreferences]
/// active le chiffrement AES-256 via Jetpack Security. Sur iOS, le token
/// est stocké dans le Keychain.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: androidOptions,
              iOptions: iosOptions,
            );

  static const AndroidOptions androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
  );

  static const IOSOptions iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
  );

  static const String _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  /// Lit le refresh token depuis le stockage sécurisé.
  /// Retourne `null` si absent (première ouverture, ou après un [clearAll]).
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  /// Persiste [token] dans le stockage sécurisé.
  /// Appelé après un login ou un refresh réussi.
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  /// Supprime uniquement le refresh token.
  /// À préférer à [clearAll] lors d'une déconnexion normale.
  Future<void> clearRefreshToken() => _storage.delete(key: _refreshTokenKey);

  /// Supprime toutes les entrées du stockage sécurisé.
  /// À utiliser uniquement lors d'une réinitialisation complète de l'app.
  Future<void> clearAll() => _storage.deleteAll();
}
