import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';

String _formatPrice(double price) => '${price.toStringAsFixed(2)} €';

/// Étape 0 (invisible si rien n'a changé) : revalidation des prix et
/// disponibilités du panier. `CheckoutScreen` déclenche `revalidateCart()`
/// à l'ouverture — `revalidateCart` avance automatiquement à
/// `CheckoutStep.deliveryMode` si aucune alerte, donc cet écran n'est visible
/// que pendant le chargement ou si des alertes existent.
class StepRevalidation extends ConsumerWidget {
  const StepRevalidation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutProvider);

    if (checkoutState.isRevalidating || checkoutState.priceAlerts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Certains articles de votre panier ont changé depuis que vous les avez ajoutés.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...checkoutState.priceAlerts.map(
                (alert) => _PriceAlertTile(alert: alert),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () => ref
                    .read(checkoutProvider.notifier)
                    .dismissAlertsAndContinue(),
                child: const Text('Continuer'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Retour au panier'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceAlertTile extends StatelessWidget {
  const _PriceAlertTile({required this.alert});
  final PriceAlert alert;

  @override
  Widget build(BuildContext context) {
    final priceChanged = alert.oldPrice != alert.newPrice;
    final becameUnavailable = alert.wasAvailable && !alert.isAvailable;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.item.product.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            if (priceChanged)
              Text(
                'Prix mis à jour : ${_formatPrice(alert.oldPrice)} → ${_formatPrice(alert.newPrice)}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (becameUnavailable)
              Text(
                'Cet article n\'est plus disponible.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
