import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

const kEuAllergens = <String, String>{
  'gluten': 'Gluten',
  'crustaceans': 'Crustaces',
  'eggs': 'Oeufs',
  'fish': 'Poisson',
  'peanuts': 'Arachides',
  'soybeans': 'Soja',
  'milk': 'Lait',
  'nuts': 'Fruits a coque',
  'celery': 'Celeri',
  'mustard': 'Moutarde',
  'sesame': 'Sesame',
  'sulphites': 'Sulfites',
  'lupin': 'Lupin',
  'molluscs': 'Mollusques',
};

Map<String, String> allergenLabels(AppLocalizations l10n) => {
      'gluten': l10n.allergenGluten,
      'crustaceans': l10n.allergenCrustaceans,
      'eggs': l10n.allergenEggs,
      'fish': l10n.allergenFish,
      'peanuts': l10n.allergenPeanuts,
      'soybeans': l10n.allergenSoybeans,
      'milk': l10n.allergenMilk,
      'nuts': l10n.allergenNuts,
      'celery': l10n.allergenCelery,
      'mustard': l10n.allergenMustard,
      'sesame': l10n.allergenSesame,
      'sulphites': l10n.allergenSulphites,
      'lupin': l10n.allergenLupin,
      'molluscs': l10n.allergenMolluscs,
    };

class AllergenFilterBar extends ConsumerWidget {
  const AllergenFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilters = ref.watch(activeAllergenFiltersProvider);
    final l10n = AppLocalizations.of(context)!;
    final labels = allergenLabels(l10n);

    return Padding(
      padding: const EdgeInsets.only(bottom: KitchenSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KitchenSpacing.lg,
              vertical: KitchenSpacing.xxs,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.filter_alt_outlined,
                  size: 16,
                  color: KitchenColors.textMuted,
                ),
                const SizedBox(width: KitchenSpacing.xs),
                Text(
                  l10n.allergenExcludeLabel,
                  style: KitchenTypography.label.copyWith(
                    color: KitchenColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (activeFilters.isNotEmpty) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: () => ref
                        .read(activeAllergenFiltersProvider.notifier)
                        .state = const {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.allergenClearLabel,
                      style: KitchenTypography.label.copyWith(
                        color: KitchenColors.cognac,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: KitchenSpacing.lg,
              ),
              separatorBuilder: (_, __) =>
                  const SizedBox(width: KitchenSpacing.xs),
              itemCount: kEuAllergens.length,
              itemBuilder: (context, index) {
                final code = kEuAllergens.keys.elementAt(index);
                final label = labels[code] ?? code;
                final isActive = activeFilters.contains(code);

                return FilterChip(
                  label: Text(label),
                  selected: isActive,
                  onSelected: (selected) {
                    final current = ref.read(activeAllergenFiltersProvider);
                    ref.read(activeAllergenFiltersProvider.notifier).state =
                        selected
                            ? {...current, code}
                            : current.difference({code});
                  },
                  showCheckmark: false,
                  backgroundColor: KitchenColors.paperLight,
                  selectedColor: KitchenColors.cognac.withValues(alpha: 0.16),
                  side: BorderSide(
                    color: isActive
                        ? KitchenColors.cognac
                        : KitchenColors.brown700.withValues(alpha: 0.16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KitchenRadius.pill),
                  ),
                  labelStyle: KitchenTypography.label.copyWith(
                    color: isActive
                        ? KitchenColors.cognac
                        : KitchenColors.textMuted,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: KitchenSpacing.xs,
                  ),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
