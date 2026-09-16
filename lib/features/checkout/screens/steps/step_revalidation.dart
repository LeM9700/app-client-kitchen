import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

String _formatPrice(double price) => formatPrice(price);

/// Etape 0 : revalidation prix/disponibilite du panier.
class StepRevalidation extends ConsumerWidget {
  const StepRevalidation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutProvider);
    final l10n = AppLocalizations.of(context)!;

    if (checkoutState.isRevalidating || checkoutState.priceAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KitchenLoadingIndicator(color: KitchenColors.cognac),
            const SizedBox(height: KitchenSpacing.md),
            Text(
              'Verification du panier...',
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(KitchenSpacing.lg),
            children: [
              Text(
                'Quelques details ont change',
                style: KitchenTypography.title.copyWith(fontSize: 30),
              ),
              const SizedBox(height: KitchenSpacing.xs),
              Text(
                l10n.checkoutRevalidationMessage,
                style: KitchenTypography.body.copyWith(
                  color: KitchenColors.textMuted,
                ),
              ),
              const SizedBox(height: KitchenSpacing.lg),
              ...checkoutState.priceAlerts.map(
                (alert) => _PriceAlertTile(alert: alert),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(KitchenSpacing.lg),
            child: Column(
              children: [
                KitchenEmbossedButton(
                  onPressed: () => ref
                      .read(checkoutProvider.notifier)
                      .dismissAlertsAndContinue(),
                  semanticLabel: 'Continuer avec le panier mis a jour',
                  child: Text(l10n.checkoutContinueButton),
                ),
                const SizedBox(height: KitchenSpacing.xs),
                TextButton(
                  onPressed: () => context.pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: KitchenColors.cognac,
                    minimumSize: const Size(44, 44),
                  ),
                  child: Text(l10n.checkoutBackToCart),
                ),
              ],
            ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: KitchenSpacing.sm),
      child: KitchenSurface(
        padding: const EdgeInsets.all(KitchenSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              color: KitchenColors.cognac,
            ),
            const SizedBox(width: KitchenSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.item.product.name,
                    style: KitchenTypography.label.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: KitchenSpacing.xxs),
                  if (priceChanged)
                    Text(
                      l10n.checkoutPriceUpdated(
                        _formatPrice(alert.oldPrice),
                        _formatPrice(alert.newPrice),
                      ),
                      style: KitchenTypography.body.copyWith(
                        color: KitchenColors.terracotta,
                      ),
                    ),
                  if (becameUnavailable)
                    Text(
                      l10n.checkoutItemNoLongerAvailable,
                      style: KitchenTypography.body.copyWith(
                        color: KitchenColors.terracotta,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
