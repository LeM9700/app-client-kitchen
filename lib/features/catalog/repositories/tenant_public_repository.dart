import 'package:dio/dio.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/features/catalog/models/tenant_public_info.dart';

class TenantPublicRepository {
  const TenantPublicRepository(this._client);

  final ApiClient _client;

  Future<TenantStatusInfo> fetchStatus(String slug) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.tenantStatus,
        queryParameters: {'tenant_slug': slug},
      );
      return TenantStatusInfo.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  Future<List<BusinessHourInfo>> fetchHours(String slug) async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.tenantHours,
        queryParameters: {'tenant_slug': slug},
      );
      return (response.data ?? const [])
          .whereType<Map>()
          .map(
            (value) => BusinessHourInfo.fromJson(
              Map<String, dynamic>.from(value),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}
