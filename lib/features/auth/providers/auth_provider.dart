import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/auth/token_storage.dart';
import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/core/providers/auth_session_provider.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/features/auth/models/user.dart';
import 'package:app_client/features/auth/repositories/auth_repository.dart';
import 'package:app_client/features/tracking/services/push_notification_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Providers
// ──────────────────────────────────────────────────────────────────────────────

/// Repository d'auth — singleton, dépend de ApiClient et TokenStorage.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(apiClientProvider),
    TokenStorage(),
  );
});

/// Utilisateur connecté — null si non authentifié.
///
/// Mis à jour par [AuthNotifier] après login/register.
/// Écouté par les widgets qui ont besoin du profil utilisateur.
final currentUserProvider = StateProvider<User?>((ref) => null);

/// Getter pratique : true si un utilisateur est connecté.
final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(accessTokenProvider) != null,
);

// ──────────────────────────────────────────────────────────────────────────────
// AuthNotifier
// ──────────────────────────────────────────────────────────────────────────────

/// Gère le cycle de vie de l'authentification.
///
/// État : [AsyncValue<void>]
/// - `data(null)` → état initial ou après action réussie
/// - `loading()` → action en cours
/// - `error(e, s)` → action échouée (contient [AppException])
///
/// Le router (Plan 05) écoute [accessTokenProvider] via [_RouterNotifier]
/// et redirige automatiquement — [AuthNotifier] ne fait jamais de navigation.
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  /// Connexion avec email + password.
  ///
  /// [🔒 CORRECTIF] `TokenResponse` ne contient jamais d'objet `user` — le
  /// profil est récupéré séparément via [AuthRepository.getMe] une fois les
  /// tokens posés, pour que l'appel authentifié passe par l'intercepteur JWT.
  ///
  /// En cas de succès : met à jour [accessTokenProvider], [currentSessionIdProvider]
  /// et [currentUserProvider]. En cas d'erreur : state = AsyncError contenant l'[AppException].
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final tokens = await _repo.login(email: email, password: password);
      _ref.read(accessTokenProvider.notifier).state = tokens.accessToken;
      _ref.read(currentSessionIdProvider.notifier).state = tokens.sessionId;
      final user = await _repo.getMe();
      _ref.read(currentUserProvider.notifier).state = user;
      // [Plan 14 / corrections §4] Enregistrement best-effort du token push
      // — c'est ici qu'on sait pour la première fois qu'une session valide
      // vient d'être posée (POST /notifications/devices exige
      // get_current_user côté serveur). Ne bloque jamais le login : toutes
      // les erreurs sont avalées dans PushNotificationService.
      unawaited(
        PushNotificationService.registerDeviceToken(
          _ref.read(apiClientProvider),
        ),
      );
    });
  }

  /// Inscription client (email + password + nom complet requis + téléphone optionnel).
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final tokens = await _repo.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      _ref.read(accessTokenProvider.notifier).state = tokens.accessToken;
      _ref.read(currentSessionIdProvider.notifier).state = tokens.sessionId;
      final user = await _repo.getMe();
      _ref.read(currentUserProvider.notifier).state = user;
      // [Plan 14 / corrections §4] Enregistrement best-effort du token push
      // — c'est ici qu'on sait pour la première fois qu'une session valide
      // vient d'être posée (POST /notifications/devices exige
      // get_current_user côté serveur). Ne bloque jamais le login : toutes
      // les erreurs sont avalées dans PushNotificationService.
      unawaited(
        PushNotificationService.registerDeviceToken(
          _ref.read(apiClientProvider),
        ),
      );
    });
  }

  /// Déconnexion — efface les tokens et le profil utilisateur.
  ///
  /// Le router détecte `accessTokenProvider == null` et redirige vers `/home`.
  Future<void> logout() async {
    await _repo.logout();
    _ref.read(accessTokenProvider.notifier).state = null;
    _ref.read(currentSessionIdProvider.notifier).state = null;
    _ref.read(currentUserProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) => AuthNotifier(ref),
);
