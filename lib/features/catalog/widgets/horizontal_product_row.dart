import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/widgets/shimmer_skeleton.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/widgets/product_card.dart';

/// Row horizontale de produits réutilisable pour les sections de la home
/// (Incontournables, catégories). Se masque silencieusement en cas d'erreur
/// ou de liste vide — une home ne doit pas afficher d'écran d'erreur par
/// section, seulement les sections qui ont du contenu.
class HorizontalProductRow extends StatelessWidget {
  const HorizontalProductRow({
    super.key,
    required this.title,
    required this.productsAsync,
    this.onSeeAll,
  });

  final String title;
  final AsyncValue<List<Product>> productsAsync;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return productsAsync.when(
      loading: () => _RowSkeleton(title: title),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RowHeader(title: title, onSeeAll: onSeeAll),
              SizedBox(
                height: 236,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, index) => SizedBox(
                    width: 160,
                    child: ProductCard(
                      product: products[index],
                      enableHero: false,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RowHeader extends StatelessWidget {
  const _RowHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: const Text('Voir tout')),
        ],
      ),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RowHeader(title: title),
        SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, __) => const SizedBox(
              width: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: ShimmerBlock(borderRadius: 8)),
                  SizedBox(height: 8),
                  ShimmerBlock(height: 14, width: 120),
                  SizedBox(height: 6),
                  ShimmerBlock(height: 12, width: 60),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
