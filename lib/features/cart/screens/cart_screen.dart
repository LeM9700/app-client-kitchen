import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_colors.dart';
import 'package:app_client/core/theme/kod_mome/kod_mome_design_pack.dart';
import 'package:app_client/core/widgets/empty_state.dart';
import 'package:app_client/design_system/kod_mome/glass_surface.dart';
import 'package:app_client/design_system/kod_mome/gold_foil_text.dart';
import 'package:app_client/design_system/kod_mome/medallion.dart';
import 'package:app_client/design_system/kod_mome/neumorphic_surface.dart';
import 'package:app_client/features/cart/models/cart_item.dart';
import 'package:app_client/features/cart/models/cart_state.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

String _formatPrice(double price) => '${price.toStringAsFixed(2)} €';

/// Écran panier — 100% local (voir décision d'architecture Plan 09), aucun
/// appel API tant que le checkout n'est pas lancé, hors aperçus code
/// promo/fidélité (lecture seule, authentifiés).
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final isAuthenticated = ref.watch(accessTokenProvider) != null;
    final l10n = AppLocalizations.of(context)!;
    final isKodMome = Env.isKodMomeBuild;

    if (cart.isEmpty) {
      return const _EmptyCart();
    }

    final checkoutLabel =
        l10n.cartCheckoutButton(_formatPrice(cart.total));

    return Scaffold(
      backgroundColor: isKodMome ? KodMomeDesignPack.charcoal : null,
      appBar: AppBar(
        backgroundColor: isKodMome ? KodMomeDesignPack.charcoal : null,
        foregroundColor: isKodMome ? KodMomeDesignPack.cream : null,
        title: Text(l10n.cartTitle),
        actions: [
          TextButton(
            onPressed: () => ref.read(cartProvider.notifier).clear(),
            child: Text(
              l10n.cartClearButton,
              style: isKodMome
                  ? const TextStyle(color: KodMomeDesignPack.primary)
                  : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              children: [
                // Liste des items
                ...cart.itemList.map(
                  (item) => _CartItemTile(
                    item: item,
                    onIncrement: () => ref
                        .read(cartProvider.notifier)
                        .updateQuantity(item.key, item.quantity + 1),
                    onDecrement: () => ref
                        .read(cartProvider.notifier)
                        .updateQuantity(item.key, item.quantity - 1),
                    onRemove: () =>
                        ref.read(cartProvider.notifier).removeItem(item.key),
                  ),
                ),

                const SizedBox(height: 16),

                // Code promo (uniquement si connecté)
                if (isAuthenticated)
                  _PromoCodeField(orderTotal: cart.subtotal)
                else
                  const _PromoLoginPrompt(),

                const SizedBox(height: 16),

                // Aperçu fidélité (uniquement si connecté)
                if (isAuthenticated)
                  _LoyaltyPreview(orderAmount: cart.subtotal),

                const SizedBox(height: 16),

                // Récapitulatif
                _CartSummary(cart: cart),
              ],
            ),
          ),

          // Bouton checkout
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: isKodMome
                  ? NeumorphicButton(
                      borderRadius: 16,
                      onTap: () => context.push(AppRoutes.checkout),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: GoldFoilText(
                          checkoutLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => context.push(AppRoutes.checkout),
                      child: Text(checkoutLabel),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Panier vide
// ──────────────────────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (Env.isKodMomeBuild) {
      return Scaffold(
        backgroundColor: KodMomeDesignPack.charcoal,
        appBar: AppBar(
          backgroundColor: KodMomeDesignPack.charcoal,
          foregroundColor: KodMomeDesignPack.cream,
          title: Text(l10n.cartEmptyTitle),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const KodMomeMedallion.empty(),
              const SizedBox(height: 20),
              Text(
                l10n.cartEmptyStateTitle,
                style: const TextStyle(
                  color: KodMomeDesignPack.cream,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.cartEmptyStateSubtitle,
                style: TextStyle(
                  color: KodMomeDesignPack.cream.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cartEmptyTitle)),
      body: EmptyState(
        title: l10n.cartEmptyStateTitle,
        subtitle: l10n.cartEmptyStateSubtitle,
        icon: Icons.shopping_bag_outlined,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Ligne panier
// ──────────────────────────────────────────────────────────────────────────────

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKodMome = Env.isKodMomeBuild;
    final selectedExtras = item.product.extras
        .where((extra) => item.selectedExtraIds.contains(extra.id))
        .toList();
    final nameColor = isKodMome ? KodMomeDesignPack.cream : null;
    final mutedColor =
        isKodMome ? KodMomeDesignPack.cream.withValues(alpha: 0.65) : null;

    final row = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 84,
              height: 84,
              child: item.product.imageUrl != null
                  ? Image.network(
                      item.product.imageUrl!,
                      fit: BoxFit.cover,
                      cacheWidth: 220,
                      errorBuilder: (_, __, ___) =>
                          const _CartImagePlaceholder(),
                    )
                  : const _CartImagePlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: nameColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: mutedColor),
                        tooltip: l10n.cartRemoveTooltip,
                        visualDensity: VisualDensity.compact,
                        onPressed: onRemove,
                      ),
                    ],
                  ),
                  if (item.selectedVariant != null)
                    Text(
                      item.selectedVariant!.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: mutedColor),
                    ),
                  if (selectedExtras.isNotEmpty)
                    Text(
                      selectedExtras.map((e) => e.name).join(', '),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: mutedColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StepperButton(
                        icon: Icons.remove,
                        onPressed: onDecrement,
                        tooltip: l10n.cartRemoveTooltip,
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${item.quantity}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: nameColor),
                        ),
                      ),
                      _StepperButton(
                        icon: Icons.add,
                        onPressed: onIncrement,
                        tooltip: l10n.cartAddTooltip,
                      ),
                      const Spacer(),
                      isKodMome
                          ? GoldFoilText(
                              _formatPrice(item.totalPrice),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            )
                          : Text(
                              _formatPrice(item.totalPrice),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );

    if (isKodMome) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: KodMomeGlassSurface(
          padding: const EdgeInsets.all(8),
          child: row,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: row,
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final isKodMome = Env.isKodMomeBuild;

    return SizedBox.square(
      dimension: 26,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        style: isKodMome
            ? IconButton.styleFrom(
                backgroundColor:
                    KodMomeDesignPack.primary.withValues(alpha: 0.16),
                foregroundColor: KodMomeDesignPack.primary,
              )
            : null,
      ),
    );
  }
}

class _CartImagePlaceholder extends StatelessWidget {
  const _CartImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Icon(
        Icons.local_pizza_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Code promo
// ──────────────────────────────────────────────────────────────────────────────

class _PromoLoginPrompt extends StatelessWidget {
  const _PromoLoginPrompt();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKodMome = Env.isKodMomeBuild;
    final textColor = isKodMome ? KodMomeDesignPack.cream : null;

    final row = Row(
      children: [
        Icon(Icons.lock_outline, size: 20, color: textColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.cartPromoLoginPrompt,
            style: TextStyle(color: textColor),
          ),
        ),
      ],
    );

    if (isKodMome) {
      return KodMomeGlassSurface(padding: const EdgeInsets.all(12), child: row);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: row,
    );
  }
}

/// Champ code promo — appelle `POST /promotions/validate` (preview lecture
/// seule, voir Décision d'architecture n°3). Réservé aux utilisateurs
/// connectés : [CartScreen] n'affiche ce widget que si authentifié.
class _PromoCodeField extends ConsumerStatefulWidget {
  const _PromoCodeField({required this.orderTotal});
  final double orderTotal;

  @override
  ConsumerState<_PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends ConsumerState<_PromoCodeField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    final invalidPromoMessage =
        AppLocalizations.of(context)!.cartPromoInvalidError;
    final notifier = ref.read(cartProvider.notifier);
    notifier.setValidatingPromo(true);
    try {
      final preview = await ref.read(promoRepositoryProvider).validatePromo(
            code: code,
            orderTotal: widget.orderTotal,
          );
      if (preview.valid) {
        notifier.setPromoResult(discount: preview.discount, code: code);
      } else {
        notifier.setPromoError(invalidPromoMessage);
      }
    } on AppException catch (e) {
      notifier.setPromoError(e.message);
    } finally {
      notifier.setValidatingPromo(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final l10n = AppLocalizations.of(context)!;
    final isKodMome = Env.isKodMomeBuild;

    final field = Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            style: isKodMome
                ? const TextStyle(color: KodMomeDesignPack.cream)
                : null,
            decoration: InputDecoration(
              labelText: l10n.cartPromoCodeLabel,
              labelStyle: isKodMome
                  ? TextStyle(
                      color: KodMomeDesignPack.cream.withValues(alpha: 0.6),
                    )
                  : null,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            enabled: !cart.isValidatingPromo,
            onSubmitted: (_) => _validate(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: cart.isValidatingPromo ? null : _validate,
          style: FilledButton.styleFrom(
            backgroundColor:
                isKodMome ? KodMomeDesignPack.primary : Colors.white,
            foregroundColor:
                isKodMome ? KodMomeDesignPack.charcoalDeep : AppColors.black,
            minimumSize: const Size(88, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: cart.isValidatingPromo
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.cartPromoApplyButton),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isKodMome
            ? KodMomeGlassSurface(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: field,
              )
            : Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: field,
              ),
        if (cart.promoError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              cart.promoError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (cart.promoCode != null && cart.promoDiscount != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.cartPromoAppliedLabel(
                cart.promoCode!,
                _formatPrice(cart.promoDiscount!),
              ),
              style: TextStyle(
                color: isKodMome
                    ? KodMomeDesignPack.primary
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Aperçu fidélité
// ──────────────────────────────────────────────────────────────────────────────

/// Aperçu des points fidélité gagnés pour cette commande, via
/// [loyaltyPreviewProvider]. Réservé aux utilisateurs connectés.
class _LoyaltyPreview extends ConsumerWidget {
  const _LoyaltyPreview({required this.orderAmount});
  final double orderAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(loyaltyPreviewProvider(orderAmount));
    final l10n = AppLocalizations.of(context)!;
    final isKodMome = Env.isKodMomeBuild;

    return preview.when(
      data: (data) {
        final row = Row(
          children: [
            Icon(
              Icons.stars_rounded,
              size: 20,
              color: isKodMome ? KodMomeDesignPack.primary : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.cartLoyaltyPreview(data.totalPoints),
                style: isKodMome
                    ? const TextStyle(color: KodMomeDesignPack.cream)
                    : null,
              ),
            ),
          ],
        );

        if (isKodMome) {
          return KodMomeGlassSurface(padding: const EdgeInsets.all(12), child: row);
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: row,
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      // Aperçu non bloquant : une erreur ici ne doit pas gêner le panier.
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Récapitulatif
// ──────────────────────────────────────────────────────────────────────────────

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart});
  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKodMome = Env.isKodMomeBuild;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryRow(
          label: l10n.cartSubtotalLabel,
          value: _formatPrice(cart.subtotal),
        ),
        if (cart.promoDiscount != null)
          _SummaryRow(
            label:
                '${l10n.cartDiscountLabel}${cart.promoCode != null ? ' (${cart.promoCode})' : ''}',
            value: '-${_formatPrice(cart.promoDiscount!)}',
          ),
        _SummaryRow(
          label: l10n.cartDeliveryFeeLabel,
          value: l10n.cartDeliveryFeeValue,
        ),
        Divider(
          height: 24,
          color: isKodMome
              ? KodMomeDesignPack.cream.withValues(alpha: 0.2)
              : null,
        ),
        _SummaryRow(
          label: l10n.cartTotalLabel,
          value: _formatPrice(cart.total),
          emphasize: true,
        ),
      ],
    );

    if (isKodMome) {
      // Seule surface avec vrai flou (BackdropFilter) de cet écran — la
      // barre "Commander" est neumorphique, pas glass. Voir les garde-fous
      // perf du plan Kod Mome (une surface héro max par écran).
      return KodMomeGlassSurface(
        variant: KodMomeGlassVariant.hero,
        padding: const EdgeInsets.all(14),
        child: content,
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: content,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final isKodMome = Env.isKodMomeBuild;
    final baseColor = isKodMome
        ? (emphasize
            ? KodMomeDesignPack.primary
            : KodMomeDesignPack.cream.withValues(alpha: 0.85))
        : null;
    final style = (emphasize
            ? Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )
            : Theme.of(context).textTheme.bodyMedium)
        ?.copyWith(color: baseColor);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
