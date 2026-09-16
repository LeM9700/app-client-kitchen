import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/models/tenant_branding.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/theme/tenant_theme_provider.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_brand_logo.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/models/category.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/models/tenant_public_info.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/providers/catalog_search_provider.dart';
import 'package:app_client/features/catalog/providers/favorites_provider.dart';
import 'package:app_client/features/catalog/providers/tenant_public_provider.dart';
import 'package:app_client/features/catalog/widgets/catalog_search_box.dart';
import 'package:app_client/features/catalog/widgets/category_chip.dart';
import 'package:app_client/features/catalog/widgets/horizontal_product_row.dart';
import 'package:app_client/features/catalog/widgets/promo_hero_carousel.dart';
import 'package:app_client/features/checkout/providers/client_location_provider.dart';
import 'package:app_client/features/loyalty/providers/loyalty_provider.dart';
import 'package:app_client/features/notifications/widgets/notification_bell_button.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/providers/order_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isAuthenticated = ref.watch(accessTokenProvider) != null;
    final allProductsAsync = ref.watch(filteredAllProductsProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: KitchenColors.paper,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _HomeHeader()),
                const SliverToBoxAdapter(
                  child: CatalogSearchBox(navigateOnSubmit: true),
                ),
                categoriesAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 58,
                      child: Center(
                        child: KitchenLoadingIndicator(
                          color: KitchenColors.cognac,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  error: (_, __) =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                  data: (categories) => SliverToBoxAdapter(
                    child: _HomeCategoryStrip(categories: categories),
                  ),
                ),
                const SliverToBoxAdapter(child: PromoHeroCarousel()),
                const SliverToBoxAdapter(child: _KodMomeInfoBand()),
                SliverToBoxAdapter(
                  child: HorizontalProductRow(
                    title: 'Incontournables',
                    productsAsync: allProductsAsync.whenData(
                      (products) => products.take(6).toList(),
                    ),
                    onSeeAll: () {
                      ref.read(selectedCategoryProvider.notifier).state = null;
                      context.push(AppRoutes.search);
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: HorizontalProductRow(
                    title: 'Pizzas vedettes',
                    productsAsync: ref.watch(filteredFeaturedProductsProvider),
                    onSeeAll: () {
                      ref
                          .read(catalogSearchFiltersProvider.notifier)
                          .setPopularOnly(true);
                      context.push(AppRoutes.search);
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ProductOrPlaceholderRow(
                    title: 'Boissons',
                    emptyText: 'Les boissons arrivent bientot.',
                    productsAsync: allProductsAsync.whenData(
                      (products) => products
                          .where(
                            (product) => productLooksLikeKind(
                              product,
                              CatalogSectionKind.drinks,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ProductOrPlaceholderRow(
                    title: 'Desserts',
                    emptyText: 'Les desserts seront ajoutes au menu.',
                    productsAsync: allProductsAsync.whenData(
                      (products) => products
                          .where(
                            (product) => productLooksLikeKind(
                              product,
                              CatalogSectionKind.desserts,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ProductOrPlaceholderRow(
                    title: 'Nouveautes',
                    emptyText: 'Aucune nouveaute pour le moment.',
                    productsAsync: allProductsAsync.whenData(
                      (products) => products
                          .where(
                            (product) => productLooksLikeKind(
                              product,
                              CatalogSectionKind.news,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                if (isAuthenticated) ...[
                  const SliverToBoxAdapter(child: _ReorderSection()),
                  SliverToBoxAdapter(
                    child: HorizontalProductRow(
                      title: 'Mes favoris',
                      productsAsync: ref.watch(favoriteProductsProvider),
                      onSeeAll: () => context.push(AppRoutes.favorites),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 148)),
              ],
            ),
            if (!cart.isEmpty) const _StickyCartCta(),
          ],
        ),
      ),
    );
  }
}

class _HomeCategoryStrip extends ConsumerWidget {
  const _HomeCategoryStrip({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          KitchenSpacing.lg,
          KitchenSpacing.xs,
          KitchenSpacing.lg,
          KitchenSpacing.sm,
        ),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: KitchenSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return CategoryChip(
              label: 'Tout',
              isSelected: ref.watch(selectedCategoryProvider) == null,
              onTap: () {
                ref.read(selectedCategoryProvider.notifier).state = null;
                context.push(AppRoutes.search);
              },
            );
          }
          final category = categories[index - 1];
          return CategoryChip(
            label: category.name,
            isSelected: ref.watch(selectedCategoryProvider) == category.id,
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = category.id;
              context.push(AppRoutes.search);
            },
          );
        },
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isAuthenticated = ref.watch(accessTokenProvider) != null;
    final branding = ref.watch(tenantBrandingProvider);
    final clientLocation = ref.watch(clientLocationProvider);
    final rawName = branding.displayName?.trim();
    final displayName = Env.isKodMomeBuild
        ? 'KOD MOME'
        : rawName == null || rawName.isEmpty
            ? 'Kitchen'
            : rawName;
    final locationLabel =
        clientLocation == null ? l10n.homeDeliverTo : 'Position client';
    final locationValue = clientLocation?.address.trim().isNotEmpty == true
        ? clientLocation!.address
        : l10n.homeDeliveryAddressPlaceholder;
    final coordinates = clientLocation?.coordinates;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KitchenSpacing.lg,
        KitchenSpacing.md,
        KitchenSpacing.lg,
        KitchenSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const KitchenBrandLogo(size: 58),
              const SizedBox(width: KitchenSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: KitchenTypography.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: KitchenSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: KitchenColors.cognac,
                        ),
                        const SizedBox(width: KitchenSpacing.xxs),
                        Text(
                          locationLabel,
                          style: KitchenTypography.label.copyWith(
                            color: KitchenColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: KitchenSpacing.xs),
                        Expanded(
                          child: Text(
                            locationValue,
                            style: KitchenTypography.body.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: KitchenColors.textMuted.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ],
                    ),
                    if (coordinates != null) ...[
                      const SizedBox(height: KitchenSpacing.xxs),
                      Text(
                        coordinates,
                        style: KitchenTypography.body.copyWith(
                          color: KitchenColors.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: KitchenSpacing.sm),
              const NotificationBellButton(),
            ],
          ),
          if (isAuthenticated) ...[
            const SizedBox(height: KitchenSpacing.md),
            const _LoyaltyBadge(),
          ],
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
      data: (account) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(KitchenRadius.pill),
          onTap: () => context.push(AppRoutes.loyalty),
          child: KitchenSurface(
            elevation: KitchenElevation.inset,
            borderRadius: BorderRadius.circular(KitchenRadius.pill),
            padding: const EdgeInsets.symmetric(
              horizontal: KitchenSpacing.sm,
              vertical: KitchenSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars_rounded,
                  size: 16,
                  color: KitchenColors.cognac,
                ),
                const SizedBox(width: KitchenSpacing.xs),
                Text(
                  AppLocalizations.of(context)!
                      .loyaltyPointsLabel(account.points),
                  style: KitchenTypography.label.copyWith(
                    color: KitchenColors.cognac,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KodMomeInfoBand extends ConsumerWidget {
  const _KodMomeInfoBand();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(tenantBrandingProvider);
    final statusAsync = ref.watch(tenantStatusProvider);
    final hoursAsync = ref.watch(tenantBusinessHoursProvider);
    final status = statusAsync.valueOrNull;
    final contactChips = _contactChips(branding);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KitchenSpacing.lg,
        KitchenSpacing.sm,
        KitchenSpacing.lg,
        KitchenSpacing.lg,
      ),
      child: KitchenSurface(
        elevation: KitchenElevation.inset,
        borderRadius: BorderRadius.circular(KitchenRadius.lg),
        padding: const EdgeInsets.all(KitchenSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: KitchenGradients.cognac,
                    borderRadius: BorderRadius.circular(KitchenRadius.md),
                  ),
                  child: const Icon(
                    Icons.local_pizza_outlined,
                    color: KitchenColors.whiteWarm,
                  ),
                ),
                const SizedBox(width: KitchenSpacing.sm),
                Expanded(
                  child: Text(
                    _restaurantName(branding.displayName),
                    style: KitchenTypography.title.copyWith(fontSize: 29),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusPill(
                  label: _statusPillLabel(statusAsync),
                  isOpen: status?.isOpen,
                ),
              ],
            ),
            const SizedBox(height: KitchenSpacing.md),
            Text(
              'Une pizzeria de quartier pensee pour commander vite: recettes genereuses, pate travaillee, cuisson minute et favoris a portee de main.',
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.textMuted,
              ),
            ),
            const SizedBox(height: KitchenSpacing.md),
            Wrap(
              spacing: KitchenSpacing.sm,
              runSpacing: KitchenSpacing.sm,
              children: [
                _InfoChip(
                  icon: Icons.storefront_outlined,
                  label: _statusDetailLabel(statusAsync),
                ),
                _InfoChip(
                  icon: Icons.schedule_rounded,
                  label: _todayHoursLabel(hoursAsync),
                ),
                const _InfoChip(
                  icon: Icons.delivery_dining_outlined,
                  label: 'Zone livraison verifiee au checkout',
                ),
                ...contactChips,
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _restaurantName(String? displayName) {
    final name = displayName?.trim();
    if (Env.isKodMomeBuild || name == null || name.isEmpty) {
      return 'KOD MOME';
    }
    return name;
  }

  String _statusPillLabel(AsyncValue<TenantStatusInfo> statusAsync) {
    return statusAsync.when(
      loading: () => 'Chargement',
      error: (_, __) => 'Statut indisponible',
      data: (status) => status.isOpen ? 'Ouvert' : 'Ferme',
    );
  }

  String _statusDetailLabel(AsyncValue<TenantStatusInfo> statusAsync) {
    return statusAsync.when(
      loading: () => 'Statut restaurant en cours',
      error: (_, __) => 'Statut restaurant indisponible',
      data: (status) {
        if (status.isOpen) {
          return 'Ouvert maintenant - prep ${status.estimatedPrepTimeMinutes} min';
        }
        final message = _clean(status.message);
        if (message != null) return message;
        final nextOpening = _clean(status.nextOpening);
        if (nextOpening != null) return 'Rouvre $nextOpening';
        return 'Ferme pour le moment';
      },
    );
  }

  String _todayHoursLabel(AsyncValue<List<BusinessHourInfo>> hoursAsync) {
    return hoursAsync.when(
      loading: () => 'Chargement des horaires',
      error: (_, __) => 'Horaires indisponibles',
      data: (hours) {
        final today = DateTime.now().weekday - 1;
        final slots = hours
            .where((slot) => slot.dayOfWeek == today && slot.isActive)
            .toList()
          ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
        if (slots.isEmpty) return 'Aujourd\'hui ferme';
        final label = slots
            .map((slot) => '${slot.opensShort}-${slot.closesShort}')
            .join(' / ');
        return 'Aujourd\'hui $label';
      },
    );
  }

  List<Widget> _contactChips(TenantBranding branding) {
    final chips = <Widget>[];
    final phone = _clean(branding.contactPhone);
    final email = _clean(branding.contactEmail);
    final instagram = _clean(branding.instagramUrl);
    final googleBusiness = _clean(branding.googleBusinessUrl);

    if (phone != null) {
      chips.add(
        _InfoChip(icon: Icons.phone_outlined, label: phone),
      );
    }
    if (email != null) {
      chips.add(
        _InfoChip(icon: Icons.mail_outline, label: email),
      );
    }
    if (instagram != null) {
      chips.add(
        _InfoChip(
          icon: Icons.alternate_email_rounded,
          label: _instagramLabel(instagram),
        ),
      );
    }
    if (googleBusiness != null) {
      chips.add(
        const _InfoChip(
          icon: Icons.travel_explore_outlined,
          label: 'Fiche Google Business disponible',
        ),
      );
    }
    if (chips.isEmpty) {
      chips.add(
        const _InfoChip(
          icon: Icons.alternate_email_rounded,
          label: 'Contacts a renseigner par le restaurant',
        ),
      );
    }
    return chips;
  }

  String _instagramLabel(String url) {
    final uri = Uri.tryParse(url);
    String? handle;
    if (uri != null) {
      for (final segment in uri.pathSegments) {
        if (segment.trim().isNotEmpty) {
          handle = segment;
          break;
        }
      }
    }
    if (handle == null) return 'Instagram disponible';
    return 'Instagram @$handle';
  }

  String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.isOpen});

  final String label;
  final bool? isOpen;

  @override
  Widget build(BuildContext context) {
    final color = switch (isOpen) {
      true => KitchenColors.olive,
      false => KitchenColors.terracotta,
      null => KitchenColors.cognac,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KitchenSpacing.sm,
        vertical: KitchenSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(KitchenRadius.pill),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: KitchenTypography.label.copyWith(
          color: color,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KitchenSpacing.sm,
        vertical: KitchenSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: KitchenColors.paperLight,
        borderRadius: BorderRadius.circular(KitchenRadius.pill),
        border: Border.all(
          color: KitchenColors.brown700.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: KitchenColors.cognac),
          const SizedBox(width: KitchenSpacing.xs),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width - 96,
            ),
            child: Text(
              label,
              style: KitchenTypography.label.copyWith(
                color: KitchenColors.textMuted,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductOrPlaceholderRow extends StatelessWidget {
  const _ProductOrPlaceholderRow({
    required this.title,
    required this.emptyText,
    required this.productsAsync,
  });

  final String title;
  final String emptyText;
  final AsyncValue<List<Product>> productsAsync;

  @override
  Widget build(BuildContext context) {
    return productsAsync.when(
      loading: () => HorizontalProductRow(
        title: title,
        productsAsync: productsAsync,
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isNotEmpty) {
          return HorizontalProductRow(
            title: title,
            productsAsync: AsyncValue.data(products),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            KitchenSpacing.lg,
            KitchenSpacing.sm,
            KitchenSpacing.lg,
            KitchenSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: KitchenTypography.title.copyWith(fontSize: 28),
              ),
              const SizedBox(height: KitchenSpacing.sm),
              KitchenSurface(
                elevation: KitchenElevation.inset,
                borderRadius: BorderRadius.circular(KitchenRadius.md),
                padding: const EdgeInsets.all(KitchenSpacing.lg),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      color: KitchenColors.cognac,
                    ),
                    const SizedBox(width: KitchenSpacing.sm),
                    Expanded(
                      child: Text(
                        emptyText,
                        style: KitchenTypography.body.copyWith(
                          color: KitchenColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReorderSection extends ConsumerWidget {
  const _ReorderSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderHistoryProvider);
    if (state.isLoading || state.error != null) {
      return const SizedBox.shrink();
    }

    final orders = state.orders.take(3).toList();
    if (orders.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KitchenSpacing.lg,
        KitchenSpacing.sm,
        KitchenSpacing.lg,
        KitchenSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commander a nouveau',
            style: KitchenTypography.title.copyWith(fontSize: 28),
          ),
          const SizedBox(height: KitchenSpacing.sm),
          for (final order in orders) _ReorderTile(order: order),
        ],
      ),
    );
  }
}

class _ReorderTile extends ConsumerWidget {
  const _ReorderTile({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = order.items.isEmpty
        ? 'Commande #${order.id}'
        : order.items
            .take(2)
            .map((item) => item.productName ?? 'Produit')
            .join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: KitchenSpacing.sm),
      child: KitchenSurface(
        elevation: KitchenElevation.inset,
        borderRadius: BorderRadius.circular(KitchenRadius.md),
        padding: const EdgeInsets.all(KitchenSpacing.md),
        child: Row(
          children: [
            const Icon(
              Icons.replay_rounded,
              color: KitchenColors.cognac,
            ),
            const SizedBox(width: KitchenSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: KitchenTypography.body.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KitchenSpacing.xxs),
                  Text(
                    formatPrice(order.total),
                    style: KitchenTypography.label.copyWith(
                      color: KitchenColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final outcome =
                      await ref.read(reorderProvider).reorder(order.id);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        '${outcome.addedCount} article(s) ajoute(s) au panier',
                      ),
                    ),
                  );
                  if (context.mounted) context.push(AppRoutes.cart);
                } catch (_) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Impossible de recommander pour le moment'),
                    ),
                  );
                }
              },
              child: const Text('Recommander'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyCartCta extends ConsumerWidget {
  const _StickyCartCta();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Positioned(
      left: KitchenSpacing.lg,
      right: KitchenSpacing.lg,
      bottom: KitchenSpacing.md,
      child: KitchenEmbossedButton(
        onPressed: () => context.push(AppRoutes.cart),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined),
            const SizedBox(width: KitchenSpacing.sm),
            Flexible(
              child: Text(
                'Voir le panier - ${cart.totalQuantity} article(s) - ${formatPrice(cart.total)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
