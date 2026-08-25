import 'package:dio/dio.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/features/cart/models/cart_item.dart';
import 'package:app_client/features/checkout/models/delivery_info.dart';

/// Signale un 422 DELIVERY_ZONE_UNREACHABLE — distingué des autres erreurs pour que le
/// notifier puisse afficher un message métier ("hors zone") plutôt qu'une erreur générique.
class DeliveryZoneUnreachableException implements Exception {}

class CheckoutRepository {
  const CheckoutRepository(this._client);
  final ApiClient _client;

  /// [TECH DEBT corrigé] lat/lng, pas une adresse texte — voir la note en tête de plan.
  /// L'API ne renvoie jamais {deliverable: false} : succès = 200, hors zone = 422.
  Future<DeliveryInfo> checkDeliveryZone({
    required double lat,
    required double lng,
    String? displayAddress,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.deliveryCheck,
        data: {
          'lat': lat,
          'lng': lng,
          if (displayAddress != null) 'address': displayAddress,
        },
      );
      return DeliveryInfo.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw DeliveryZoneUnreachableException();
      }
      throw ApiClient.handleDioError(e);
    }
  }

  /// [TECH DEBT corrigé] `Idempotency-Key` est un header (pas un champ body). La clé est générée
  /// une seule fois par le notifier (voir `CheckoutState.idempotencyKey`) et passée ici — la
  /// régénérer à chaque appel viderait l'intérêt même de l'en-tête (un retry après timeout doit
  /// réutiliser la MÊME clé pour que l'API dédoublonne). `extras` se passe en objets
  /// `{extra_id, quantity}` (`OrderItemExtraCreate`), pas une liste d'ids. `delivery_zone_id` et
  /// l'id retourné sont des `int`, pas des `String`.
  Future<int> createOrder({
    required List<CartItem> items,
    required String orderType,
    required String idempotencyKey,
    String? deliveryAddress,
    int? deliveryZoneId,
    String? promoCode,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.orders,
        data: {
          'order_type': orderType,
          'items': items
              .map(
                (i) => {
                  'product_id': i.product.id,
                  'quantity': i.quantity,
                  if (i.selectedVariant != null)
                    'variant_id': i.selectedVariant!.id,
                  if (i.selectedExtraIds.isNotEmpty)
                    'extras': i.selectedExtraIds
                        .map((id) => {'extra_id': id, 'quantity': 1})
                        .toList(),
                },
              )
              .toList(),
          if (deliveryAddress != null) 'delivery_address': deliveryAddress,
          if (deliveryZoneId != null) 'delivery_zone_id': deliveryZoneId,
          if (promoCode != null) 'promo_code': promoCode,
        },
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      return response.data!['id'] as int;
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}
