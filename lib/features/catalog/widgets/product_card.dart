import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_colors.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/favorites_provider.dart';

/// Photo-first product card used in catalogue grids and horizontal rows.
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFavorite = ref.watch(
      favoritesProvider.select((favorites) => favorites.contains(product.id)),
    );

    return InkWell(
      onTap: () => context.push(AppRoutes.productDetail(product.id.toString())),
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Hero(
                  tag: 'product-${product.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox.expand(
                      child: product.imageUrl != null
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              cacheWidth: 520,
                              errorBuilder: (_, __, ___) =>
                                  const _ProductImagePlaceholder(),
                            )
                          : const _ProductImagePlaceholder(),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _FavoriteButton(
                    isFavorite: isFavorite,
                    onTap: () =>
                        ref.read(favoritesProvider.notifier).toggle(product.id),
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
