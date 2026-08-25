import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';

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

    final deliveryFee = checkoutState.deliveryMode == DeliveryMode.delivery
        ? (checkoutState.deliveryInfo?.fee ?? 0)
        : 0.0;
    final estimatedTotal = cart.total + deliveryFee;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Articles', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...cart.itemList.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${item.quantity} × ${item.product.name}'),
                      ),
                      Text(_formatPrice(item.totalPrice)),
                    ],
                  ),
                ),
              ),
              const Divider(height: 32),
              Text(
                checkoutState.deliveryMode == DeliveryMode.delivery
                    ? 'Livraison'
                    : 'Retrait en boutique',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (checkoutState.deliveryMode == DeliveryMode.delivery &&
                  checkoutState.deliveryInfo != null) ...[
                Text('Zone : ${checkoutState.deliveryInfo!.name}'),
                Text(
                  'Délai estimé : ${checkoutState.deliveryInfo!.estimatedMinutes} min',
                ),
                Text(
                  'Frais de livraison : ${_formatPrice(checkoutState.deliveryInfo!.fee)}',
                ),
                if (checkoutState.address != null &&
                    checkoutState.address!.isNotEmpty)
                  Text('Adresse : ${checkoutState.address}'),
              ] else if (checkoutState.deliveryMode == DeliveryMode.pickup)
                const Text('À récupérer directement en boutique.'),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total estimé',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
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
                'Le montant définitif est calculé par le serveur à la création de la commande.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (checkoutState.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  checkoutState.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: checkoutState.isLoading
                ? null
                : () => _confirmOrder(context, ref),
            child: checkoutState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirmer la commande'),
          ),
        ),
      ],
    );
  }
}
