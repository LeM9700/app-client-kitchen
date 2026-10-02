import 'package:latlong2/latlong.dart';

/// Candidat d'adresse renvoye par `GET /delivery/geocode` (proxy Mapbox cote API).
class AddressSuggestion {
  const AddressSuggestion({
    required this.label,
    required this.lat,
    required this.lng,
    this.street,
    this.postcode,
    this.city,
    this.countryCode,
  });

  final String label;
  final double lat;
  final double lng;
  final String? street;
  final String? postcode;
  final String? city;
  final String? countryCode;

  LatLng get point => LatLng(lat, lng);

  /// Retourne `null` si les coordonnees sont absentes ou invalides : une suggestion sans
  /// position ne peut pas servir a placer le repere.
  static AddressSuggestion? tryParse(Object? json) {
    if (json is! Map) return null;
    final lat = json['lat'];
    final lng = json['lng'];
    final label = json['label'];
    if (lat is! num || lng is! num || label is! String || label.isEmpty) {
      return null;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return AddressSuggestion(
      label: label,
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      street: json['street'] as String?,
      postcode: json['postcode'] as String?,
      city: json['city'] as String?,
      countryCode: json['country_code'] as String?,
    );
  }
}

class DeliveryEstablishment {
  const DeliveryEstablishment({
    required this.id,
    required this.name,
    required this.hasDeliveryZones,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String name;
  final bool hasDeliveryZones;
  final double? latitude;
  final double? longitude;

  LatLng? get point => latitude != null && longitude != null
      ? LatLng(latitude!, longitude!)
      : null;

  static DeliveryEstablishment? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! int || name is! String) return null;
    return DeliveryEstablishment(
      id: id,
      name: name,
      hasDeliveryZones: json['has_delivery_zones'] == true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

/// Reponse de `GET /delivery/availability` : la livraison est-elle proposee, et ou se
/// trouvent les restaurants (pour centrer la carte).
class DeliveryAvailability {
  const DeliveryAvailability({
    required this.deliveryEnabled,
    this.establishments = const [],
  });

  final bool deliveryEnabled;
  final List<DeliveryEstablishment> establishments;

  /// Position du premier restaurant qui livre et dont la position est connue.
  LatLng? get mapCenter {
    for (final establishment in establishments) {
      if (establishment.hasDeliveryZones && establishment.point != null) {
        return establishment.point;
      }
    }
    for (final establishment in establishments) {
      if (establishment.point != null) return establishment.point;
    }
    return null;
  }

  factory DeliveryAvailability.fromJson(Map<String, dynamic> json) {
    final raw = json['establishments'];
    return DeliveryAvailability(
      deliveryEnabled: json['delivery_enabled'] != false,
      establishments: raw is List
          ? raw
              .map(DeliveryEstablishment.tryParse)
              .whereType<DeliveryEstablishment>()
              .toList()
          : const [],
    );
  }
}
