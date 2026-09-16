import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/core/widgets/shimmer_skeleton.dart';
import 'package:app_client/features/catalog/models/category.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/providers/catalog_search_provider.dart';
import 'package:app_client/features/catalog/widgets/catalog_search_box.dart';
import 'package:app_client/features/catalog/widgets/category_chip.dart';
import 'package:app_client/features/catalog/widgets/product_card.dart';
import 'package:app_client/features/notifications/widgets/notification_bell_button.dart';

/// Ecran d'exploration complete du catalogue ("Voir tout" depuis la home).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialQuery?.trim();
    if (initialQuery != null && initialQuery.isNotEmpty) {
      Future.microtask(
        () => ref.read(searchQueryProvider.notifier).state = initialQuery,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);
    final query = ref.watch(searchQueryProvider).trim();
    final title =
        _titleFor(categoriesAsync.valueOrNull, selectedCategoryId, query);

    return Scaffold(
      backgroundColor: KitchenColors.paper,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _ListHeader(
                title: title,
                hasCategorySelection: selectedCategoryId != null,
              ),
            ),
            const SliverToBoxAdapter(
              child: CatalogSearchBox(autofocus: false),
            ),
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                loading: () => const SizedBox(
                  height: 58,
                  child: Center(
                    child: KitchenLoadingIndicator(
                      color: KitchenColors.cognac,
                      size: 30,
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (categories) => _FilterStrip(
                  categories: categories,
                  selectedCategoryId: selectedCategoryId,
                ),
              ),
            ),
            const _ProductGrid(),
            const SliverToBoxAdapter(child: SizedBox(height: 112)),
          ],
        ),
      ),
    );
  }

  String _titleFor(
    List<Category>? categories,
    int? selectedCategoryId,
    String query,
  ) {
    if (query.isNotEmpty) {
      return 'Recherche';
    }
    if (selectedCategoryId == null || categories == null) {
      return 'Explorer le menu';
    }
    final selected =
        categories.where((c) => c.id == selectedCategoryId).firstOrNull;
    return selected?.name ?? 'Explorer le menu';
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.title,
    required this.hasCategorySelection,
  });

  final String title;
  final bool hasCategorySelection;

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HeaderButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Retour',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.home),
          ),
          const SizedBox(width: KitchenSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KitchenTypography.title.copyWith(fontSize: 30),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: KitchenSpacing.xxs),
                Text(
                  hasCategorySelection
                      ? 'Toutes les recettes de cette categorie.'
                      : 'Toutes les pizzas disponibles a la commande.',
                  style: KitchenTypography.body.copyWith(
                    color: KitchenColors.textMuted,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: KitchenSpacing.sm),
          const NotificationBellButton(),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: KitchenEmbossedButton(
        onPressed: onPressed,
        shape: BoxShape.circle,
        padding: EdgeInsets.zero,
        semanticLabel: tooltip,
        child: Icon(icon, size: 21),
      ),
    );
  }
}

class _FilterStrip extends ConsumerWidget {
  const _FilterStrip({
    required this.categories,
    required this.selectedCategoryId,
  });

  final List<Category> categories;
  final int? selectedCategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: KitchenSpacing.lg,
          vertical: KitchenSpacing.xs,
        ),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: KitchenSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return CategoryChip(
              label: 'Tout',
              isSelected: selectedCategoryId == null,
              onTap: () =>
                  ref.read(selectedCategoryProvider.notifier).state = null,
            );
          }
          final category = categories[index - 1];
          return CategoryChip(
            label: category.name,
            isSelected: selectedCategoryId == category.id,
            onTap: () => ref.read(selectedCategoryProvider.notifier).state =
                selectedCategoryId == category.id ? null : category.id,
          );
        },
      ),
    );
  }
}

class _ProductGrid extends ConsumerWidget {
  const _ProductGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(catalogSearchResultsProvider);
    final hasActiveQueryOrFilter =
        ref.watch(searchQueryProvider).trim().isNotEmpty ||
            ref.watch(catalogActiveFilterCountProvider) > 0;

    return resultsAsync.when(
      loading: () => const SliverToBoxAdapter(child: _ProductGridSkeleton()),
      error: (e, _) => SliverToBoxAdapter(
        child: _InlineError(
          message: 'Impossible de charger le menu.',
          onRetry: () => ref.invalidate(allProductsProvider),
        ),
      ),
      data: (products) => products.isEmpty
          ? SliverToBoxAdapter(
              child: _EmptyPanel(
                title: hasActiveQueryOrFilter
                    ? 'Aucun produit correspondant'
                    : 'Aucun produit disponible',
                subtitle: hasActiveQueryOrFilter
                    ? 'Modifiez votre recherche ou reinitialisez les filtres.'
                    : 'Le menu sera visible des que la cuisine l ouvre.',
                icon: Icons.search_off_outlined,
                actionLabel:
                    hasActiveQueryOrFilter ? 'Reinitialiser les filtres' : null,
                onAction: hasActiveQueryOrFilter
                    ? () {
                        ref.read(searchQueryProvider.notifier).state = '';
                        ref.read(catalogSearchFiltersProvider.notifier).reset();
                        ref.read(activeAllergenFiltersProvider.notifier).state =
                            const {};
                        ref.read(selectedCategoryProvider.notifier).state =
                            null;
                      }
                    : null,
              ),
            )
          : _ProductSliver(products: products),
    );
  }
}

class _ProductGridSkeleton extends StatelessWidget {
  const _ProductGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _gridPadding,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: _gridDelegate(MediaQuery.sizeOf(context).width),
        itemCount: 8,
        itemBuilder: (_, __) => const KitchenSurface(
          padding: EdgeInsets.all(KitchenSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ShimmerBlock(
                  borderRadius: KitchenRadius.md,
                  height: double.infinity,
                ),
              ),
              SizedBox(height: KitchenSpacing.sm),
              ShimmerBlock(height: 14, width: 120),
              SizedBox(height: KitchenSpacing.xs),
              ShimmerBlock(height: 12, width: 80),
              SizedBox(height: KitchenSpacing.xs),
              ShimmerBlock(height: 14, width: 58),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductSliver extends StatelessWidget {
  const _ProductSliver({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: _gridPadding,
      sliver: SliverGrid.builder(
        gridDelegate: _gridDelegate(MediaQuery.sizeOf(context).width),
        itemCount: products.length,
        itemBuilder: (context, index) => ProductCard(product: products[index]),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(KitchenSpacing.lg),
      child: KitchenSurface(
        padding: const EdgeInsets.all(KitchenSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: KitchenColors.terracotta,
              size: 38,
            ),
            const SizedBox(height: KitchenSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.textMuted,
              ),
            ),
            const SizedBox(height: KitchenSpacing.md),
            KitchenEmbossedButton(
              onPressed: onRetry,
              semanticLabel: 'Recharger le menu',
              child: const Text('REESSAYER'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(KitchenSpacing.lg),
      child: KitchenSurface(
        padding: const EdgeInsets.all(KitchenSpacing.xl),
        child: Column(
          children: [
            Icon(icon, color: KitchenColors.cognac, size: 38),
            const SizedBox(height: KitchenSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: KitchenTypography.title.copyWith(fontSize: 28),
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
              const SizedBox(height: KitchenSpacing.md),
              KitchenEmbossedButton(
                onPressed: onAction,
                child: Text(actionLabel!.toUpperCase()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

const _gridPadding = EdgeInsets.fromLTRB(
  KitchenSpacing.lg,
  KitchenSpacing.sm,
  KitchenSpacing.lg,
  0,
);

SliverGridDelegateWithFixedCrossAxisCount _gridDelegate(double width) {
  final columns = width >= 1100 ? 4 : (width >= 720 ? 3 : 2);
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    mainAxisSpacing: KitchenSpacing.lg,
    crossAxisSpacing: width >= 720 ? KitchenSpacing.lg : KitchenSpacing.md,
    childAspectRatio: width >= 720 ? 0.84 : 0.68,
  );
}
