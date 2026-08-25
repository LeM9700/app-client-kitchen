import 'package:flutter/material.dart';

import 'package:app_client/features/catalog/widgets/allergen_filter_bar.dart';

/// Badge d'allergène affiché sur la fiche produit.
///
/// Utilise [kEuAllergens] défini dans [allergen_filter_bar.dart] pour
/// convertir le code API en libellé lisible.
///
/// Design : fond coloré discret, icône + texte. L'accent visuel est
/// intentionnellement modéré — informatif, pas alarmiste.
class AllergenBadge extends StatelessWidget {
  const AllergenBadge({super.key, required this.code});

  /// Code EU de l'allergène (ex: 'gluten', 'milk').
  final String code;

  @override
  Widget build(BuildContext context) {
    final label = kEuAllergens[code] ?? code;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 12,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
