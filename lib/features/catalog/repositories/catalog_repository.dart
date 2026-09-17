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

  List<Map<String, dynamic>> _itemsFromPayload(Object? data) {
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List).cast<Map<String, dynamic>>();
    }
    throw const FormatException('Format de catalogue inattendu.');
  }

  /// Retourne toutes les catégories actives triées par [sortOrder].
  Future<List<Category>> getCategories() async {
    try {
      final response = await _client.get<dynamic>(ApiEndpoints.categories);
      return _itemsFromPayload(response.data).map(Category.fromJson).toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Retourne les produits d'une catégorie, triés par [sortOrder].
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    try {
      final response = await _client.get<dynamic>(
        ApiEndpoints.productsByCategory(categoryId),
      );
      return _itemsFromPayload(response.data).map(Product.fromJson).toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Retourne le détail d'un produit par son [productId].
  ///
  /// [displayCurrency] : code ISO 4217 optionnel pour une conversion de prix
  /// indicative (voir [Product.indicativePriceLabel]) — jamais la devise
  /// réellement facturée.
  Future<Product> getProduct(int productId, {String? displayCurrency}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.product(productId),
        queryParameters: displayCurrency == null
            ? null
            : {'display_currency': displayCurrency},
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
  ///
  /// [displayCurrency] : voir [getProduct].
  Future<List<Product>> getFeaturedProducts({String? displayCurrency}) async {
    try {
      final response = await _client.get<dynamic>(
        ApiEndpoints.featuredProducts,
        queryParameters: displayCurrency == null
            ? null
            : {'display_currency': displayCurrency},
      );
      return _itemsFromPayload(response.data).map(Product.fromJson).toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Retourne tous les produits actifs, toutes catégories confondues, sans
  /// filtre — section "Tout le menu" de l'accueil. [pageSize] à 100 (max
  /// serveur) couvre le catalogue d'un restaurant en une seule page ; au-delà,
  /// seule la première page est retournée (pas de pagination infinie ici).
  ///
  /// Contrairement à [getFeaturedProducts]/[getProductsByCategory], cet
  /// endpoint renvoie une enveloppe paginée (`{items, total, page, ...}`),
  /// pas une liste brute.
  ///
  /// [displayCurrency] : voir [getProduct].
  Future<List<Product>> getAllProducts({
    int pageSize = 100,
    String? displayCurrency,
  }) async {
    try {
      final response = await _client.get<dynamic>(
        ApiEndpoints.products,
        queryParameters: {
          'page_size': pageSize,
          if (displayCurrency != null) 'display_currency': displayCurrency,
        },
      );
      return _itemsFromPayload(response.data).map(Product.fromJson).toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}
