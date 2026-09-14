import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/theme/kod_mome/kod_mome_design_pack.dart';
import 'package:app_client/design_system/kod_mome/glass_surface.dart';
import 'package:app_client/design_system/kod_mome/gold_foil_text.dart';
import 'package:app_client/design_system/kod_mome/neumorphic_surface.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final isKodMome = Env.isKodMomeBuild;

    if (checkoutState.isRevalidating || checkoutState.priceAlerts.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: isKodMome ? KodMomeDesignPack.primary : null,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.checkoutRevalidationMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isKodMome
                          ? KodMomeDesignPack.cream.withValues(alpha: 0.85)
                          : null,
                    ),
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
              isKodMome
                  ? NeumorphicButton(
                      borderRadius: 16,
                      onTap: () => ref
                          .read(checkoutProvider.notifier)
                          .dismissAlertsAndContinue(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: GoldFoilText(
                          l10n.checkoutContinueButton,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => ref
                          .read(checkoutProvider.notifier)
                          .dismissAlertsAndContinue(),
                      child: Text(l10n.checkoutContinueButton),
                    ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  l10n.checkoutBackToCart,
                  style: isKodMome
                      ? const TextStyle(color: KodMomeDesignPack.primary)
                      : null,
                ),
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
    final l10n = AppLocalizations.of(context)!;
    final isKodMome = Env.isKodMomeBuild;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          alert.item.product.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isKodMome ? KodMomeDesignPack.cream : null,
              ),
        ),
        const SizedBox(height: 4),
        if (priceChanged)
          Text(
            l10n.checkoutPriceUpdated(
              _formatPrice(alert.oldPrice),
              _formatPrice(alert.newPrice),
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (becameUnavailable)
          Text(
            l10n.checkoutItemNoLongerAvailable,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );

    if (isKodMome) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: KodMomeGlassSurface(
          padding: const EdgeInsets.all(12),
          child: content,
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(12), child: content),
    );
  }
}
