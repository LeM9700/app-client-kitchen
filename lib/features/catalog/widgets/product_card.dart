import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/favorites_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, this.enableHero = true});

  final Product product;
  final bool enableHero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isFavorite = ref.watch(
      favoritesProvider.select((favorites) => favorites.contains(product.id)),
    );
    final isAuthenticated = ref.watch(accessTokenProvider) != null;
    final canQuickAdd =
        product.isAvailable && !product.hasVariants && !product.hasExtras;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: KitchenRadius.card,
        onTap: () =>
            context.push(AppRoutes.productDetail(product.id.toString())),
        child: KitchenSurface(
          padding: const EdgeInsets.all(KitchenSpacing.xs),
          borderRadius: KitchenRadius.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ProductImage(product: product, enableHero: enableHero),
                    Positioned(
                      top: KitchenSpacing.xs,
                      right: KitchenSpacing.xs,
                      child: _FavoriteButton(
                        isFavorite: isFavorite,
                        isAuthenticated: isAuthenticated,
                        onTap: () =>
                            _toggleFavorite(context, ref, isAuthenticated),
                      ),
                    ),
                    if (canQuickAdd)
                      Positioned(
                        bottom: KitchenSpacing.xs,
                        right: KitchenSpacing.xs,
                        child: _QuickAddButton(
                          tooltip: l10n.productAddToCartButton,
                          onTap: () => _quickAdd(context, ref, l10n),
                        ),
                      ),
                    if (!product.isAvailable)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: KitchenColors.espresso.withValues(
                              alpha: 0.56,
                            ),
                            borderRadius: BorderRadius.circular(
                              KitchenRadius.md,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              l10n.productUnavailable,
                              style: KitchenTypography.label.copyWith(
                                color: KitchenColors.whiteWarm,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: KitchenSpacing.sm),
              Text(
                product.name,
                style: KitchenTypography.body.copyWith(
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: KitchenSpacing.xxs),
              Text(
                _subtitle(l10n),
                style: KitchenTypography.body.copyWith(
                  color: KitchenColors.textMuted,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: KitchenSpacing.xs),
              Text(
                product.displayPrice,
                style: KitchenTypography.label.copyWith(
                  color: KitchenColors.cognac,
                  fontSize: 14,
                ),
              ),
              if (product.indicativePriceLabel != null) ...[
                const SizedBox(height: KitchenSpacing.xxs),
                Text(
                  product.indicativePriceLabel!,
                  style: KitchenTypography.label.copyWith(
                    color: KitchenColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(AppLocalizations l10n) {
    final description = product.description?.trim();
    if (description != null && description.isNotEmpty) return description;
    return product.isAvailable
        ? l10n.productAvailableToday
        : l10n.productTemporarilyUnavailable;
  }

  void _quickAdd(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    ref.read(cartProvider.notifier).addItem(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.productAddedToCart)),
    );
  }

  void _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    bool isAuthenticated,
  ) {
    if (!isAuthenticated) {
      final redirect = Uri.encodeComponent(AppRoutes.home);
      context.push('${AppRoutes.login}?redirect=$redirect');
      return;
    }
    ref.read(favoritesProvider.notifier).toggle(product.id);
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product, required this.enableHero});

  final Product product;
  final bool enableHero;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(KitchenRadius.md),
      child: SizedBox.expand(
        child: product.imageUrl != null
            ? Image.network(
                product.imageUrl!,
                fit: BoxFit.cover,
                cacheWidth: 520,
                errorBuilder: (_, __, ___) => const _ProductImagePlaceholder(),
              )
            : const _ProductImagePlaceholder(),
      ),
    );

    if (!enableHero) return image;

    return Hero(tag: 'product-${product.id}', child: image);
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.isAuthenticated,
    required this.onTap,
  });

  final bool isFavorite;
  final bool isAuthenticated;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isAuthenticated
          ? (isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris')
          : 'Connectez-vous pour enregistrer vos favoris',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: KitchenColors.whiteWarm.withValues(alpha: 0.88),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x242D1B13),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: !isAuthenticated
                  ? KitchenColors.textMuted
                  : isFavorite
                      ? KitchenColors.terracotta
                      : KitchenColors.espresso,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: KitchenGradients.cognac,
            boxShadow: [
              BoxShadow(
                color: Color(0x302D1B13),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            size: 22,
            color: KitchenColors.whiteWarm,
          ),
        ),
      ),
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: KitchenColors.flour,
      child: Center(
        child: Icon(
          Icons.local_pizza_outlined,
          size: 42,
          color: KitchenColors.cognac,
        ),
      ),
    );
  }
}
