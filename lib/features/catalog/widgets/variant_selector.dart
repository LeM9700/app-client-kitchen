import 'package:flutter/material.dart';

import 'package:app_client/features/catalog/models/product.dart';

/// Sélecteur de variante (ex: Petite / Moyenne / Grande).
///
/// State géré par le parent via [selectedVariantId] + [onChanged].
/// Pattern callback-up pour rester testable sans Riverpod.
class VariantSelector extends StatelessWidget {
  const VariantSelector({
    super.key,
    required this.variants,
    required this.selectedVariantId,
    required this.onChanged,
    this.basePrice = 0,
  });

  final List<ProductVariant> variants;
  final int? selectedVariantId;
  final ValueChanged<int> onChanged;
  final double basePrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Taille', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: variants.map((variant) {
            final isSelected = variant.id == selectedVariantId;
            final totalPrice = basePrice + variant.priceDelta;

            return GestureDetector(
              onTap: () => onChanged(variant.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.4),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      variant.name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${totalPrice.toStringAsFixed(2)} €',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimary.withValues(alpha: 0.8)
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
