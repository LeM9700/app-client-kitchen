import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_colors.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/favorites_provider.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';

/// Photo-first product card used in catalogue grids and horizontal rows.
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, this.enableHero = true});

  final Product product;

  /// Désactive le [Hero] autour de l'image du produit.
  ///
  /// Par défaut `true` pour préserver l'animation de transition vers
  /// [ProductDetailScreen]. À mettre à `false` quand un même [ProductCard]
  /// (même `product.id`) peut être rendu plusieurs fois dans le même
  /// sous-arbre de route (ex. [HorizontalProductRow] utilisé pour la row
  /// "Incontournables" ET une row catégorie sur la home) — deux [Hero] avec
  /// le même tag dans le même subtree font planter Flutter.
  final bool enableHero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFavorite = ref.watch(
      favoritesProvider.select((favorites) => favorites.contains(product.id)),
    );
    final canQuickAdd =
        product.isAvailable && !product.hasVariants && !product.hasExtras;

    return InkWell(
      onTap: () => context.push(AppRoutes.productDetail(product.id.toString())),
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                _ProductImage(product: product, enableHero: enableHero),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _FavoriteButton(
                    isFavorite: isFavorite,
                    onTap: () =>
                        ref.read(favoritesProvider.notifier).toggle(product.id),
                  ),
                ),
                if (canQuickAdd)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _QuickAddButton(
                      onTap: () => _quickAdd(context, ref),
                    ),
                  ),
                if (!product.isAvailable)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Indisponible',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          if (product.description != null && product.description!.isNotEmpty)
            Text(
              product.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.grey700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else
            Text(
              product.isAvailable
                  ? "Disponible aujourd'hui"
                  : 'Momentanement indisponible',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.grey700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 3),
          Text(
            product.displayPrice,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.priceGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _quickAdd(BuildContext context, WidgetRef ref) {
    ref.read(cartProvider.notifier).addItem(product);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajouté au panier')),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product, required this.enableHero});

  final Product product;
  final bool enableHero;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(8),
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
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 17,
            color: isFavorite ? AppColors.brandRed : const Color(0xFF6E6E6E),
          ),
        ),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.brandRed,
          shape: BoxShape.circle,
        ),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.add, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.grey100,
      child: Icon(
        Icons.local_pizza_outlined,
        size: 42,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
