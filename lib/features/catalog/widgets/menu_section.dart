import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/catalog/models/menu.dart';
import 'package:app_client/features/catalog/providers/menu_provider.dart';

class MenuSection extends ConsumerWidget {
  const MenuSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menus = ref.watch(menusProvider);
    return menus.when(
      loading: () => const SizedBox(
        height: 248,
        child: Center(
          child: KitchenLoadingIndicator(color: KitchenColors.cognac),
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.fromLTRB(
          KitchenSpacing.lg,
          KitchenSpacing.sm,
          KitchenSpacing.lg,
          KitchenSpacing.lg,
        ),
        child: KitchenSurface(
          elevation: KitchenElevation.inset,
          padding: const EdgeInsets.all(KitchenSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.restaurant_menu, color: KitchenColors.cognac),
              const SizedBox(width: KitchenSpacing.sm),
              const Expanded(child: Text('Les menus sont indisponibles.')),
              IconButton(
                tooltip: 'Reessayer',
                onPressed: () => ref.invalidate(menusProvider),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ),
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : _MenuSectionBody(menus: items),
    );
  }
}

class _MenuSectionBody extends StatelessWidget {
  const _MenuSectionBody({required this.menus});

  final List<CatalogMenu> menus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KitchenSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KitchenSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Menus',
                    style: KitchenTypography.title.copyWith(fontSize: 31),
                  ),
                ),
                Text(
                  'Formules a prix fixe',
                  style: KitchenTypography.label.copyWith(
                    color: KitchenColors.olive,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KitchenSpacing.sm),
          SizedBox(
            height: 258,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: KitchenSpacing.lg),
              itemCount: menus.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: KitchenSpacing.md),
              itemBuilder: (context, index) => _MenuCard(menu: menus[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.menu});

  final CatalogMenu menu;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 286,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: KitchenRadius.card,
          onTap: () => context.push(AppRoutes.menuDetail(menu.id)),
          child: KitchenSurface(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(KitchenRadius.lg),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (menu.imageUrl?.trim().isNotEmpty == true)
                          Image.network(
                            menu.imageUrl!,
                            fit: BoxFit.cover,
                            cacheWidth: 620,
                            errorBuilder: (_, __, ___) =>
                                const _MenuImageFallback(),
                          )
                        else
                          const _MenuImageFallback(),
                        Positioned(
                          top: KitchenSpacing.sm,
                          right: KitchenSpacing.sm,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: KitchenColors.paperLight,
                              borderRadius: BorderRadius.circular(
                                KitchenRadius.pill,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: KitchenSpacing.sm,
                                vertical: KitchenSpacing.xs,
                              ),
                              child: Text(
                                formatPrice(menu.fixedPrice),
                                style: KitchenTypography.label.copyWith(
                                  color: KitchenColors.cognac,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(KitchenSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KitchenTypography.title.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: KitchenSpacing.xxs),
                      Text(
                        '${menu.groups.length} choix a composer',
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
          ),
        ),
      ),
    );
  }
}

class _MenuImageFallback extends StatelessWidget {
  const _MenuImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: KitchenColors.flour,
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 52,
          color: KitchenColors.cognac,
        ),
      ),
    );
  }
}
