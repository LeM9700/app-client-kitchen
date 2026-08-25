import 'package:dio/dio.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';

/// Repository favoris — `GET`/`POST /favorites`, `DELETE /favorites/{id}`.
/// Miroir de `api-pizza/app/modules/favorites/router.py`.
class FavoritesRepository {
  const FavoritesRepository(this._client);
  final ApiClient _client;

  /// `GET /favorites` — retourne les identifiants produits favoris de
  /// l'utilisateur courant.
  Future<Set<int>> list() async {
    try {
      final response =
          await _client.get<List<dynamic>>(ApiEndpoints.favorites);
      return (response.data as List)
          .map((e) => (e as Map<String, dynamic>)['product_id'] as int)
          .toSet();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// `POST /favorites` — idempotent côté serveur (voir
  /// `api-pizza/app/modules/favorites/router.py::add_favorite`).
  Future<void> add(int productId) async {
    try {
      await _client.post<Map<String, dynamic>>(
        ApiEndpoints.favorites,
        data: {'product_id': productId},
      );
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// `DELETE /favorites/{product_id}` — idempotent côté serveur, ne lève pas
  /// si le produit n'était pas favori.
  Future<void> remove(int productId) async {
    try {
      await _client.delete<void>(ApiEndpoints.favorite(productId));
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}
