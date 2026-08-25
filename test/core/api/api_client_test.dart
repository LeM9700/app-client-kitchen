import 'dart:convert';
import 'dart:typed_data';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/auth/token_storage.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

class _AdapterResponse {
  const _AdapterResponse(this.statusCode, this.data);

  final int statusCode;
  final Object? data;
}

class _RecordedRequest {
  _RecordedRequest(RequestOptions options)
      : path = options.path,
        headers = Map<String, dynamic>.from(options.headers);

  final String path;
  final Map<String, dynamic> headers;
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
        const _AdapterResponse(200, {'access_token': 'new-access-token'}),
        const _AdapterResponse(200, {'ok': true}),
      ]);
      final dio = Dio()..httpClientAdapter = adapter;
      final storage = MockTokenStorage();
      when(() => storage.getRefreshToken()).thenAnswer(
        (_) async => 'refresh-token',
      );

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
    });
  });
}
