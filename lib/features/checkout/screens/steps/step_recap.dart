import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/kod_mome/kod_mome_design_pack.dart';
import 'package:app_client/design_system/kod_mome/glass_surface.dart';
import 'package:app_client/design_system/kod_mome/gold_foil_text.dart';
import 'package:app_client/design_system/kod_mome/neumorphic_surface.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

String _formatPrice(double price) => '${price.toStringAsFixed(2)} €';

/// Étape 3 : récapitulatif final + création de la commande.
///
/// [🔒 CORRECTIF — décision d'architecture n°4] Aucun endpoint `/orders/preview`
/// n'existe côté API (voir plans/corrections) — le total affiché ici est donc
/// l'estimation client (sous-total panier + frais de livraison retournés par
/// `/delivery/check`). Le montant exact facturé est celui que `POST /orders`
/// retourne/traite côté serveur ; ce récap ne prétend pas afficher un total
/// "officiel serveur" distinct puisque l'API ne l'expose pas avant création.
class StepRecap extends ConsumerWidget {
  const StepRecap({super.key});

  Future<void> _confirmOrder(BuildContext context, WidgetRef ref) async {
    final orderId = await ref.read(checkoutProvider.notifier).createOrder();
    if (orderId == null) return; // erreur déjà affichée via checkoutState.error
    if (!context.mounted) return;

    // La route paiement ouvre la Stripe PaymentSheet avec l'orderId créé par
    // le serveur. L'id passe en query param pour rester cohérent avec le
    // router existant (`/checkout/payment?orderId=...`).
    context.push('${AppRoutes.payment}?orderId=$orderId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final l10n = AppLocalizations.of(context)!;
    final isKodMome = Env.isKodMomeBuild;
    final textColor = isKodMome ? KodMomeDesignPack.cream : null;
    final mutedColor =
        isKodMome ? KodMomeDesignPack.cream.withValues(alpha: 0.7) : null;

    final deliveryFee = checkoutState.deliveryMode == DeliveryMode.delivery
        ? (checkoutState.deliveryInfo?.fee ?? 0)
        : 0.0;
    final estimatedTotal = cart.total + deliveryFee;

    final recapCard = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.checkoutRecapArticlesTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: textColor),
        ),
        const SizedBox(height: 8),
        ...cart.itemList.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.checkoutRecapLineItem(
                      item.quantity,
                      item.product.name,
                    ),
                    style: TextStyle(color: mutedColor),
                  ),
                ),
                Text(
                  _formatPrice(item.totalPrice),
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 32,
          color: isKodMome ? KodMomeDesignPack.cream.withValues(alpha: 0.2) : null,
        ),
        Text(
          checkoutState.deliveryMode == DeliveryMode.delivery
              ? l10n.checkoutDeliveryTitle
              : l10n.checkoutPickupTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: textColor),
        ),
        const SizedBox(height: 8),
        if (checkoutState.deliveryMode == DeliveryMode.delivery &&
            checkoutState.deliveryInfo != null) ...[
          Text(
            l10n.checkoutRecapZone(checkoutState.deliveryInfo!.name),
            style: TextStyle(color: mutedColor),
          ),
          Text(
            l10n.checkoutRecapEstimatedTime(
              checkoutState.deliveryInfo!.estimatedMinutes,
            ),
            style: TextStyle(color: mutedColor),
          ),
          Text(
            l10n.checkoutRecapDeliveryFee(
              _formatPrice(checkoutState.deliveryInfo!.fee),
            ),
            style: TextStyle(color: mutedColor),
          ),
          if (checkoutState.address != null &&
              checkoutState.address!.isNotEmpty)
            Text(
              l10n.checkoutRecapAddress(checkoutState.address!),
              style: TextStyle(color: mutedColor),
            ),
        ] else if (checkoutState.deliveryMode == DeliveryMode.pickup)
          Text(
            l10n.checkoutRecapPickupOnly,
            style: TextStyle(color: mutedColor),
          ),
        Divider(
          height: 32,
          color: isKodMome ? KodMomeDesignPack.cream.withValues(alpha: 0.2) : null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.checkoutRecapEstimatedTotal,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: textColor),
            ),
            isKodMome
                ? GoldFoilText(
                    _formatPrice(estimatedTotal),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : Text(
                    _formatPrice(estimatedTotal),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.checkoutRecapFinalAmountNotice,
          style:
              Theme.of(context).textTheme.bodySmall?.copyWith(color: mutedColor),
        ),
        if (checkoutState.error != null) ...[
          const SizedBox(height: 16),
          Text(
            checkoutState.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              isKodMome
                  // Seule surface avec vrai flou de cet écran, voir
                  // garde-fous perf du plan.
                  ? KodMomeGlassSurface(
                      variant: KodMomeGlassVariant.hero,
                      child: recapCard,
                    )
                  : recapCard,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: isKodMome
              ? NeumorphicButton(
                  borderRadius: 16,
                  onTap: checkoutState.isLoading
                      ? () {}
                      : () => _confirmOrder(context, ref),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: checkoutState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KodMomeDesignPack.primary,
                            ),
                          )
                        : GoldFoilText(
                            l10n.checkoutConfirmOrderButton,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                )
              : ElevatedButton(
                  onPressed: checkoutState.isLoading
                      ? null
                      : () => _confirmOrder(context, ref),
                  child: checkoutState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.checkoutConfirmOrderButton),
                ),
        ),
      ],
    );
  }
}
