import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';

/// Étape 1 : choix entre livraison et retrait en boutique.
///
/// Pickup saute directement l'étape adresse (voir `CheckoutNotifier.selectDeliveryMode`).
class StepDeliveryMode extends ConsumerWidget {
  const StepDeliveryMode({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode =
        ref.watch(checkoutProvider.select((s) => s.deliveryMode));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Comment souhaitez-vous récupérer votre commande ?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _ModeCard(
            icon: Icons.delivery_dining,
            title: 'Livraison',
            subtitle: 'Livré à votre adresse',
            selected: selectedMode == DeliveryMode.delivery,
            onTap: () => ref
                .read(checkoutProvider.notifier)
                .selectDeliveryMode(DeliveryMode.delivery),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            icon: Icons.storefront,
            title: 'Retrait en boutique',
            subtitle: 'À récupérer sur place',
            selected: selectedMode == DeliveryMode.pickup,
            onTap: () => ref
                .read(checkoutProvider.notifier)
                .selectDeliveryMode(DeliveryMode.pickup),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: selected ? colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: selected
            ? Icon(Icons.check_circle, color: colorScheme.primary)
            : null,
        onTap: onTap,
      ),
    );
  }
}
