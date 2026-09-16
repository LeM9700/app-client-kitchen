import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClientLocation {
  const ClientLocation({
    required this.address,
    required this.lat,
    required this.lng,
  });

  final String address;
  final double lat;
  final double lng;

  String get coordinates =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}

final clientLocationProvider = StateProvider<ClientLocation?>((ref) => null);
