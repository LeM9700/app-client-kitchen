import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/auth/token_storage.dart';
import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/auth_session_provider.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';

/// Client HTTP singleton de l'application.
///
/// Responsabilités :
/// - Attacher le header `X-Tenant-Slug` sur toutes les requêtes.
/// - Attacher le `Bearer` token si l'utilisateur est authentifié.
/// - Rafraîchir automatiquement la paire access/refresh token (rotation)
///   sur réponse 401.
/// - Déconnecter proprement l'utilisateur si le refresh échoue.
/// - Convertir les [DioException] en [AppException] (via [handleDioError]).
///
/// Les repositories n'instancient jamais [Dio] directement — ils consomment
/// uniquement [ApiClient] via [apiClientProvider].
class ApiClient {
  /// Construit le client et enregistre l'intercepteur JWT.
  ApiClient(
    this._ref, {
    Dio? dio,
    TokenStorage? tokenStorage,
    String baseUrl = Env.apiBaseUrl,
  })  : _dio = dio ?? Dio(_baseOptions(baseUrl)),
        _storage = tokenStorage ?? TokenStorage() {
    if (dio != null) {
      _applyDefaultOptions(_dio, baseUrl);
    }
    _dio.interceptors.add(_buildAuthInterceptor());
  }

  final Ref _ref;
  final Dio _dio;
  final TokenStorage _storage;

  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static BaseOptions _baseOptions(String baseUrl) {
    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        ..._defaultHeaders,
        'X-Tenant-Slug': Env.tenantSlug,
      },
    );
  }

  static void _applyDefaultOptions(Dio dio, String baseUrl) {
    if (dio.options.baseUrl.isEmpty) {
      dio.options.baseUrl = baseUrl;
    }
    dio.options.connectTimeout ??= const Duration(seconds: 10);
    dio.options.receiveTimeout ??= const Duration(seconds: 30);
    dio.options.headers.addAll(_defaultHeaders);
    dio.options.headers.putIfAbsent('X-Tenant-Slug', () => Env.tenantSlug);
  }

  /// Garde pour éviter les boucles de refresh en cas de requêtes concurrentes.
  bool _isRefreshing = false;

  // ──────────────────────────────────────────────────────────────────────────
  // API publique — proxies vers Dio
  // ──────────────────────────────────────────────────────────────────────────

  /// GET [path] avec [queryParameters] optionnels.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters, options: options);

  /// POST [path] avec [data] en body.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.post<T>(path, data: data, options: options);

  /// PATCH [path] avec [data] en body.
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.patch<T>(path, data: data, options: options);

  /// DELETE [path].
  Future<Response<T>> delete<T>(
    String path, {
    Options? options,
  }) =>
      _dio.delete<T>(path, options: options);

  // ──────────────────────────────────────────────────────────────────────────
  // Tenant slug
  // ──────────────────────────────────────────────────────────────────────────

  /// Injecte `X-Tenant-Slug` dans les headers par défaut de Dio.
  ///
  /// Appelé une seule fois au démarrage (SplashScreen, Plan 05)
  /// après avoir lu [Env.tenantSlug].
  void setTenantSlug(String slug) {
    _dio.options.headers['X-Tenant-Slug'] = slug;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Intercepteur JWT
  // ──────────────────────────────────────────────────────────────────────────

  InterceptorsWrapper _buildAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // Attach Bearer token si disponible en mémoire.
        final token = _ref.read(accessTokenProvider);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // [🔒] Ne pas boucler sur l'endpoint de refresh lui-même.
        final isRefreshEndpoint =
            error.requestOptions.path.contains('/auth/refresh');
        if (isRefreshEndpoint) {
          return handler.next(error);
        }

        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          try {
            final newToken = await _tryRefresh();
            if (newToken != null) {
              // Mettre à jour le token en mémoire.
              _ref.read(accessTokenProvider.notifier).state = newToken;
              // Rejouer la requête originale avec le nouveau token.
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newToken';
              final retryResponse = await _dio.fetch<dynamic>(opts);
              return handler.resolve(retryResponse);
            }
            // [🔒 CORRECTIF] `_tryRefresh` renvoie `null` sans lever
            // d'exception quand l'API ne renvoie pas de paire complète
            // (refresh token absent/révoqué) — sans ce branchement, la
            // session restait "valide" en mémoire (access token jamais nettoyé)
            // alors qu'aucun renouvellement n'a pu avoir lieu.
            await _doLogout();
          } catch (_) {
            // Refresh échoué (token révoqué, session expirée) → déconnexion.
            await _doLogout();
          } finally {
            _isRefreshing = false;
          }
        }

        handler.next(error);
      },
    );
  }

  /// Tente de rafraîchir la paire access/refresh token via
  /// [ApiEndpoints.refresh].
  ///
  /// [🔒 CORRECTIF] L'API pratique une rotation du refresh token à chaque
  /// appel : le refresh token utilisé dans la requête est immédiatement
  /// révoqué côté serveur et remplacé par celui renvoyé dans la réponse
  /// (`TokenResponse.refresh_token`). L'ancien code ne persistait jamais ce
  /// nouveau refresh token — le prochain renouvellement retentait alors
  /// l'ancien token révoqué et échouait systématiquement (session invalidée
  /// prématurément). On persiste donc ici la paire complète, et on ne
  /// considère le refresh réussi que si l'API a bien renvoyé un nouveau
  /// refresh token : continuer avec l'ancien serait sinon voué à l'échec au
  /// prochain cycle.
  ///
  /// Met aussi à jour [currentSessionIdProvider] si l'API renvoie un nouvel
  /// identifiant de session (`session_id`), et retourne le nouvel access
  /// token si le refresh réussit, `null` sinon.
  Future<String?> _tryRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return null;

    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    final data = response.data;
    final newAccessToken = data?['access_token'] as String?;
    final newRefreshToken = data?['refresh_token'] as String?;
    if (newAccessToken == null || newRefreshToken == null) return null;

    await _storage.saveRefreshToken(newRefreshToken);

    final newSessionId = data?['session_id'] as int?;
    if (newSessionId != null) {
      _ref.read(currentSessionIdProvider.notifier).state = newSessionId;
    }

    return newAccessToken;
  }

  /// Déconnexion propre : vide l'access token et l'id de session en mémoire,
  /// et le refresh token en storage sécurisé.
  ///
  /// Le router guard (Plan 05) détecte `accessTokenProvider == null` et
  /// redirige vers `/auth/login`.
  Future<void> _doLogout() async {
    _ref.read(accessTokenProvider.notifier).state = null;
    _ref.read(currentSessionIdProvider.notifier).state = null;
    await _storage.clearRefreshToken();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Conversion d'erreurs
  // ──────────────────────────────────────────────────────────────────────────

  /// Convertit une [DioException] en [AppException] typée.
  ///
  /// À appeler dans le `catch (e)` de chaque repository :
  /// ```dart
  /// } on DioException catch (e) {
  ///   throw ApiClient.handleDioError(e);
  /// }
  /// ```
  ///
  /// Les screens ne manipulent jamais [DioException] directement.
  ///
  /// [🔒 CORRECTIF] api-pizza renvoie DEUX formats d'erreur distincts selon
  /// l'origine du rejet (aucun `RequestValidationError` handler custom n'est
  /// enregistré, voir `api-pizza/app/main.py`) :
  /// 1. Échec de validation Pydantic automatique (body/query malformé) :
  ///    `{"detail": [{"loc": [...], "msg": "...", "type": "..."}]}`.
  /// 2. Erreur métier levée via `AppError` (ex. INSUFFICIENT_POINTS,
  ///    DELIVERY_ZONE_UNREACHABLE) : `{"code": "...", "detail": "message
  ///    humain", "field": "nom_du_champ_ou_null"}` — et ce sur N'IMPORTE
  ///    QUEL statut 4xx (400/401/403/404/409/422), pas seulement 422.
  /// Les deux formes doivent être reconnues, sinon un message d'erreur
  /// métier explicite (ex. "hors zone de livraison") se réduit à un message
  /// générique par statut HTTP.
  static AppException handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        final data = e.response?.data;
        final appErrorMessage = _extractAppErrorMessage(data);
        final fieldErrors = _parseValidationErrors(data);
        // [🔒 CORRECTIF] Un `AppError` avec un `field` non nul (ex. 400/409
        // métier) doit devenir une [ValidationException] quel que soit le
        // statut HTTP — sinon un fieldErrors non vide est calculé puis
        // silencieusement jeté par le `switch` ci-dessous, qui ne branchait
        // ce cas que sur 422 (bug repéré lors du polish transversal — la
        // note ci-dessus prétendait déjà couvrir "n'importe quel statut
        // 4xx", ce qui n'était vrai que pour le message, pas pour les
        // erreurs de champ).
        if (fieldErrors.isNotEmpty) {
          return ValidationException(
            fieldErrors: fieldErrors,
            message: appErrorMessage ?? 'Données invalides.',
          );
        }
        // [🔧] `switch` sur un sujet nullable : le pattern relationnel `>= 500`
        // exige un sujet non-nullable dans les versions récentes du SDK Dart —
        // on retombe sur `0` (capturé par le `_` générique) si absent.
        return switch (e.response?.statusCode ?? 0) {
          401 => AuthException(
              appErrorMessage ?? 'Session expirée. Reconnectez-vous.',
            ),
          403 => AuthException(appErrorMessage ?? 'Accès refusé.'),
          404 => NotFoundException(appErrorMessage ?? 'Ressource introuvable.'),
          422 => ValidationException(
              fieldErrors: const {},
              message: appErrorMessage ?? 'Données invalides.',
            ),
          >= 500 => ServerException(
              appErrorMessage ??
                  'Erreur serveur. Réessayez dans quelques instants.',
            ),
          _ => ServerException(
              appErrorMessage ??
                  'Erreur inattendue (${e.response?.statusCode}).',
            ),
        };

      // cancel, unknown, badCertificate
      default:
        return const NetworkException();
    }
  }

  /// Parse les erreurs de champ, sous les deux formats possibles :
  /// - Pydantic : `{"detail": [{"loc": ["body", "email"], "msg": "..."}, ...]}`
  /// - `AppError` métier : `{"code": "...", "detail": "message", "field": "nom"}`
  ///   (mappé sur une seule entrée si `field` est renseigné).
  static Map<String, String> _parseValidationErrors(dynamic data) {
    if (data is! Map<String, dynamic>) return {};
    final detail = data['detail'];
    if (detail is List) {
      return {
        for (final item in detail)
          if (item is Map<String, dynamic>)
            // Prend le dernier élément de `loc` comme clé de champ.
            (item['loc'] as List?)?.lastOrNull?.toString() ?? 'field':
                item['msg']?.toString() ?? 'Erreur',
      };
    }
    if (detail is String && data['field'] is String) {
      return {data['field'] as String: detail};
    }
    return {};
  }

  /// Extrait le message humain d'une erreur `AppError` (`{"detail": "..."}`),
  /// quel que soit le statut HTTP. Retourne `null` pour le format Pydantic
  /// (`detail` y est une `List`, pas une `String`).
  static String? _extractAppErrorMessage(dynamic data) {
    if (data is Map<String, dynamic> && data['detail'] is String) {
      return data['detail'] as String;
    }
    return null;
  }
}
