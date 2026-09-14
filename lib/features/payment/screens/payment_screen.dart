import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/theme/kod_mome/kod_mome_design_pack.dart';
import 'package:app_client/design_system/kod_mome/glass_surface.dart';
import 'package:app_client/design_system/kod_mome/gold_foil_text.dart';
import 'package:app_client/design_system/kod_mome/neumorphic_surface.dart';
import 'package:app_client/features/payment/providers/payment_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final isKodMome = Env.isKodMomeBuild;

    // Réaction aux changements d'état.
    ref.listen(paymentProvider, (_, next) {
      if (next.status == PaymentStatus.success) {
        // Le panier est déjà vidé dans PaymentNotifier.pay(). Le tracking
        // affiche la confirmation et l'avancement de commande, sans écran
        // "merci" intermédiaire.
        context.go('/orders/$orderId/tracking');
      }
    });

    final payLabel = paymentState.status == PaymentStatus.failure
        ? l10n.paymentRetryButton
        : l10n.paymentPayNowButton;

    return Scaffold(
      backgroundColor: isKodMome ? KodMomeDesignPack.charcoal : null,
      appBar: AppBar(
        backgroundColor: isKodMome ? KodMomeDesignPack.charcoal : null,
        foregroundColor: isKodMome ? KodMomeDesignPack.cream : null,
        title: Text(l10n.paymentTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock_outline,
                size: 48,
                color: isKodMome
                    ? KodMomeDesignPack.primary
                    : const Color(0xFF2E7D32),
              ),
              const SizedBox(height: 16),
              isKodMome
                  ? GoldFoilText(
                      l10n.paymentSecureTitle,
                      style: theme.textTheme.headlineMedium,
                    )
                  : Text(
                      l10n.paymentSecureTitle,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
              const SizedBox(height: 8),
              Text(
                l10n.paymentSecureSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isKodMome
                      ? KodMomeDesignPack.cream.withValues(alpha: 0.65)
                      : null,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Erreur (paiement refusé, erreur réseau/serveur) — le bouton
              // "Payer" ci-dessous permet de réessayer sans recréer d'intent
              // (voir PaymentNotifier.pay).
              if (paymentState.status == PaymentStatus.failure &&
                  paymentState.error != null) ...[
                isKodMome
                    ? KodMomeGlassSurface(
                        child: Text(
                          paymentState.error!,
                          style: const TextStyle(
                            color: KodMomeDesignPack.redAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Container(
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
              isKodMome
                  ? NeumorphicButton(
                      borderRadius: 16,
                      onTap: paymentState.status == PaymentStatus.loading
                          ? () {}
                          : () =>
                              ref.read(paymentProvider.notifier).pay(orderId),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: paymentState.status == PaymentStatus.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: KodMomeDesignPack.primary,
                                ),
                              )
                            : GoldFoilText(
                                payLabel,
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: paymentState.status == PaymentStatus.loading
                          ? null
                          : () =>
                              ref.read(paymentProvider.notifier).pay(orderId),
                      child: paymentState.status == PaymentStatus.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(payLabel),
                    ),

              const SizedBox(height: 12),

              // Bouton annuler.
              TextButton(
                onPressed: paymentState.status == PaymentStatus.loading
                    ? null
                    : () => context.pop(),
                child: Text(
                  l10n.paymentCancelButton,
                  style: isKodMome
                      ? const TextStyle(color: KodMomeDesignPack.primary)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
