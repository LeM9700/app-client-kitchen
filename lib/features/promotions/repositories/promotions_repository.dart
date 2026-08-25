import 'package:dio/dio.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/features/promotions/models/promotion.dart';

/// Repository promotions publiques (Plan 17) — vitrine commerciale, pas
/// d'application de code au panier (Plan 09, hors scope ici).
///
/// [🔒 api-corrections-phase-d.md §7] `GET /promotions` ne requiert pas de
/// JWT mais scope le tenant UNIQUEMENT via le header `X-Tenant-Slug`
/// (`request.headers.get("X-Tenant-Slug", "default")` côté serveur — sans ce
/// header, retombe silencieusement sur le tenant `"default"`). Ce repository
/// passe obligatoirement par [ApiClient] (jamais un `Dio` nu) pour hériter du
/// header posé par `ApiClient.setTenantSlug` au boot.
class PromotionsRepository {
  const PromotionsRepository(this._client);
  final ApiClient _client;

  /// `GET /promotions` — liste des promotions actives, déjà filtrées côté
  /// serveur (voir doc de [Promotion], pas de champ `isActive` à filtrer ici).
  Future<List<Promotion>> getActivePromotions() async {
    try {
      final response =
          await _client.get<List<dynamic>>(ApiEndpoints.promotions);
      return (response.data ?? [])
          .map((e) => Promotion.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}
