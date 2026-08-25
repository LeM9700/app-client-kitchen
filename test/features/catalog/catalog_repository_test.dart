import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/features/catalog/models/category.dart';
import 'package:app_client/features/catalog/repositories/catalog_repository.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Mocks (mocktail — cohérent avec test/features/auth/auth_repository_test.dart
// et test/features/checkout/checkout_provider_test.dart)
// ──────────────────────────────────────────────────────────────────────────────

class MockApiClient extends Mock implements ApiClient {}

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

// ──────────────────────────────────────────────────────────────────────────────
// Fixtures — les clés reflètent le JSON réel de l'API (`base_price`,
// `is_active`, `allergens` en objets `{allergen_id, name, slug}`), voir
// `lib/features/catalog/models/product.dart` (`_allergensFromJson` extrait le
// `slug` de chaque objet) et `category.dart`.
// ──────────────────────────────────────────────────────────────────────────────

const _categoryJson = {
  'id': 1,
  'name': 'Pizzas',
  'description': 'Nos pizzas au feu de bois',
  'image_url': null,
  'sort_order': 1,
  'is_active': true,
};

const _productJson = {
  'id': 42,
  'name': 'Margherita',
  'base_price': 10.5,
  'category_id': 1,
  'description': 'Tomate, mozzarella, basilic',
  'image_url': null,
  'allergens': [
    {'allergen_id': 1, 'name': 'Gluten', 'slug': 'gluten'},
  ],
  'variants': <dynamic>[],
  'extras': <dynamic>[],
  'is_active': true,
  'is_featured': false,
  'sort_order': 0,
};

void main() {
  late MockApiClient mockClient;
  late CatalogRepository repo;

  setUp(() {
    mockClient = MockApiClient();
    repo = CatalogRepository(mockClient);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // getCategories()
  // ──────────────────────────────────────────────────────────────────────────

  group('getCategories()', () {
    test('mappe la liste JSON en List<Category>', () async {
      when(() => mockClient.get<List<dynamic>>(ApiEndpoints.categories))
          .thenAnswer((_) async => _response([_categoryJson]));

      final result = await repo.getCategories();

      expect(result, hasLength(1));
      expect(result.first, isA<Category>());
      expect(result.first.id, 1);
      expect(result.first.name, 'Pizzas');
      expect(result.first.sortOrder, 1);
    });

    test('convertit une DioException 500 en ServerException', () {
      when(() => mockClient.get<List<dynamic>>(ApiEndpoints.categories))
          .thenThrow(_dioError(500, {'detail': 'boom'}));

      expect(() => repo.getCategories(), throwsA(isA<ServerException>()));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // getProductsByCategory()
  // ──────────────────────────────────────────────────────────────────────────

  group('getProductsByCategory()', () {
    test(
        'mappe base_price → price, is_active → isAvailable, allergens (objets) → slugs',
        () async {
      when(
        () => mockClient.get<List<dynamic>>(ApiEndpoints.productsByCategory(1)),
      ).thenAnswer((_) async => _response([_productJson]));

      final result = await repo.getProductsByCategory(1);

      expect(result, hasLength(1));
      final product = result.first;
      expect(product.id, 42);
      expect(product.price, 10.5); // base_price
      expect(product.isAvailable, true); // is_active
      expect(product.allergens, ['gluten']); // slug extrait de l'objet
    });

    test('convertit une DioException 404 en NotFoundException', () {
      when(
        () =>
            mockClient.get<List<dynamic>>(ApiEndpoints.productsByCategory(99)),
      ).thenThrow(_dioError(404, {'detail': 'Catégorie introuvable'}));

      expect(
        () => repo.getProductsByCategory(99),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // getProduct()
  // ──────────────────────────────────────────────────────────────────────────

  group('getProduct()', () {
    test('retourne le détail produit mappé', () async {
      when(() => mockClient.get<Map<String, dynamic>>(ApiEndpoints.product(42)))
          .thenAnswer((_) async => _response(_productJson));

      final product = await repo.getProduct(42);

      expect(product.id, 42);
      expect(product.name, 'Margherita');
      expect(product.price, 10.5);
    });

    test('convertit une DioException réseau en NetworkException', () {
      when(() => mockClient.get<Map<String, dynamic>>(ApiEndpoints.product(42)))
          .thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(() => repo.getProduct(42), throwsA(isA<NetworkException>()));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // search()
  // ──────────────────────────────────────────────────────────────────────────

  group('search()', () {
    test('envoie q + allergens joints par virgule, injecte query côté client',
        () async {
      when(
        () => mockClient.get<Map<String, dynamic>>(
          ApiEndpoints.catalogSearch,
          queryParameters: {'q': 'margherita', 'allergens': 'gluten,milk'},
        ),
      ).thenAnswer(
        (_) async => _response({
          'products': [_productJson],
          'total': 1,
        }),
      );

      final result = await repo.search(
        'margherita',
        allergens: ['gluten', 'milk'],
      );

      expect(result.total, 1);
      expect(result.products, hasLength(1));
      // `query` est absent du payload serveur — injecté côté client par
      // `..putIfAbsent('query', () => query)`.
      expect(result.query, 'margherita');
    });

    test('n\'envoie pas de paramètre allergens si la liste est vide', () async {
      when(
        () => mockClient.get<Map<String, dynamic>>(
          ApiEndpoints.catalogSearch,
          queryParameters: {'q': 'pizza'},
        ),
      ).thenAnswer(
        (_) async => _response({
          'products': <dynamic>[],
          'total': 0,
        }),
      );

      final result = await repo.search('pizza');

      expect(result.total, 0);
      verify(
        () => mockClient.get<Map<String, dynamic>>(
          ApiEndpoints.catalogSearch,
          queryParameters: {'q': 'pizza'},
        ),
      ).called(1);
    });

    test('convertit une DioException en AppException', () {
      when(
        () => mockClient.get<Map<String, dynamic>>(
          ApiEndpoints.catalogSearch,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(_dioError(500, {'detail': 'boom'}));

      expect(() => repo.search('x'), throwsA(isA<ServerException>()));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // getFeaturedProducts()
  // ──────────────────────────────────────────────────────────────────────────

  group('getFeaturedProducts()', () {
    test('mappe la liste de produits vedettes', () async {
      when(() => mockClient.get<List<dynamic>>(ApiEndpoints.featuredProducts))
          .thenAnswer((_) async => _response([_productJson]));

      final result = await repo.getFeaturedProducts();

      expect(result, hasLength(1));
      expect(result.first.id, 42);
    });

    test('convertit une DioException en AppException', () {
      when(() => mockClient.get<List<dynamic>>(ApiEndpoints.featuredProducts))
          .thenThrow(_dioError(500, null));

      expect(() => repo.getFeaturedProducts(), throwsA(isA<ServerException>()));
    });
  });
}
