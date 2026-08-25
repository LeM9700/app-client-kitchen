import 'package:dio/dio.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/models/tenant_branding.dart';

/// Repository responsable du chargement du branding tenant.
///
/// Appelle [GET /tenant/branding] (endpoint public, sans auth).
/// Le slug est passé en query param car l'header [X-Tenant-Slug] est
/// déjà positionné globalement par [ApiClient.setTenantSlug()].
class BrandingRepository {
  const BrandingRepository(this._client);

  final ApiClient _client;

  /// Charge le branding du tenant identifié par [slug].
  ///
  /// Le [slug] est injecté dans la réponse JSON avant parsing car l'API
  /// ne le retourne pas (économie de bande passante — il est connu du client).
  ///
  /// Throws [AppException] si l'appel échoue.
  Future<TenantBranding> fetchBranding(String slug) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.tenantBranding,
        queryParameters: {'tenant_slug': slug},
      );

      final data = Map<String, dynamic>.from(response.data ?? {});
      // Injection du slug côté client — non retourné par l'API.
      data['slug'] = slug;

      return TenantBranding.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}
