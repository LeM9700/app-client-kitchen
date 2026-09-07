import 'dart:convert';
import 'dart:typed_data';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/auth/token_storage.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/auth_session_provider.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

/// Fake en mémoire de [TokenStorage] pour les tests de rotation.
///
/// Contrairement à un mock statique (une seule valeur stubée pour toute la
/// durée du test), ce fake reflète l'état réel du stockage sécurisé : après
/// [saveRefreshToken], [getRefreshToken] renvoie la valeur la plus récente —
/// exactement ce qu'il faut pour prouver qu'un refresh ultérieur utilise
/// bien le refresh token issu de la dernière rotation, pas le premier.
class _FakeTokenStorage implements TokenStorage {
  String? _refreshToken;
  final List<String> savedRefreshTokens = [];

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> saveRefreshToken(String token) async {
    _refreshToken = token;
    savedRefreshTokens.add(token);
  }

  @override
  Future<void> clearRefreshToken() async => _refreshToken = null;

  @override
  Future<void> clearAll() async => _refreshToken = null;
}

class _AdapterResponse {
  const _AdapterResponse(this.statusCode, this.data);

  final int statusCode;
  final Object? data;
}

class _RecordedRequest {
  _RecordedRequest(RequestOptions options)
      : path = options.path,
        headers = Map<String, dynamic>.from(options.headers),
        data = options.data;

  final String path;
  final Map<String, dynamic> headers;
  final dynamic data;
}

class _QueueHttpClientAdapter implements HttpClientAdapter {
  _QueueHttpClientAdapter(this.responses);

  final List<_AdapterResponse> responses;
  final requests = <_RecordedRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(_RecordedRequest(options));
    final response = responses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(response.data),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Tests unitaires de [ApiClient.handleDioError].
///
/// Cette méthode est statique et pure (pas d'IO, pas de Riverpod) →
/// testable sans mocks complexes.
void main() {
  group('ApiClient.handleDioError', () {
    final opts = RequestOptions(path: '/test');

    test('retourne NetworkException sur connectionTimeout', () {
      final e = DioException(
        requestOptions: opts,
        type: DioExceptionType.connectionTimeout,
      );
      expect(ApiClient.handleDioError(e), isA<NetworkException>());
    });

    test('retourne NetworkException sur receiveTimeout', () {
      final e = DioException(
        requestOptions: opts,
        type: DioExceptionType.receiveTimeout,
      );
      expect(ApiClient.handleDioError(e), isA<NetworkException>());
    });

    test('retourne NetworkException sur connectionError', () {
      final e = DioException(
        requestOptions: opts,
        type: DioExceptionType.connectionError,
      );
      expect(ApiClient.handleDioError(e), isA<NetworkException>());
    });

    test('retourne AuthException sur 401', () {
      final e = DioException(
        requestOptions: opts,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: opts, statusCode: 401),
      );
      expect(ApiClient.handleDioError(e), isA<AuthException>());
    });

    test('retourne AuthException sur 403', () {
      final e = DioException(
        requestOptions: opts,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: opts, statusCode: 403),
      );
      final ex = ApiClient.handleDioError(e);
      expect(ex, isA<AuthException>());
      expect(ex.message, contains('Accès refusé'));
    });

    test('retourne NotFoundException sur 404', () {
      final e = DioException(
        requestOptions: opts,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: opts, statusCode: 404),
      );
      expect(ApiClient.handleDioError(e), isA<NotFoundException>());
    });

    test('retourne ServerException sur 500', () {
      final e = DioException(
        requestOptions: opts,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: opts, statusCode: 500),
      );
      expect(ApiClient.handleDioError(e), isA<ServerException>());
    });

    group('ValidationException sur 422', () {
      test('parse correctement les fieldErrors Pydantic', () {
        final e = DioException(
          requestOptions: opts,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: opts,
            statusCode: 422,
            data: {
              'detail': [
                {
                  'loc': ['body', 'email'],
                  'msg': 'Email invalide',
                },
                {
                  'loc': ['body', 'password'],
                  'msg': 'Trop court',
                },
              ],
            },
          ),
        );
        final ex = ApiClient.handleDioError(e);
        expect(ex, isA<ValidationException>());
        final validation = ex as ValidationException;
        expect(validation.fieldErrors['email'], 'Email invalide');
        expect(validation.fieldErrors['password'], 'Trop court');
      });

      test('retourne fieldErrors vide si detail malformé', () {
        final e = DioException(
          requestOptions: opts,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: opts,
            statusCode: 422,
            data: {'detail': 'not a list'},
          ),
        );
        final ex = ApiClient.handleDioError(e) as ValidationException;
        expect(ex.fieldErrors, isEmpty);
      });
    });
  });

  group('ApiClient auth interceptor', () {
    test('refreshes on 401 and retries the original request', () async {
      final adapter = _QueueHttpClientAdapter([
        const _AdapterResponse(401, {'detail': 'expired'}),
        const _AdapterResponse(200, {
          'access_token': 'new-access-token',
          'refresh_token': 'new-refresh-token',
          'session_id': 7,
        }),
        const _AdapterResponse(200, {'ok': true}),
      ]);
      final dio = Dio()..httpClientAdapter = adapter;
      final storage = MockTokenStorage();
      when(() => storage.getRefreshToken()).thenAnswer(
        (_) async => 'refresh-token',
      );
      when(() => storage.saveRefreshToken(any())).thenAnswer((_) async {});

      late ApiClient client;
      final apiClientProvider = Provider<ApiClient>((ref) {
        client = ApiClient(
          ref,
          dio: dio,
          tokenStorage: storage,
          baseUrl: 'https://api.opizza.example',
        )..setTenantSlug('opizza-prod');
        return client;
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(accessTokenProvider.notifier).state = 'old-access-token';
      container.read(apiClientProvider);

      final response = await client.get<Map<String, dynamic>>('/orders/42');

      expect(response.data, {'ok': true});
      expect(container.read(accessTokenProvider), 'new-access-token');
      expect(container.read(currentSessionIdProvider), 7);
      expect(adapter.requests, hasLength(3));
      expect(adapter.requests[0].path, '/orders/42');
      expect(adapter.requests[1].path, '/auth/refresh');
      expect(adapter.requests[2].path, '/orders/42');
      expect(
        adapter.requests[0].headers['Authorization'],
        'Bearer old-access-token',
      );
      expect(
        adapter.requests[2].headers['Authorization'],
        'Bearer new-access-token',
      );
      expect(adapter.requests[0].headers['X-Tenant-Slug'], 'opizza-prod');
      expect(adapter.requests[2].headers['X-Tenant-Slug'], 'opizza-prod');
      verify(() => storage.getRefreshToken()).called(1);
      // [🔒] La rotation côté API doit être répercutée côté client : le
      // nouveau refresh token renvoyé par /auth/refresh doit être persisté,
      // pas seulement le nouvel access token.
      verify(() => storage.saveRefreshToken('new-refresh-token')).called(1);
    });

    test(
      'utilise le refresh token le plus récent après deux refresh successifs',
      () async {
        final adapter = _QueueHttpClientAdapter([
          // Cycle 1 : requête protégée → 401 → refresh → retry.
          const _AdapterResponse(401, {'detail': 'expired'}),
          const _AdapterResponse(200, {
            'access_token': 'access-token-1',
            'refresh_token': 'refresh-token-1',
            'session_id': 1,
          }),
          const _AdapterResponse(200, {'order': 1}),
          // Cycle 2 : nouvelle requête protégée → 401 → refresh → retry.
          const _AdapterResponse(401, {'detail': 'expired'}),
          const _AdapterResponse(200, {
            'access_token': 'access-token-2',
            'refresh_token': 'refresh-token-2',
            'session_id': 2,
          }),
          const _AdapterResponse(200, {'order': 2}),
        ]);
        final dio = Dio()..httpClientAdapter = adapter;
        final storage = _FakeTokenStorage()
          .._refreshToken = 'initial-refresh-token';

        late ApiClient client;
        final apiClientProvider = Provider<ApiClient>((ref) {
          client = ApiClient(
            ref,
            dio: dio,
            tokenStorage: storage,
            baseUrl: 'https://api.opizza.example',
          )..setTenantSlug('opizza-prod');
          return client;
        });
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(accessTokenProvider.notifier).state =
            'initial-access-token';
        container.read(apiClientProvider);

        // ── Cycle 1 ──────────────────────────────────────────────────────
        final response1 = await client.get<Map<String, dynamic>>('/orders/1');
        expect(response1.data, {'order': 1});
        expect(container.read(accessTokenProvider), 'access-token-1');
        // Le refresh initial utilise bien le token issu du login.
        expect(
          adapter.requests[1].data,
          {'refresh_token': 'initial-refresh-token'},
        );

        // ── Cycle 2 ──────────────────────────────────────────────────────
        final response2 = await client.get<Map<String, dynamic>>('/orders/2');
        expect(response2.data, {'order': 2});
        expect(container.read(accessTokenProvider), 'access-token-2');
        expect(container.read(currentSessionIdProvider), 2);
        // [🔒] Le second refresh doit envoyer le refresh token émis par le
        // PREMIER refresh (rotation), jamais le token initial : côté API,
        // ce dernier a déjà été révoqué lors du cycle 1.
        expect(
          adapter.requests[4].data,
          {'refresh_token': 'refresh-token-1'},
        );

        expect(
          storage.savedRefreshTokens,
          ['refresh-token-1', 'refresh-token-2'],
        );
        expect(await storage.getRefreshToken(), 'refresh-token-2');
      },
    );

    test(
      'déconnecte proprement si le refresh ne renvoie pas de paire complète',
      () async {
        final adapter = _QueueHttpClientAdapter([
          const _AdapterResponse(401, {'detail': 'expired'}),
          // Réponse de refresh incomplète (pas de refresh_token) : ne doit
          // jamais être traitée comme un succès partiel.
          const _AdapterResponse(200, {'access_token': 'new-access-token'}),
        ]);
        final dio = Dio()..httpClientAdapter = adapter;
        final storage = _FakeTokenStorage().._refreshToken = 'refresh-token';

        late ApiClient client;
        final apiClientProvider = Provider<ApiClient>((ref) {
          client = ApiClient(
            ref,
            dio: dio,
            tokenStorage: storage,
            baseUrl: 'https://api.opizza.example',
          )..setTenantSlug('opizza-prod');
          return client;
        });
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(accessTokenProvider.notifier).state = 'old-access-token';
        container.read(currentSessionIdProvider.notifier).state = 1;
        container.read(apiClientProvider);

        // L'erreur 401 d'origine doit remonter à l'appelant — pas de retry
        // silencieux, pas de boucle : une seule tentative de refresh a eu
        // lieu (2 requêtes en tout : la requête protégée + le refresh).
        await expectLater(
          client.get<Map<String, dynamic>>('/orders/42'),
          throwsA(isA<DioException>()),
        );

        expect(adapter.requests, hasLength(2));
        expect(container.read(accessTokenProvider), isNull);
        expect(container.read(currentSessionIdProvider), isNull);
        expect(storage.savedRefreshTokens, isEmpty);
        expect(await storage.getRefreshToken(), isNull);
      },
    );
  });
}
