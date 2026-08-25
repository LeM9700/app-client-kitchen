import 'package:dio/dio.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/core/auth/token_storage.dart';
import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/features/account/models/session.dart';
import 'package:app_client/features/auth/models/auth_tokens.dart';
import 'package:app_client/features/auth/models/user.dart';

/// Repository d'authentification.
///
/// Responsabilités :
/// - Appels HTTP vers les endpoints `/auth/*` et `/customer/*`.
/// - Persistance du refresh token via [TokenStorage].
/// - Conversion [DioException] → [AppException].
///
/// Ne touche PAS à [accessTokenProvider] — c'est [AuthNotifier] qui gère
/// la mise à jour du token en mémoire.
///
/// [🔒 CORRECTIF] `TokenResponse` (login/register) ne contient jamais d'objet
/// `user` imbriqué — seulement `access_token`/`refresh_token`/`session_id`.
/// [login]/[register] retournent donc uniquement les tokens ; c'est à
/// [AuthNotifier] d'enchaîner avec [getMe] pour peupler le profil.
class AuthRepository {
  const AuthRepository(this._client, this._storage);

  final ApiClient _client;
  final TokenStorage _storage;

  /// Connexion email + password.
  ///
  /// [🔒 CORRECTIF] `LoginRequest` exige `tenant_slug` dans le BODY (pas
  /// seulement le header `X-Tenant-Slug`) — sans lui l'appel échoue en 422.
  /// Sauvegarde le refresh token en secure storage.
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {
          'tenant_slug': Env.tenantSlug,
          'email': email,
          'password': password,
        },
      );
      final tokens = AuthTokens.fromJson(response.data!);
      await _storage.saveRefreshToken(tokens.refreshToken);
      return tokens;
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Inscription client (email + password + nom complet requis + téléphone optionnel).
  ///
  /// [🔒 CORRECTIF] `/auth/register` crée un TENANT (restaurant) — ce n'est
  /// PAS l'inscription d'un client. L'inscription client passe par
  /// `/customer/register` (`CustomerRegisterRequest`), qui exige
  /// `full_name` (obligatoire, pas optionnel) et accepte `phone` (optionnel).
  /// Le header `X-Tenant-Slug` est déjà injecté par défaut sur [ApiClient]
  /// (voir [ApiClient.setTenantSlug], appelé au boot dans `SplashScreen`).
  ///
  /// L'utilisateur est connecté immédiatement après inscription.
  /// [emailVerified] sera false — un bandeau non bloquant l'informera.
  Future<AuthTokens> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.customerRegister,
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      final tokens = AuthTokens.fromJson(response.data!);
      await _storage.saveRefreshToken(tokens.refreshToken);
      return tokens;
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Demande de réinitialisation de mot de passe.
  ///
  /// L'API envoie un email à [email] si le compte existe.
  /// Réponse toujours 200 (pas de user enumeration).
  Future<void> forgotPassword(String email) async {
    try {
      await _client.post<void>(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Retourne le profil de l'utilisateur connecté.
  ///
  /// [🔒 CORRECTIF] `/auth/me` a un bug serveur connu : `phone` (ajouté en
  /// migration 0030) n'est pas renseigné dans la réponse alors que
  /// `UserOut.phone` est un champ requis côté schéma — l'appel peut échouer
  /// en 500. `/customer/me` (`CustomerOut`) est l'endpoint dédié au profil
  /// client, il renseigne `phone` correctement : on l'utilise à la place.
  Future<User> getMe() async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>(ApiEndpoints.customerMe);
      return User.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Met à jour le profil (nom complet et/ou téléphone) via `PATCH /customer/me`.
  Future<User> updateProfile({String? fullName, String? phone}) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        ApiEndpoints.customerMe,
        data: {
          if (fullName != null) 'full_name': fullName,
          if (phone != null) 'phone': phone,
        },
      );
      return User.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Déconnexion — révoque le token côté serveur et efface le storage local.
  ///
  /// [⚠️ PROD] Le `clearAll()` est dans le `finally` : même si l'appel API
  /// échoue (réseau absent), les tokens locaux sont effacés. L'utilisateur
  /// ne reste jamais en état "pseudo-connecté".
  Future<void> logout() async {
    try {
      await _client.post<void>(ApiEndpoints.logout);
    } catch (_) {
      // Ignorer les erreurs réseau — déconnexion locale garantie.
    } finally {
      await _storage.clearAll();
    }
  }

  /// Liste les sessions actives de l'utilisateur.
  ///
  /// [🔒 CORRECTIF api-corrections-phase-d.md §8] `SessionOut` n'a PAS de
  /// champ `device_type`/`ip` (hypothèses erronées du plan d'origine) —
  /// parsé dans le modèle typé [Session] (`user_agent`/`ip_address` réels).
  /// [currentSessionId] (obtenu au login/register via [AuthTokens.sessionId])
  /// est transmis en query param pour que l'API marque `is_current: true`
  /// sur la bonne entrée — sans lui, aucune session n'est signalée comme
  /// courante.
  Future<List<Session>> getSessions({int? currentSessionId}) async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.sessions,
        queryParameters: {
          if (currentSessionId != null) 'current_session_id': currentSessionId,
        },
      );
      return (response.data as List)
          .map((e) => Session.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Révoque une session spécifique par son [sessionId].
  ///
  /// [🔒 CORRECTIF api-corrections-phase-d.md §8] Les ids de session sont des
  /// `int` (PK SERIAL), pas des `String` — le plan d'origine supposait le
  /// mauvais type de paramètre.
  Future<void> revokeSession(int sessionId) async {
    try {
      await _client.delete<void>('${ApiEndpoints.sessions}/$sessionId');
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Change le mot de passe de l'utilisateur connecté.
  ///
  /// `POST /auth/change-password` `{current_password, new_password}`
  /// (`ChangePasswordRequest`, `api-pizza/app/modules/auth/schemas.py`).
  /// Politique serveur sur [newPassword] : min 8 caractères, ≥1 majuscule,
  /// ≥1 chiffre, ≥1 caractère parmi `!@#$%^&*` — un manquement lève une
  /// [ValidationException] 422 (Pydantic) avec `fieldErrors['new_password']`.
  /// Un [currentPassword] incorrect lève une [AuthException] 401
  /// (`INVALID_CREDENTIALS`), pas une erreur de champ 422.
  ///
  /// [⚠️ PROD] Succès → le serveur révoque tous les refresh tokens actifs
  /// (autres appareils déconnectés) mais PAS le JTI de l'access token
  /// courant : l'app reste connectée localement sans action supplémentaire.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.post<void>(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}
