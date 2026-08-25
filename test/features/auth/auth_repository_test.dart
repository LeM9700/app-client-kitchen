import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/auth/token_storage.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/features/auth/repositories/auth_repository.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Mocks (mocktail — pas de build_runner requis)
// ──────────────────────────────────────────────────────────────────────────────

class MockApiClient extends Mock implements ApiClient {}

class MockTokenStorage extends Mock implements TokenStorage {}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

Response<T> _response<T>(T data, {int statusCode = 200}) => Response<T>(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: ''),
    );

DioException _dioError(int statusCode, Object? data) => DioException(
      requestOptions: RequestOptions(path: ''),
      response: Response(
        statusCode: statusCode,
        data: data,
        requestOptions: RequestOptions(path: ''),
      ),
      type: DioExceptionType.badResponse,
    );

// [🔧] `TokenResponse` (login/register) ne contient jamais d'objet `user`
// imbriqué — seulement access_token/refresh_token/token_type/session_id
// (voir api-corrections-phase-d.md §0/§1). Le profil est récupéré séparément
// via `getMe()`, ce fichier de test datait d'avant cette correction.
const _loginPayload = {
  'access_token': 'acc_123',
  'refresh_token': 'ref_456',
  'token_type': 'bearer',
  'session_id': 42,
};

void main() {
  late MockApiClient mockClient;
  late MockTokenStorage mockStorage;
  late AuthRepository repo;

  setUp(() {
    mockClient = MockApiClient();
    mockStorage = MockTokenStorage();
    repo = AuthRepository(mockClient, mockStorage);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // login()
  // ──────────────────────────────────────────────────────────────────────────

  group('login()', () {
    test(
        'retourne les tokens (sans user imbriqué) et sauvegarde le refresh token',
        () async {
      Map<String, dynamic>? sentBody;
      when(
        () => mockClient.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer((invocation) async {
        sentBody = invocation.namedArguments[#data] as Map<String, dynamic>;
        return _response(_loginPayload);
      });
      when(() => mockStorage.saveRefreshToken(any())).thenAnswer((_) async {});

      final tokens =
          await repo.login(email: 'test@example.com', password: 'pass1234');

      expect(tokens.accessToken, 'acc_123');
      expect(tokens.refreshToken, 'ref_456');
      expect(tokens.sessionId, 42);
      // `LoginRequest` exige `tenant_slug` dans le body — pas seulement le
      // header `X-Tenant-Slug` (voir api-corrections-phase-d.md §0).
      expect(sentBody?['tenant_slug'], isNotNull);
      verify(() => mockStorage.saveRefreshToken('ref_456')).called(1);
    });

    test('convertit DioException 401 en AuthException', () {
      when(
        () => mockClient.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(_dioError(401, {'detail': 'Invalid credentials'}));

      expect(
        () => repo.login(email: 'bad@example.com', password: 'wrong'),
        throwsA(isA<AuthException>()),
      );
    });

    test('convertit DioException 422 en ValidationException avec fieldErrors',
        () async {
      when(
        () => mockClient.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        _dioError(422, {
          'detail': [
            {
              'loc': ['body', 'email'],
              'msg': 'invalid email',
            },
          ],
        }),
      );

      try {
        await repo.login(email: 'not-an-email', password: 'pass1234');
        fail('devrait throw ValidationException');
      } on ValidationException catch (e) {
        expect(e.fieldErrors['email'], 'invalid email');
      }
    });

    test('convertit DioException réseau en NetworkException', () {
      when(
        () => mockClient.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        () => repo.login(email: 'test@example.com', password: 'pass1234'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // register()
  // ──────────────────────────────────────────────────────────────────────────

  group('register()', () {
    const registerPayload = {
      'access_token': 'acc_new',
      'refresh_token': 'ref_new',
      'token_type': 'bearer',
      'session_id': 99,
    };

    test(
        'inscription réussie — appelle /customer/register avec full_name requis',
        () async {
      Map<String, dynamic>? sentBody;
      when(
        () => mockClient.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer((invocation) async {
        sentBody = invocation.namedArguments[#data] as Map<String, dynamic>;
        return _response(registerPayload, statusCode: 201);
      });
      when(() => mockStorage.saveRefreshToken(any())).thenAnswer((_) async {});

      final tokens = await repo.register(
        email: 'new@example.com',
        password: 'pass1234',
        fullName: 'Nouvel Utilisateur',
      );

      expect(tokens.accessToken, 'acc_new');
      expect(tokens.sessionId, 99);
      expect(sentBody?['full_name'], 'Nouvel Utilisateur');
      expect(sentBody?.containsKey('phone'), false);
      verify(() => mockStorage.saveRefreshToken('ref_new')).called(1);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // logout()
  // ──────────────────────────────────────────────────────────────────────────

  group('logout()', () {
    test('efface le storage même si le POST échoue', () async {
      when(() => mockClient.post<void>(any())).thenThrow(Exception('network'));
      when(() => mockStorage.clearAll()).thenAnswer((_) async {});

      await repo.logout(); // ne doit pas throw

      verify(() => mockStorage.clearAll()).called(1);
    });

    test('efface le storage après un POST réussi', () async {
      when(() => mockClient.post<void>(any()))
          .thenAnswer((_) async => _response<void>(null));
      when(() => mockStorage.clearAll()).thenAnswer((_) async {});

      await repo.logout();

      verify(() => mockStorage.clearAll()).called(1);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // forgotPassword()
  // ──────────────────────────────────────────────────────────────────────────

  group('forgotPassword()', () {
    test('complète sans erreur sur 200', () async {
      when(
        () => mockClient.post<void>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => _response<void>(null));

      await expectLater(
        repo.forgotPassword('test@example.com'),
        completes,
      );
    });
  });
}
