import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';

/// Rangée horizontale de produits recommandés en bas de la fiche produit.
///
/// Stratégie : afficher les autres produits de la même catégorie, en excluant
/// le produit courant. Pas de ML pour la v1 — simplicité > pertinence parfaite.
///
/// [⚡ PERF] Réutilise [productsByCategoryProvider] déjà chargé — pas de
/// requête supplémentaire si la catégorie a déjà été consultée.
class RecommendedProductsRow extends ConsumerWidget {
  const RecommendedProductsRow({
    super.key,
    required this.categoryId,
    required this.currentProductId,
  });

  final int? categoryId;
  final int currentProductId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryId = this.categoryId;
    if (categoryId == null) return const SizedBox.shrink();

    final productsAsync = ref.watch(productsByCategoryProvider(categoryId));

    return productsAsync.when(
      loading: () => const SizedBox(height: 120),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        final recommendations = products
            .where((p) => p.id != currentProductId && p.isAvailable)
            .take(6)
            .toList();

        if (recommendations.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Vous aimerez aussi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: recommendations.length,
                itemBuilder: (context, index) =>
                    _RecommendationCard(product: recommendations[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.productDetail(product.id.toString())),
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'product-${product.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 100,
                  width: 120,
                  child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          cacheWidth: 240,
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.local_pizza_outlined),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.name,
              style: theme.textTheme.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              product.displayPrice,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
