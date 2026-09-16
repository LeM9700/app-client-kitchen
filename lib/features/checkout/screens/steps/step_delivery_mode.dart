import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/features/checkout/widgets/kitchen_order_mode_selector.dart';

/// Etape 1 : choix entre livraison et retrait en boutique.
///
/// Pickup saute directement l'etape adresse (voir
/// `CheckoutNotifier.selectDeliveryMode`).
class StepDeliveryMode extends ConsumerWidget {
  const StepDeliveryMode({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode =
        ref.watch(checkoutProvider.select((s) => s.deliveryMode));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KitchenSpacing.lg,
        KitchenSpacing.md,
        KitchenSpacing.lg,
        KitchenSpacing.xl,
      ),
      children: [
        Text(
          'Comment voulez-vous recevoir votre commande ?',
          style: KitchenTypography.title.copyWith(fontSize: 30),
        ),
        const SizedBox(height: KitchenSpacing.xs),
        Text(
          'Choisissez un mode, le panier reste intact pendant tout le tunnel.',
          style:
              KitchenTypography.body.copyWith(color: KitchenColors.textMuted),
        ),
        const SizedBox(height: KitchenSpacing.lg),
        KitchenOrderModeSelector(
          selectedMode: selectedMode,
          onSelected: (mode) =>
              ref.read(checkoutProvider.notifier).selectDeliveryMode(mode),
        ),
        const SizedBox(height: KitchenSpacing.lg),
        KitchenSurface(
          elevation: KitchenElevation.inset,
          padding: const EdgeInsets.all(KitchenSpacing.md),
          child: Row(
            children: [
              Icon(
                selectedMode == DeliveryMode.delivery
                    ? Icons.delivery_dining_outlined
                    : Icons.storefront_outlined,
                color: KitchenColors.cognac,
              ),
              const SizedBox(width: KitchenSpacing.sm),
              Expanded(
                child: Text(
                  selectedMode == DeliveryMode.delivery
                      ? 'La zone de livraison sera verifiee avec votre position sur la carte.'
                      : 'Aucune adresse de livraison necessaire pour le retrait.',
                  style: KitchenTypography.body.copyWith(
                    color: KitchenColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
