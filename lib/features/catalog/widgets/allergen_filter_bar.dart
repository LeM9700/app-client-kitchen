import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

/// Les 14 allergènes majeurs définis par le règlement UE 1169/2011.
///
/// Clé : code interne API. Valeur : libellé affiché (français — utilisé
/// par [AllergenBadge] sur la fiche produit, pas encore localisée).
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

/// Mêmes 14 allergènes, libellés localisés — utilisé uniquement par
/// [AllergenFilterBar] (écran retouché). [kEuAllergens] reste la source
/// française utilisée par les écrans pas encore localisés.
Map<String, String> _allergenLabels(AppLocalizations l10n) => {
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
    final l10n = AppLocalizations.of(context)!;
    final labels = _allergenLabels(l10n);

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
                l10n.allergenExcludeLabel,
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
                  child: Text(l10n.allergenClearLabel),
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
