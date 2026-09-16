import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/providers/connectivity_provider.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_motion.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';

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
          duration: KitchenMotion.medium,
          curve: KitchenMotion.entranceCurve,
          height: isConnected ? 0 : 36,
          color: KitchenColors.terracotta,
          child: isConnected
              ? const SizedBox.shrink()
              : Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: KitchenColors.whiteWarm,
                        size: 17,
                      ),
                      const SizedBox(width: KitchenSpacing.xs),
                      Text(
                        'Connexion perdue',
                        style: KitchenTypography.label.copyWith(
                          color: KitchenColors.whiteWarm,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
