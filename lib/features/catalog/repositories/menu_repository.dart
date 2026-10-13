import 'package:dio/dio.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/features/catalog/models/menu.dart';

class MenuRepository {
  const MenuRepository(this._client);

  final ApiClient _client;

  Future<List<CatalogMenu>> getMenus({int pageSize = 100}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.menus,
        queryParameters: {'page': 1, 'page_size': pageSize},
      );
      return (response.data?['items'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (value) => CatalogMenu.fromJson(
              Map<String, dynamic>.from(value),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiClient.handleDioError(error);
    }
  }

  Future<CatalogMenu> getMenu(int menuId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.menu(menuId),
      );
      return CatalogMenu.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiClient.handleDioError(error);
    }
  }
}
