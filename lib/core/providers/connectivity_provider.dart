import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écoute la connectivité réseau de l'appareil (pas l'état de connexion
/// WebSocket — un concern distinct, voir `TrackingScreen`). `true` = un
/// réseau est disponible (peut ne pas avoir Internet, `connectivity_plus` ne
/// vérifie que l'interface, pas l'accès réel — suffisant pour ce cas d'usage
/// : bannière informative, pas garantie de connectivité serveur).
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
        (results) => !results.contains(ConnectivityResult.none),
      );
});
