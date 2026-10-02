import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/features/checkout/models/address_models.dart';

/// Codes d'erreur metier de la livraison renvoyes par api-pizza (`AppError.code`).
const deliveryErrorCodes = <String>{
  'DELIVERY_DISABLED',
  'DELIVERY_MIN_ORDER_NOT_MET',
  'DELIVERY_ZONE_UNREACHABLE',
  'DELIVERY_COORDINATES_REQUIRED',
  'INVALID_DELIVERY_ZONE',
  'CUSTOMER_PHONE_REQUIRED',
  'PROMO_DELIVERY_ONLY',
  'GEOCODING_NOT_CONFIGURED',
  'GEOCODING_UNAVAILABLE',
  'GEOCODING_QUERY_TOO_SHORT',
};

/// Convertit une erreur HTTP en [DeliveryException] quand l'API a renvoye un code de
/// livraison connu (pour que l'ecran affiche un message traduit plutot que le texte
/// technique du serveur), sinon applique la conversion generique.
AppException mapDeliveryError(DioException error) {
  final data = error.response?.data;
  if (data is Map) {
    final code = data['code'];
    if (code is String && deliveryErrorCodes.contains(code)) {
      return DeliveryException(code, (data['detail'] as String?) ?? code);
    }
  }
  if (error.response?.statusCode == 429) {
    return const DeliveryException(
      'RATE_LIMITED',
      'Trop de requetes, reessayez dans un instant.',
    );
  }
  return ApiClient.handleDioError(error);
}

/// Recherche d'adresse (via le proxy Mapbox de l'API) et disponibilite de la livraison.
class AddressRepository {
  const AddressRepository(this._client);

  final ApiClient _client;

  /// Adresse saisie -> candidats avec coordonnees. [lat]/[lng] favorisent les resultats
  /// proches du restaurant.
  Future<List<AddressSuggestion>> geocode(
    String query, {
    double? lat,
    double? lng,
    String language = 'fr',
  }) async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.deliveryGeocode,
        queryParameters: {
          'q': query,
          if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
          'language': language,
          'limit': 5,
        },
      );
      return (response.data ?? const [])
          .map(AddressSuggestion.tryParse)
          .whereType<AddressSuggestion>()
          .toList();
    } on DioException catch (e) {
      throw mapDeliveryError(e);
    }
  }

  /// Coordonnees -> adresse la plus proche, ou `null`.
  Future<AddressSuggestion?> reverse(
    double lat,
    double lng, {
    String language = 'fr',
  }) async {
    try {
      final response = await _client.get<dynamic>(
        ApiEndpoints.deliveryReverseGeocode,
        queryParameters: {'lat': lat, 'lng': lng, 'language': language},
      );
      return AddressSuggestion.tryParse(response.data);
    } on DioException catch (e) {
      throw mapDeliveryError(e);
    }
  }

  /// Public (tenant via `X-Tenant-Slug`) : la livraison est-elle proposee ?
  Future<DeliveryAvailability> availability() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.deliveryAvailability,
      );
      return DeliveryAvailability.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw mapDeliveryError(e);
    }
  }
}

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepository(ref.read(apiClientProvider)),
);

/// Disponibilite de la livraison. En cas d'echec (reseau, serveur) la valeur n'est pas
/// disponible : l'interface reste ouverte (ne bloque jamais la commande) et c'est le
/// serveur qui tranche a la creation de la commande.
final deliveryAvailabilityProvider =
    FutureProvider.autoDispose<DeliveryAvailability>(
  (ref) => ref.read(addressRepositoryProvider).availability(),
);
