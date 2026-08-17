import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_colors.dart';
import 'package:app_client/features/catalog/models/category.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/widgets/allergen_filter_bar.dart';
import 'package:app_client/features/catalog/widgets/horizontal_product_row.dart';
import 'package:app_client/features/catalog/widgets/promo_hero_carousel.dart';
import 'package:app_client/features/loyalty/providers/loyalty_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _HomeHeader()),
            const SliverToBoxAdapter(child: PromoHeroCarousel()),
            const SliverToBoxAdapter(child: _SearchEntry()),
            const SliverToBoxAdapter(child: AllergenFilterBar()),
            SliverToBoxAdapter(
              child: HorizontalProductRow(
                title: 'Incontournables',
                productsAsync: ref.watch(filteredFeaturedProductsProvider),
                onSeeAll: () {
                  ref.read(selectedCategoryProvider.notifier).state = null;
                  context.push(AppRoutes.search);
                },
              ),
            ),
            categoriesAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: SizedBox(
                  height: 74,
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (categories) => SliverToBoxAdapter(
                child: _CategoryRows(categories: categories),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 112)),
          ],
        ),
      ),
    );
  }
}

class _CategoryRows extends ConsumerWidget {
  const _CategoryRows({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (final category in categories)
          HorizontalProductRow(
            title: category.name,
            productsAsync: ref.watch(filteredProductsProvider(category.id)),
            onSeeAll: () {
              ref.read(selectedCategoryProvider.notifier).state = category.id;
              context.push(AppRoutes.search);
            },
          ),
      ],
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAuthenticated = ref.watch(accessTokenProvider) != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.grey100,
            child: Icon(Icons.person, color: AppColors.brandGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Livrer a', style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.priceGreen,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        'Adresse de livraison',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Chevron décoratif désactivé : un vrai sélecteur d'adresse
                    // est hors périmètre de ce plan (déferré) — il réutiliserait
                    // l'UI de sélection d'adresse déjà construite pour le
                    // checkout (features/checkout/screens/steps/step_address.dart).
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
                if (isAuthenticated) ...[
                  const SizedBox(height: 4),
                  const _LoyaltyBadge(),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Cloche décorative désactivée : aucun flux de notifications
          // consultable n'existe côté backend aujourd'hui (le module
          // `notifications` ne gère que l'enregistrement des tokens push).
          // Un bouton qui ne fait rien est trompeur — à réactiver une fois
          // l'endpoint de flux disponible (audit UX home, Phase 13).
          const Icon(Icons.notifications_none, color: AppColors.grey400),
        ],
      ),
    );
  }
}

class _LoyaltyBadge extends ConsumerWidget {
  const _LoyaltyBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(loyaltyAccountProvider);

    return accountAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (account) => InkWell(
        onTap: () => context.push(AppRoutes.loyalty),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.brandRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.stars_rounded,
                size: 14,
                color: AppColors.brandRed,
              ),
              const SizedBox(width: 4),
              Text(
                '${account.points} points',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.brandRed,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchEntry extends ConsumerWidget {
  const _SearchEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: InkWell(
        onTap: () {
          ref.read(selectedCategoryProvider.notifier).state = null;
          context.push(AppRoutes.search);
        },
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: AppColors.black),
              SizedBox(width: 10),
              Expanded(
                child: Text('Que souhaitez-vous commander ?'),
              ),
              VerticalDivider(width: 24),
              Icon(Icons.tune, color: AppColors.black),
            ],
          ),
        ),
      ),
    );
  }
}
