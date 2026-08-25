import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/features/payment/providers/payment_provider.dart';

/// Écran de paiement — ouvre la Stripe PaymentSheet pour la commande [orderId].
///
/// [🔒 SÉCURITÉ] Aucune donnée de carte ne transite par ce widget ni par le
/// serveur api-pizza — la PaymentSheet Stripe gère intégralement la saisie,
/// la tokenisation et le 3DS (voir décision d'architecture n°1 du Plan 13).
///
/// [Décision d'architecture n°4] Pas d'écran de succès séparé : un paiement
/// réussi vide le panier puis navigue directement vers le suivi de commande
/// (`/orders/{orderId}/tracking`), qui sert lui-même de confirmation visuelle.
/// `AppRoutes.paymentSuccess` (`/checkout/success`) reste déclaré dans le
/// router mais n'est volontairement pas atteint par ce flux.
class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key, required this.orderId});
  final int orderId; // [TECH DEBT corrigé] int côté API (cohérent avec Plan 11)

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(paymentProvider);
    final theme = Theme.of(context);

    // Réaction aux changements d'état.
    ref.listen(paymentProvider, (_, next) {
      if (next.status == PaymentStatus.success) {
        // Le panier est déjà vidé dans PaymentNotifier.pay(). Le tracking
        // affiche la confirmation et l'avancement de commande, sans écran
        // "merci" intermédiaire.
        context.go('/orders/$orderId/tracking');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 48,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(height: 16),
              Text(
                'Paiement sécurisé',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Votre paiement est chiffré et sécurisé par Stripe.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Erreur (paiement refusé, erreur réseau/serveur) — le bouton
              // "Payer" ci-dessous permet de réessayer sans recréer d'intent
              // (voir PaymentNotifier.pay).
              if (paymentState.status == PaymentStatus.failure &&
                  paymentState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    paymentState.error!,
                    style: const TextStyle(color: Color(0xFFB71C1C)),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Bouton payer.
              ElevatedButton(
                onPressed: paymentState.status == PaymentStatus.loading
                    ? null
                    : () => ref.read(paymentProvider.notifier).pay(orderId),
                child: paymentState.status == PaymentStatus.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        paymentState.status == PaymentStatus.failure
                            ? 'Réessayer'
                            : 'Payer maintenant',
                      ),
              ),

              const SizedBox(height: 12),

              // Bouton annuler.
              TextButton(
                onPressed: paymentState.status == PaymentStatus.loading
                    ? null
                    : () => context.pop(),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
