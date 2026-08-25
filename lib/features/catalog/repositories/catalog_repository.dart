import 'package:dio/dio.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/features/catalog/models/category.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/models/search_result.dart';

/// Repository catalogue — accès lecture seule, pas d'auth requise.
///
/// Toutes les méthodes sont publiques : le catalogue est visible sans connexion
/// (décision d'architecture Plan 07 : maximiser la rétention avant checkout).
///
/// [⚡ PERF] Pas de cache local ici — la mise en cache est déléguée aux
/// providers Riverpod via [keepAlive] et [FutureProvider.family].
class CatalogRepository {
  const CatalogRepository(this._client);

  final ApiClient _client;

  /// Retourne toutes les catégories actives triées par [sortOrder].
  Future<List<Category>> getCategories() async {
    try {
      final response =
          await _client.get<List<dynamic>>(ApiEndpoints.categories);
      return (response.data as List)
          .cast<Map<String, dynamic>>()
          .map(Category.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Retourne les produits d'une catégorie, triés par [sortOrder].
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.productsByCategory(categoryId),
      );
      return (response.data as List)
          .cast<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Retourne le détail d'un produit par son [productId].
  Future<Product> getProduct(int productId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.product(productId),
      );
      return Product.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Recherche full-text dans le catalogue.
  ///
  /// [query] : terme de recherche (min 2 caractères recommandé).
  /// [allergens] : liste de codes EU pour filtrage (ex: ['gluten', 'milk']).
  Future<SearchResult> search(
    String query, {
    List<String> allergens = const [],
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.catalogSearch,
        queryParameters: {
          'q': query,
          if (allergens.isNotEmpty) 'allergens': allergens.join(','),
        },
      );
      return SearchResult.fromJson(
        Map<String, dynamic>.from(response.data ?? {})
          ..putIfAbsent('query', () => query),
      );
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Retourne les produits "en vedette" pour la section homepage hero.
  Future<List<Product>> getFeaturedProducts() async {
    try {
      final response =
          await _client.get<List<dynamic>>(ApiEndpoints.featuredProducts);
      return (response.data as List)
          .cast<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}
