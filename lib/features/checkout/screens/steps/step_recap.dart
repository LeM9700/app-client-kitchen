import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/features/checkout/widgets/kitchen_order_summary.dart';
import 'package:app_client/l10n/app_localizations.dart';

/// Etape 3 : recapitulatif final + creation de la commande.
///
/// Aucun endpoint `/orders/preview` n'existe : le total affiche reste une
/// estimation client avant creation, le serveur restant autoritaire.
class StepRecap extends ConsumerWidget {
  const StepRecap({super.key});

  Future<void> _confirmOrder(BuildContext context, WidgetRef ref) async {
    final orderId = await ref.read(checkoutProvider.notifier).createOrder();
    if (orderId == null) return;
    if (!context.mounted) return;

    context.push('${AppRoutes.payment}?orderId=$orderId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final l10n = AppLocalizations.of(context)!;

    final deliveryFee = checkoutState.deliveryMode == DeliveryMode.delivery
        ? (checkoutState.deliveryInfo?.fee ?? 0)
        : 0.0;
    final discount = cart.promoDiscount ?? 0;
    final estimatedTotal = cart.subtotal - discount + deliveryFee;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              KitchenSpacing.lg,
              KitchenSpacing.md,
              KitchenSpacing.lg,
              KitchenSpacing.xl,
            ),
            children: [
              KitchenSurface(
                padding: const EdgeInsets.all(KitchenSpacing.lg),
                child: KitchenOrderSummary(
                  items: cart.itemList,
                  deliveryMode: checkoutState.deliveryMode,
                  subtotal: cart.subtotal,
                  deliveryFee: deliveryFee,
                  discountTotal: discount,
                  total: estimatedTotal,
                  address: checkoutState.address,
                  estimatedMinutes:
                      checkoutState.deliveryInfo?.estimatedMinutes,
                  zoneName: checkoutState.deliveryInfo?.name,
                ),
              ),
              const SizedBox(height: KitchenSpacing.md),
              KitchenSurface(
                elevation: KitchenElevation.inset,
                padding: const EdgeInsets.all(KitchenSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: KitchenColors.olive,
                    ),
                    const SizedBox(width: KitchenSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.checkoutRecapFinalAmountNotice,
                        style: KitchenTypography.body.copyWith(
                          color: KitchenColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (checkoutState.error != null) ...[
                const SizedBox(height: KitchenSpacing.md),
                Text(
                  checkoutState.error!,
                  style: KitchenTypography.body.copyWith(
                    color: KitchenColors.terracotta,
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(KitchenSpacing.lg),
            child: KitchenEmbossedButton(
              onPressed: () => _confirmOrder(context, ref),
              isLoading: checkoutState.isLoading,
              enabled: !cart.isEmpty,
              semanticLabel: 'Creer la commande et passer au paiement',
              child: Text(l10n.checkoutConfirmOrderButton),
            ),
          ),
        ),
      ],
    );
  }
}
