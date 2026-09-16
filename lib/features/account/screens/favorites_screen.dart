import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/providers/favorites_provider.dart';
import 'package:app_client/features/catalog/widgets/product_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(favoriteProductsProvider);
    final favoriteCount = ref.watch(favoritesProvider).length;

    return Scaffold(
      backgroundColor: KitchenColors.paper,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _FavoritesHeader(favoriteCount: favoriteCount),
            ),
            productsAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: KitchenLoadingIndicator(
                    color: KitchenColors.cognac,
                    size: 34,
                  ),
                ),
              ),
              error: (_, __) => SliverFillRemaining(
                hasScrollBody: false,
                child: _FavoritesMessage(
                  icon: Icons.error_outline_rounded,
                  title: 'Favoris indisponibles',
                  subtitle: 'Impossible de charger vos favoris pour le moment.',
                  actionLabel: 'Recharger',
                  onAction: () => ref.invalidate(allProductsProvider),
                ),
              ),
              data: (products) => products.isEmpty
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _FavoritesMessage(
                        icon: Icons.favorite_border_rounded,
                        title: 'Aucun favori',
                        subtitle:
                            'Touchez le coeur d une pizza pour la retrouver ici.',
                      ),
                    )
                  : _FavoriteProductsGrid(products: products),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 112)),
          ],
        ),
      ),
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({required this.favoriteCount});

  final int favoriteCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KitchenSpacing.lg,
        KitchenSpacing.md,
        KitchenSpacing.lg,
        KitchenSpacing.sm,
      ),
      child: Row(
        children: [
          KitchenEmbossedButton(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.account),
            shape: BoxShape.circle,
            padding: EdgeInsets.zero,
            semanticLabel: 'Retour',
            child: const Icon(Icons.arrow_back_rounded, size: 21),
          ),
          const SizedBox(width: KitchenSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes favoris',
                  style: KitchenTypography.title.copyWith(fontSize: 34),
                ),
                const SizedBox(height: KitchenSpacing.xxs),
                Text(
                  favoriteCount == 0
                      ? 'Vos pizzas sauvegardees.'
                      : '$favoriteCount pizza${favoriteCount > 1 ? 's' : ''} sauvegardee${favoriteCount > 1 ? 's' : ''}.',
                  style: KitchenTypography.body.copyWith(
                    color: KitchenColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteProductsGrid extends StatelessWidget {
  const _FavoriteProductsGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        KitchenSpacing.lg,
        KitchenSpacing.sm,
        KitchenSpacing.lg,
        0,
      ),
      sliver: SliverGrid.builder(
        gridDelegate: _gridDelegate(MediaQuery.sizeOf(context).width),
        itemCount: products.length,
        itemBuilder: (context, index) => ProductCard(product: products[index]),
      ),
    );
  }
}

class _FavoritesMessage extends StatelessWidget {
  const _FavoritesMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KitchenSpacing.lg),
        child: KitchenSurface(
          padding: const EdgeInsets.all(KitchenSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: KitchenColors.cognac, size: 40),
              const SizedBox(height: KitchenSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: KitchenTypography.title.copyWith(fontSize: 30),
              ),
              const SizedBox(height: KitchenSpacing.xs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: KitchenTypography.body.copyWith(
                  color: KitchenColors.textMuted,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: KitchenSpacing.lg),
                KitchenEmbossedButton(
                  onPressed: onAction,
                  semanticLabel: actionLabel,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

SliverGridDelegateWithFixedCrossAxisCount _gridDelegate(double width) {
  final columns = width >= 1100 ? 4 : (width >= 720 ? 3 : 2);
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    mainAxisSpacing: KitchenSpacing.lg,
    crossAxisSpacing: width >= 720 ? KitchenSpacing.lg : KitchenSpacing.md,
    childAspectRatio: width >= 720 ? 0.84 : 0.68,
  );
}
