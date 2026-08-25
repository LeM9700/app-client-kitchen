import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/features/catalog/providers/catalog_provider.dart';

/// Les 14 allergènes majeurs définis par le règlement UE 1169/2011.
///
/// Clé : code interne API. Valeur : libellé affiché.
const kEuAllergens = <String, String>{
  'gluten': 'Gluten',
  'crustaceans': 'Crustacés',
  'eggs': 'Œufs',
  'fish': 'Poisson',
  'peanuts': 'Arachides',
  'soybeans': 'Soja',
  'milk': 'Lait',
  'nuts': 'Fruits à coque',
  'celery': 'Céleri',
  'mustard': 'Moutarde',
  'sesame': 'Sésame',
  'sulphites': 'Sulfites',
  'lupin': 'Lupin',
  'molluscs': 'Mollusques',
};

/// Barre de filtrage par allergène.
///
/// Affichée en bandeau horizontal scrollable sous les chips catégories.
/// État géré par [activeAllergenFiltersProvider] (Riverpod global).
///
/// UX : sélectionner un allergène l'EXCLUT du catalogue affiché
/// ("je suis allergique au gluten → cache les produits avec gluten").
class AllergenFilterBar extends ConsumerWidget {
  const AllergenFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilters = ref.watch(activeAllergenFiltersProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.filter_alt_outlined,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                'Exclure les allergènes',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                  child: const Text('Effacer'),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: kEuAllergens.length,
            itemBuilder: (context, index) {
              final code = kEuAllergens.keys.elementAt(index);
              final label = kEuAllergens.values.elementAt(index);
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
                labelStyle: theme.textTheme.labelSmall,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
      ],
    );
  }
}
