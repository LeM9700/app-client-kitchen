import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_colors.dart';
import 'package:app_client/core/theme/kod_mome/kod_mome_design_pack.dart';
import 'package:app_client/design_system/kod_mome/neumorphic_surface.dart';
import 'package:app_client/features/catalog/models/category.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/widgets/allergen_filter_bar.dart';
import 'package:app_client/features/catalog/widgets/horizontal_product_row.dart';
import 'package:app_client/features/catalog/widgets/promo_hero_carousel.dart';
import 'package:app_client/features/loyalty/providers/loyalty_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor:
          Env.isKodMomeBuild ? KodMomeDesignPack.charcoal : null,
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
                title: l10n.homeFeaturedSectionTitle,
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
    final l10n = AppLocalizations.of(context)!;
    final isAuthenticated = ref.watch(accessTokenProvider) != null;
    final isKodMome = Env.isKodMomeBuild;
    final labelColor =
        isKodMome ? KodMomeDesignPack.cream.withValues(alpha: 0.65) : null;
    final addressColor = isKodMome ? KodMomeDesignPack.cream : null;
    final decorativeIconColor =
        isKodMome ? KodMomeDesignPack.cream.withValues(alpha: 0.45) : AppColors.grey400;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isKodMome
                ? KodMomeDesignPack.primary.withValues(alpha: 0.16)
                : AppColors.grey100,
            child: Icon(
              Icons.person,
              color: isKodMome ? KodMomeDesignPack.primary : AppColors.brandGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeDeliverTo,
                  style: theme.textTheme.labelSmall?.copyWith(color: labelColor),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: isKodMome
                          ? KodMomeDesignPack.primary
                          : AppColors.priceGreen,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        l10n.homeDeliveryAddressPlaceholder,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: addressColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Chevron décoratif désactivé : un vrai sélecteur d'adresse
                    // est hors périmètre de ce plan (déferré) — il réutiliserait
                    // l'UI de sélection d'adresse déjà construite pour le
                    // checkout (features/checkout/screens/steps/step_address.dart).
                    // Couleur alignée sur la cloche de notifications (grey400)
                    // pour signaler visuellement qu'il ne s'agit pas d'un
                    // contrôle interactif.
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: decorativeIconColor,
                    ),
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
          Icon(Icons.notifications_none, color: decorativeIconColor),
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
      data: (account) {
        final accentColor = Env.isKodMomeBuild
            ? KodMomeDesignPack.primary
            : AppColors.brandRed;
        return InkWell(
          onTap: () => context.push(AppRoutes.loyalty),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Env.isKodMomeBuild
                  ? Border.all(color: accentColor, width: 1)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, size: 14, color: accentColor),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!
                      .loyaltyPointsLabel(account.points),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchEntry extends ConsumerWidget {
  const _SearchEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isKodMome = Env.isKodMomeBuild;
    final iconColor = isKodMome ? KodMomeDesignPack.primary : AppColors.black;
    final textColor = isKodMome ? KodMomeDesignPack.cream : null;

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
          decoration: isKodMome
              ? kodMomeNeumorphicFieldDecoration(borderRadius: 8)
              : BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
          child: Row(
            children: [
              Icon(Icons.search, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.homeSearchPlaceholder,
                  style: TextStyle(color: textColor),
                ),
              ),
              VerticalDivider(
                width: 24,
                color: isKodMome
                    ? KodMomeDesignPack.primary.withValues(alpha: 0.4)
                    : null,
              ),
              Icon(Icons.tune, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}
