import 'package:flutter/material.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';

/// Chip de sélection de catégorie dans la barre horizontale.
///
/// [isSelected] : state géré par [selectedCategoryProvider] dans le parent.
/// On passe le callback vers le haut plutôt que d'injecter le ref ici :
/// principe de séparation UI / logique.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(KitchenRadius.pill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: KitchenSpacing.md,
            vertical: KitchenSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: isSelected ? KitchenGradients.cognac : null,
            color: isSelected
                ? null
                : KitchenColors.paperLight.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(KitchenRadius.pill),
            border: Border.all(
              color: isSelected
                  ? KitchenColors.whiteWarm.withValues(alpha: 0.28)
                  : KitchenColors.brown700.withValues(alpha: 0.14),
            ),
          ),
          child: Text(
            label,
            style: KitchenTypography.label.copyWith(
              color:
                  isSelected ? KitchenColors.whiteWarm : KitchenColors.espresso,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
