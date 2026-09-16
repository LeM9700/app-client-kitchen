import 'package:flutter/material.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/l10n/app_localizations.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.productSizeLabel,
          style: KitchenTypography.title.copyWith(fontSize: 25),
        ),
        const SizedBox(height: KitchenSpacing.sm),
        Wrap(
          spacing: KitchenSpacing.sm,
          runSpacing: KitchenSpacing.sm,
          children: variants.map((variant) {
            final isSelected = variant.id == selectedVariantId;
            final totalPrice = basePrice + variant.priceDelta;

            return Semantics(
              selected: isSelected,
              button: true,
              child: GestureDetector(
                onTap: () => onChanged(variant.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: KitchenSpacing.md,
                    vertical: KitchenSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? KitchenGradients.cognac : null,
                    color: isSelected ? null : KitchenColors.paperLight,
                    borderRadius: BorderRadius.circular(KitchenRadius.md),
                    border: Border.all(
                      color: isSelected
                          ? KitchenColors.whiteWarm.withValues(alpha: 0.38)
                          : KitchenColors.brown700.withValues(alpha: 0.18),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              color: Color(0x2E2D1B13),
                              blurRadius: 14,
                              offset: Offset(0, 7),
                            ),
                          ]
                        : const [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        variant.name,
                        style: KitchenTypography.label.copyWith(
                          color: isSelected
                              ? KitchenColors.whiteWarm
                              : KitchenColors.espresso,
                        ),
                      ),
                      const SizedBox(height: KitchenSpacing.xxs),
                      Text(
                        formatPrice(totalPrice),
                        style: KitchenTypography.body.copyWith(
                          color: isSelected
                              ? KitchenColors.whiteWarm.withValues(alpha: 0.82)
                              : KitchenColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
