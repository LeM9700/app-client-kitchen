import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_colors.dart';
import 'package:app_client/core/widgets/empty_state.dart';
import 'package:app_client/features/cart/models/cart_item.dart';
import 'package:app_client/features/cart/models/cart_state.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';

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

    if (cart.isEmpty) {
      return const _EmptyCart();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panier'),
        actions: [
          TextButton(
            onPressed: () => ref.read(cartProvider.notifier).clear(),
            child: const Text('Vider'),
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
              padding: const EdgeInsets.fromLTRB(
                24,
                12,
                24,
                16,
              ),
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.checkout),
                child: Text('Commander - ${_formatPrice(cart.total)}'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Mon panier')),
      body: const EmptyState(
        title: 'Votre panier est vide',
        subtitle: 'Ajoutez des produits depuis le menu.',
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
    final selectedExtras = item.product.extras
        .where((extra) => item.selectedExtraIds.contains(extra.id))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
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
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Retirer',
                        visualDensity: VisualDensity.compact,
                        onPressed: onRemove,
                      ),
                    ],
                  ),
                  if (item.selectedVariant != null)
                    Text(
                      item.selectedVariant!.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (selectedExtras.isNotEmpty)
                    Text(
                      selectedExtras.map((e) => e.name).join(', '),
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StepperButton(
                        icon: Icons.remove,
                        onPressed: onDecrement,
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${item.quantity}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      _StepperButton(
                        icon: Icons.add,
                        onPressed: onIncrement,
                      ),
                      const Spacer(),
                      Text(
                        _formatPrice(item.totalPrice),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 26,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
        tooltip: icon == Icons.add ? 'Ajouter' : 'Retirer',
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text('Connectez-vous pour utiliser un code promo.'),
          ),
        ],
      ),
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
        notifier.setPromoError('Ce code promo n\'est pas valide.');
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Code promo',
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
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.black,
                  minimumSize: const Size(88, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: cart.isValidatingPromo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Appliquer'),
              ),
            ],
          ),
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
              'Code "${cart.promoCode}" appliqué : -${_formatPrice(cart.promoDiscount!)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
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

    return preview.when(
      data: (data) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.stars_rounded, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cette commande vous rapportera ${data.totalPoints} points fidélité.',
              ),
            ),
          ],
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(label: 'Sous-total', value: _formatPrice(cart.subtotal)),
          if (cart.promoDiscount != null)
            _SummaryRow(
              label:
                  'Remise${cart.promoCode != null ? ' (${cart.promoCode})' : ''}',
              value: '-${_formatPrice(cart.promoDiscount!)}',
            ),
          const _SummaryRow(label: 'Frais de livraison', value: 'Au checkout'),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Total',
            value: _formatPrice(cart.total),
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
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;

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
