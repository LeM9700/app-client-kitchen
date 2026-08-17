import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_colors.dart';
import 'package:app_client/core/widgets/empty_state.dart';
import 'package:app_client/core/widgets/error_view.dart';
import 'package:app_client/core/widgets/shimmer_skeleton.dart';
import 'package:app_client/features/catalog/models/category.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/widgets/category_chip.dart';
import 'package:app_client/features/catalog/widgets/product_card.dart';

/// Écran d'exploration complète du catalogue ("Voir tout" depuis la home).
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _ListHeader(
                title:
                    _titleFor(categoriesAsync.valueOrNull, selectedCategoryId),
              ),
            ),
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                loading: () => const SizedBox(
                  height: 54,
                  child: Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
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
            _ProductGrid(categoryId: selectedCategoryId),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  String _titleFor(List<Category>? categories, int? selectedCategoryId) {
    if (selectedCategoryId == null || categories == null) {
      return 'Explorer le menu';
    }
    final selected =
        categories.where((c) => c.id == selectedCategoryId).firstOrNull;
    return selected?.name ?? 'Explorer le menu';
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(42, 24, 42, 12),
      child: Row(
        children: [
          _HeaderButton(
            icon: Icons.arrow_back_ios_new,
            tooltip: 'Retour',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.home),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Container(
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Cloche décorative désactivée — même raison que home_screen.dart :
          // pas de flux de notifications consultable côté backend.
          const Icon(Icons.notifications_none, color: AppColors.grey400),
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
    return SizedBox.square(
      dimension: 38,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 21),
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
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 8),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return CategoryChip(
              label: 'Sélection',
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
  const _ProductGrid({required this.categoryId});

  final int? categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categoryId == null) {
      final featuredAsync = ref.watch(featuredProductsProvider);
      return featuredAsync.when(
        loading: () => const SliverToBoxAdapter(child: _ProductGridSkeleton()),
        error: (e, _) => SliverToBoxAdapter(
          child: ErrorView(
            message: 'Impossible de charger les recommendations.',
            onRetry: () => ref.invalidate(featuredProductsProvider),
          ),
        ),
        data: (products) => products.isEmpty
            ? const SliverToBoxAdapter(
                child: EmptyState(
                  title: 'Aucun produit disponible',
                  subtitle: 'Les produits recommandes apparaitront ici.',
                  icon: Icons.restaurant_menu_outlined,
                ),
              )
            : _ProductSliver(products: products),
      );
    }

    final filteredAsync = ref.watch(filteredProductsProvider(categoryId!));
    return filteredAsync.when(
      loading: () => const SliverToBoxAdapter(child: _ProductGridSkeleton()),
      error: (e, _) => SliverToBoxAdapter(
        child: ErrorView(
          message: 'Impossible de charger cette categorie.',
          onRetry: () =>
              ref.invalidate(productsByCategoryProvider(categoryId!)),
        ),
      ),
      data: (products) => products.isEmpty
          ? const SliverToBoxAdapter(
              child: EmptyState(
                title: 'Aucun produit disponible',
                subtitle: 'Essayez une autre categorie.',
                icon: Icons.search_off_outlined,
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
      padding: const EdgeInsets.symmetric(horizontal: 42),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: _gridDelegate(MediaQuery.sizeOf(context).width),
        itemCount: 8,
        itemBuilder: (_, __) => const Column(
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
    );
  }
}

class _ProductSliver extends StatelessWidget {
  const _ProductSliver({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(42, 4, 42, 0),
      sliver: SliverGrid.builder(
        gridDelegate: _gridDelegate(MediaQuery.sizeOf(context).width),
        itemCount: products.length,
        itemBuilder: (context, index) => ProductCard(product: products[index]),
      ),
    );
  }
}

SliverGridDelegateWithFixedCrossAxisCount _gridDelegate(double width) {
  final columns = width >= 1100 ? 4 : (width >= 700 ? 3 : 2);
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    mainAxisSpacing: 24,
    crossAxisSpacing: width >= 700 ? 26 : 48,
    childAspectRatio: width >= 700 ? 0.86 : 0.68,
  );
}
