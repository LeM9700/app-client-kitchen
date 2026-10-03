/// Position du livreur de la commande, telle que le client la voit
/// (`GET /orders/{id}/driver-location`) : une position, jamais l'historique.
class DriverLocation {
  const DriverLocation({
    required this.available,
    this.driverFirstName,
    this.lat,
    this.lng,
    this.destinationLat,
    this.destinationLng,
    this.ageSeconds,
    this.stale = false,
    this.etaMinutes,
    this.arrived = false,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    double? number(Object? value) => value is num ? value.toDouble() : null;
    return DriverLocation(
      available: json['available'] == true,
      driverFirstName: json['driver_first_name'] as String?,
      lat: number(json['lat']),
      lng: number(json['lng']),
      destinationLat: number(json['destination_lat']),
      destinationLng: number(json['destination_lng']),
      ageSeconds: (json['age_seconds'] as num?)?.toInt(),
      stale: json['stale'] == true,
      etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
      arrived: json['arrived'] == true,
    );
  }

  /// `false` tant que le livreur n'a envoye aucune position pour cette course.
  final bool available;
  final String? driverFirstName;
  final double? lat;
  final double? lng;
  final double? destinationLat;
  final double? destinationLng;

  /// Age de la position, en secondes.
  final int? ageSeconds;

  /// Position pas actualisee depuis plus d'une minute : a signaler au client.
  final bool stale;

  /// Estimation (distance a vol d'oiseau majoree), pas un itineraire.
  final int? etaMinutes;
  final bool arrived;

  bool get hasPosition => available && lat != null && lng != null;
  bool get hasDestination => destinationLat != null && destinationLng != null;
}
