import 'package:dio/dio.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/tracking/models/driver_location.dart';
import 'package:app_client/features/orders/models/reorder_result.dart';

/// Page de résultats paginée par OFFSET (`PaginatedResponse<OrderListOut>`,
/// voir `api-pizza/app/core/http/schemas.py` + `orders/router.py`) — PAS de
/// curseur, contrairement à ce que plan-15-historique.md supposait (voir
/// api-corrections-phase-d.md §5).
///
/// DTO de repository volontairement non-freezed : reconstruit par
/// `OrderHistoryNotifier` à chaque page plutôt que muté, pas besoin
/// d'égalité structurelle/`copyWith`.
class OrderPage {
  const OrderPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pages,
  });

  final List<Order> items;
  final int total;
  final int page;
  final int pageSize;
  final int pages;

  factory OrderPage.fromJson(Map<String, dynamic> json) => OrderPage(
        items: (json['items'] as List)
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['page_size'] as int,
        pages: json['pages'] as int,
      );
}

/// Repository commandes — historique, détail/reçu, reorder (Plan 15) et
/// refetch de suivi temps réel (Plan 14, consolidé ici).
class OrderRepository {
  const OrderRepository(this._client);
  final ApiClient _client;

  /// `GET /orders/me?page=&page_size=&status=` — pagination par OFFSET (pas
  /// un curseur, voir api-corrections-phase-d.md §5). [status] : liste de
  /// statuts, envoyée séparée par des virgules côté API, optionnelle.
  Future<OrderPage> getMyOrders({
    int page = 1,
    int pageSize = 20,
    List<String>? status,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.myOrders,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (status != null && status.isNotEmpty) 'status': status.join(','),
        },
      );
      return OrderPage.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// `GET /orders/{id}` — détail complet (`OrderDetailOut`). Sert aussi de
  /// reçu client (aucun endpoint `/orders/{id}/receipt` accessible hors
  /// staff/admin, voir api-corrections-phase-d.md §5) et de refetch pour le
  /// suivi temps réel (Plan 14 — événement WS reçu ou polling de secours).
  Future<Order> getOrderById(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.orderDetail(id),
      );
      return Order.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// `GET /orders/{id}/delivery-code` : le code a 4 chiffres que le client donne au livreur.
  ///
  /// `null` quand il n'y a (plus) rien a donner : commande a emporter, pas encore confirmee,
  /// deja livree ou annulee (404 / 409 cote API). Les autres erreurs remontent.
  Future<String?> getDeliveryCode(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.orderDeliveryCode(id),
      );
      final code = response.data?['code'];
      return code is String && code.isNotEmpty ? code : null;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 409) return null;
      throw ApiClient.handleDioError(e);
    }
  }

  /// `GET /orders/{id}/driver-location` : position du livreur pendant la livraison.
  ///
  /// `null` quand le suivi n'est pas (ou plus) disponible : commande qui n'est pas en route
  /// (409), commande d'un autre (404). Les autres erreurs remontent.
  Future<DriverLocation?> getDriverLocation(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.orderDriverLocation(id),
      );
      final data = response.data;
      return data == null ? null : DriverLocation.fromJson(data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 409) return null;
      throw ApiClient.handleDioError(e);
    }
  }

  /// `POST /orders/{id}/reorder` — l'id est dans le CHEMIN, pas le body
  /// (le plan d'origine supposait `POST /orders/reorder {orderId}`, faux —
  /// voir api-corrections-phase-d.md §5). Ne crée PAS de commande : retourne
  /// un payload de préremplissage panier avec les prix/la disponibilité
  /// actuels du catalogue.
  Future<ReorderResult> reorder(int orderId) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.reorder(orderId),
      );
      return ReorderResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}
