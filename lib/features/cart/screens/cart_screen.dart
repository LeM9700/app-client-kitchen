import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_brand_logo.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/cart/models/cart_item.dart';
import 'package:app_client/features/cart/models/cart_state.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final isAuthenticated = ref.watch(accessTokenProvider) != null;
    final l10n = AppLocalizations.of(context)!;

    if (cart.isEmpty) {
      return const _EmptyCart();
    }

    final checkoutLabel = l10n.cartCheckoutButton(formatPrice(cart.total));

    return Scaffold(
      backgroundColor: KitchenColors.paper,
      appBar: AppBar(
        backgroundColor: KitchenColors.paper,
        foregroundColor: KitchenColors.espresso,
        title: Text(
          l10n.cartTitle,
          style: KitchenTypography.title.copyWith(fontSize: 28),
        ),
        actions: [
          TextButton(
            onPressed: () => ref.read(cartProvider.notifier).clear(),
            child: Text(
              l10n.cartClearButton,
              style: KitchenTypography.label.copyWith(
                color: KitchenColors.cognac,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                KitchenSpacing.lg,
                KitchenSpacing.md,
                KitchenSpacing.lg,
                KitchenSpacing.lg,
              ),
              children: [
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
                const SizedBox(height: KitchenSpacing.md),
                if (isAuthenticated)
                  _PromoCodeField(orderTotal: cart.subtotal)
                else
                  const _PromoLoginPrompt(),
                const SizedBox(height: KitchenSpacing.md),
                if (isAuthenticated)
                  _LoyaltyPreview(orderAmount: cart.subtotal),
                const SizedBox(height: KitchenSpacing.md),
                _CartSummary(cart: cart),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(
              KitchenSpacing.lg,
              KitchenSpacing.sm,
              KitchenSpacing.lg,
              KitchenSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: KitchenEmbossedButton(
                onPressed: () => context.push(AppRoutes.checkout),
                semanticLabel: checkoutLabel,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_outlined),
                    const SizedBox(width: KitchenSpacing.sm),
                    Flexible(child: Text(checkoutLabel)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: KitchenColors.paper,
      appBar: AppBar(
        backgroundColor: KitchenColors.paper,
        foregroundColor: KitchenColors.espresso,
        title: Text(
          l10n.cartEmptyTitle,
          style: KitchenTypography.title.copyWith(fontSize: 28),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(KitchenSpacing.lg),
          child: KitchenSurface(
            padding: const EdgeInsets.all(KitchenSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const KitchenBrandLogo(size: 96),
                const SizedBox(height: KitchenSpacing.lg),
                Text(
                  l10n.cartEmptyStateTitle,
                  style: KitchenTypography.title.copyWith(fontSize: 26),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KitchenSpacing.xs),
                Text(
                  l10n.cartEmptyStateSubtitle,
                  style: KitchenTypography.body.copyWith(
                    color: KitchenColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    final selectedExtras = item.product.extras
        .where((extra) => item.selectedExtraIds.contains(extra.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: KitchenSpacing.md),
      child: KitchenSurface(
        padding: const EdgeInsets.all(KitchenSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(KitchenRadius.md),
              child: SizedBox(
                width: 86,
                height: 86,
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
            const SizedBox(width: KitchenSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          style: KitchenTypography.body.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: KitchenColors.textMuted,
                        tooltip: l10n.cartRemoveTooltip,
                        visualDensity: VisualDensity.compact,
                        onPressed: onRemove,
                      ),
                    ],
                  ),
                  if (item.selectedVariant != null)
                    Text(
                      item.selectedVariant!.name,
                      style: KitchenTypography.body.copyWith(
                        color: KitchenColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  if (selectedExtras.isNotEmpty)
                    Text(
                      selectedExtras.map((extra) => extra.name).join(', '),
                      style: KitchenTypography.body.copyWith(
                        color: KitchenColors.textMuted,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: KitchenSpacing.sm),
                  Row(
                    children: [
                      _StepperButton(
                        icon: Icons.remove,
                        onPressed: onDecrement,
                        tooltip: l10n.cartRemoveTooltip,
                      ),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${item.quantity}',
                          textAlign: TextAlign.center,
                          style: KitchenTypography.body.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _StepperButton(
                        icon: Icons.add,
                        onPressed: onIncrement,
                        tooltip: l10n.cartAddTooltip,
                      ),
                      const Spacer(),
                      Text(
                        formatPrice(item.totalPrice),
                        style: KitchenTypography.label.copyWith(
                          color: KitchenColors.cognac,
                          fontSize: 14,
                        ),
                      ),
                    ],
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
    return SizedBox.square(
      dimension: 34,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: KitchenColors.cognac.withValues(alpha: 0.12),
          foregroundColor: KitchenColors.espresso,
        ),
      ),
    );
  }
}

class _CartImagePlaceholder extends StatelessWidget {
  const _CartImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: KitchenColors.flour,
      child: Center(
        child: Icon(
          Icons.local_pizza_outlined,
          color: KitchenColors.cognac,
        ),
      ),
    );
  }
}

class _PromoLoginPrompt extends StatelessWidget {
  const _PromoLoginPrompt();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return KitchenSurface(
      elevation: KitchenElevation.inset,
      padding: const EdgeInsets.all(KitchenSpacing.md),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline,
            size: 20,
            color: KitchenColors.cognac,
          ),
          const SizedBox(width: KitchenSpacing.sm),
          Expanded(
            child: Text(
              l10n.cartPromoLoginPrompt,
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    } on AppException catch (error) {
      notifier.setPromoError(error.message);
    } finally {
      notifier.setValidatingPromo(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KitchenSurface(
          elevation: KitchenElevation.inset,
          padding: const EdgeInsets.fromLTRB(
            KitchenSpacing.md,
            KitchenSpacing.xs,
            KitchenSpacing.xs,
            KitchenSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  style: KitchenTypography.body,
                  cursorColor: KitchenColors.cognac,
                  decoration: InputDecoration(
                    labelText: l10n.cartPromoCodeLabel,
                    labelStyle: KitchenTypography.body.copyWith(
                      color: KitchenColors.textMuted,
                    ),
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
              const SizedBox(width: KitchenSpacing.xs),
              FilledButton(
                onPressed: cart.isValidatingPromo ? null : _validate,
                style: FilledButton.styleFrom(
                  backgroundColor: KitchenColors.cognac,
                  foregroundColor: KitchenColors.whiteWarm,
                  minimumSize: const Size(96, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: KitchenSpacing.sm,
                  ),
                ),
                child: cart.isValidatingPromo
                    ? const KitchenLoadingIndicator(
                        size: 28,
                        color: KitchenColors.whiteWarm,
                      )
                    : Text(l10n.cartPromoApplyButton),
              ),
            ],
          ),
        ),
        if (cart.promoError != null)
          Padding(
            padding: const EdgeInsets.only(top: KitchenSpacing.xs),
            child: Text(
              cart.promoError!,
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.terracotta,
                fontSize: 13,
              ),
            ),
          ),
        if (cart.promoCode != null && cart.promoDiscount != null)
          Padding(
            padding: const EdgeInsets.only(top: KitchenSpacing.xs),
            child: Text(
              l10n.cartPromoAppliedLabel(
                cart.promoCode!,
                formatPrice(cart.promoDiscount!),
              ),
              style: KitchenTypography.label.copyWith(
                color: KitchenColors.olive,
              ),
            ),
          ),
      ],
    );
  }
}

class _LoyaltyPreview extends ConsumerWidget {
  const _LoyaltyPreview({required this.orderAmount});

  final double orderAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(loyaltyPreviewProvider(orderAmount));
    final l10n = AppLocalizations.of(context)!;

    return preview.when(
      data: (data) => KitchenSurface(
        elevation: KitchenElevation.inset,
        padding: const EdgeInsets.all(KitchenSpacing.md),
        child: Row(
          children: [
            const Icon(
              Icons.stars_rounded,
              size: 20,
              color: KitchenColors.cognac,
            ),
            const SizedBox(width: KitchenSpacing.sm),
            Expanded(
              child: Text(
                l10n.cartLoyaltyPreview(data.totalPoints),
                style: KitchenTypography.body.copyWith(
                  color: KitchenColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: KitchenSpacing.sm),
        child: Center(
          child: KitchenLoadingIndicator(
            color: KitchenColors.cognac,
            size: 34,
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return KitchenSurface(
      padding: const EdgeInsets.all(KitchenSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            label: l10n.cartSubtotalLabel,
            value: formatPrice(cart.subtotal),
          ),
          if (cart.promoDiscount != null)
            _SummaryRow(
              label:
                  '${l10n.cartDiscountLabel}${cart.promoCode != null ? ' (${cart.promoCode})' : ''}',
              value: '-${formatPrice(cart.promoDiscount!)}',
            ),
          _SummaryRow(
            label: l10n.cartDeliveryFeeLabel,
            value: l10n.cartDeliveryFeeValue,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: KitchenSpacing.sm),
            child: Divider(
              color: KitchenColors.brown700.withValues(alpha: 0.16),
            ),
          ),
          _SummaryRow(
            label: l10n.cartTotalLabel,
            value: formatPrice(cart.total),
            emphasize: true,
          ),
        ],
      ),
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
    final style = emphasize
        ? KitchenTypography.label.copyWith(
            color: KitchenColors.cognac,
            fontSize: 16,
          )
        : KitchenTypography.body.copyWith(
            color: KitchenColors.textMuted,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KitchenSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: style)),
          const SizedBox(width: KitchenSpacing.md),
          Text(value, style: style),
        ],
      ),
    );
  }
}
