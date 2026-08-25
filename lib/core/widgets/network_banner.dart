import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/providers/connectivity_provider.dart';

/// Bannière globale de perte de connectivité RÉSEAU DE L'APPAREIL — distinct
/// de la bannière de reconnexion WebSocket de `TrackingScreen` (qui suit
/// l'état d'un canal applicatif, pas la connectivité device). Enveloppe
/// `ScaffoldWithNav` pour rester visible sur toute l'app (voir
/// plan-19-ux-polish.md, décision n°1).
class NetworkBanner extends ConsumerWidget {
  const NetworkBanner({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(connectivityProvider).valueOrNull ?? true;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isConnected ? 0 : 32,
          color: const Color(0xFFB71C1C),
          child: isConnected
              ? const SizedBox.shrink()
              : const Center(
                  child: Text(
                    '📡 Connexion perdue',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
