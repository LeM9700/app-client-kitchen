import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/providers/catalog_search_provider.dart';
import 'package:app_client/features/catalog/widgets/allergen_filter_bar.dart';
import 'package:app_client/features/catalog/widgets/category_chip.dart';
import 'package:app_client/l10n/app_localizations.dart';

Future<void> showCatalogFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: KitchenColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(KitchenRadius.xl),
      ),
    ),
    builder: (_) => const CatalogFilterSheet(),
  );
}

class CatalogFilterSheet extends ConsumerWidget {
  const CatalogFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filters = ref.watch(catalogSearchFiltersProvider);
    final activeCount = ref.watch(catalogActiveFilterCountProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final products = ref.watch(allProductsProvider).valueOrNull ?? const [];
    final maxProductPrice = products.fold<double>(
      20.0,
      (current, product) => math.max(current, product.price.ceilToDouble()),
    );
    final maxPrice = math.max(20.0, maxProductPrice);
    final minValue = (filters.minPrice ?? 0).clamp(0, maxPrice).toDouble();
    final maxValue =
        (filters.maxPrice ?? maxPrice).clamp(minValue, maxPrice).toDouble();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.52,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            KitchenSpacing.lg,
            KitchenSpacing.md,
            KitchenSpacing.lg,
            MediaQuery.paddingOf(context).bottom + KitchenSpacing.lg,
          ),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: KitchenColors.brown700.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(KitchenRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: KitchenSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtres',
                    style: KitchenTypography.title.copyWith(fontSize: 30),
                  ),
                ),
                if (activeCount > 0)
                  TextButton(
                    onPressed: () {
                      ref.read(catalogSearchFiltersProvider.notifier).reset();
                      ref.read(activeAllergenFiltersProvider.notifier).state =
                          const {};
                      ref.read(selectedCategoryProvider.notifier).state = null;
                    },
                    child: Text(
                      'Reinitialiser les filtres',
                      style: KitchenTypography.label.copyWith(
                        color: KitchenColors.cognac,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: KitchenSpacing.sm),
            Text(
              'Les resultats se mettent a jour au fur et a mesure.',
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.textMuted,
              ),
            ),
            const SizedBox(height: KitchenSpacing.lg),
            _SheetSection(
              title: 'Prix',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RangeSlider(
                    min: 0,
                    max: maxPrice,
                    divisions: maxPrice.round(),
                    values: RangeValues(minValue, maxValue),
                    labels: RangeLabels(
                      formatPrice(minValue),
                      formatPrice(maxValue),
                    ),
                    activeColor: KitchenColors.cognac,
                    inactiveColor:
                        KitchenColors.brown700.withValues(alpha: 0.16),
                    onChanged: (values) {
                      ref
                          .read(catalogSearchFiltersProvider.notifier)
                          .setPriceRange(
                            values.start <= 0 ? null : values.start,
                            values.end >= maxPrice ? null : values.end,
                          );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KitchenSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Text(
                          formatPrice(minValue),
                          style: KitchenTypography.label,
                        ),
                        const Spacer(),
                        Text(
                          formatPrice(maxValue),
                          style: KitchenTypography.label,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KitchenSpacing.md),
            _SheetSection(
              title: 'Categorie',
              child: categoriesAsync.when(
                loading: () => const SizedBox(height: 44),
                error: (_, __) => const SizedBox.shrink(),
                data: (categories) {
                  final selectedCategoryId =
                      ref.watch(selectedCategoryProvider);
                  return Wrap(
                    spacing: KitchenSpacing.sm,
                    runSpacing: KitchenSpacing.sm,
                    children: [
                      CategoryChip(
                        label: 'Tout',
                        isSelected: selectedCategoryId == null,
                        onTap: () => ref
                            .read(selectedCategoryProvider.notifier)
                            .state = null,
                      ),
                      for (final category in categories)
                        CategoryChip(
                          label: category.name,
                          isSelected: selectedCategoryId == category.id,
                          onTap: () => ref
                                  .read(selectedCategoryProvider.notifier)
                                  .state =
                              selectedCategoryId == category.id
                                  ? null
                                  : category.id,
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: KitchenSpacing.md),
            _SheetSection(
              title: 'Preferences',
              child: Column(
                children: [
                  _SwitchRow(
                    icon: Icons.eco_outlined,
                    label: 'Vegetarien',
                    value: filters.vegetarianOnly,
                    onChanged: ref
                        .read(catalogSearchFiltersProvider.notifier)
                        .setVegetarianOnly,
                  ),
                  _SwitchRow(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Epice',
                    value: filters.spicyOnly,
                    onChanged: ref
                        .read(catalogSearchFiltersProvider.notifier)
                        .setSpicyOnly,
                  ),
                  _SwitchRow(
                    icon: Icons.star_border_rounded,
                    label: 'Populaire',
                    value: filters.popularOnly,
                    onChanged: ref
                        .read(catalogSearchFiltersProvider.notifier)
                        .setPopularOnly,
                  ),
                  _SwitchRow(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Nouveautes',
                    value: filters.newsOnly,
                    onChanged: ref
                        .read(catalogSearchFiltersProvider.notifier)
                        .setNewsOnly,
                  ),
                ],
              ),
            ),
            const SizedBox(height: KitchenSpacing.md),
            _SheetSection(
              title: 'Allergenes a exclure',
              child: Wrap(
                spacing: KitchenSpacing.xs,
                runSpacing: KitchenSpacing.xs,
                children: [
                  for (final entry in allergenLabels(l10n).entries)
                    _AllergenChip(code: entry.key, label: entry.value),
                ],
              ),
            ),
            const SizedBox(height: KitchenSpacing.xl),
            KitchenEmbossedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded),
                  SizedBox(width: KitchenSpacing.xs),
                  Text('Voir les resultats'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SheetSection extends StatelessWidget {
  const _SheetSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KitchenSurface(
      elevation: KitchenElevation.inset,
      padding: const EdgeInsets.all(KitchenSpacing.md),
      borderRadius: BorderRadius.circular(KitchenRadius.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: KitchenTypography.label.copyWith(
              color: KitchenColors.espresso,
            ),
          ),
          const SizedBox(height: KitchenSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: KitchenColors.cognac),
      title: Text(label, style: KitchenTypography.body),
      value: value,
      activeThumbColor: KitchenColors.cognac,
      onChanged: onChanged,
    );
  }
}

class _AllergenChip extends ConsumerWidget {
  const _AllergenChip({required this.code, required this.label});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilters = ref.watch(activeAllergenFiltersProvider);
    final isActive = activeFilters.contains(code);
    return FilterChip(
      label: Text(label),
      selected: isActive,
      showCheckmark: false,
      backgroundColor: KitchenColors.paperLight,
      selectedColor: KitchenColors.cognac.withValues(alpha: 0.16),
      side: BorderSide(
        color: isActive
            ? KitchenColors.cognac
            : KitchenColors.brown700.withValues(alpha: 0.16),
      ),
      labelStyle: KitchenTypography.label.copyWith(
        color: isActive ? KitchenColors.cognac : KitchenColors.textMuted,
        fontSize: 12,
      ),
      onSelected: (selected) {
        final current = ref.read(activeAllergenFiltersProvider);
        ref.read(activeAllergenFiltersProvider.notifier).state =
            selected ? {...current, code} : current.difference({code});
      },
    );
  }
}
