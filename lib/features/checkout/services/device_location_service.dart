import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum DeviceLocationFailure { serviceDisabled, permissionDenied, unavailable }

class DeviceLocationException implements Exception {
  const DeviceLocationException(this.failure);

  final DeviceLocationFailure failure;

  @override
  String toString() => 'DeviceLocationException: ${failure.name}';
}

/// Position de l'appareil, demandee uniquement quand le client touche « Ma position »
/// pour placer son repere de livraison. Jamais de suivi en continu, jamais envoyee au
/// serveur autrement que comme coordonnees de la commande.
abstract class DeviceLocationService {
  Future<LatLng> currentPosition();
}

class GeolocatorLocationService implements DeviceLocationService {
  const GeolocatorLocationService();

  @override
  Future<LatLng> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DeviceLocationException(DeviceLocationFailure.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(DeviceLocationFailure.permissionDenied);
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      throw const DeviceLocationException(DeviceLocationFailure.unavailable);
    }
  }
}

final deviceLocationServiceProvider = Provider<DeviceLocationService>(
  (ref) => const GeolocatorLocationService(),
);
