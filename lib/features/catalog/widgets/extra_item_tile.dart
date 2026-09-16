import 'package:flutter/material.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/features/catalog/models/product.dart';

class ExtraItemTile extends StatelessWidget {
  const ExtraItemTile({
    super.key,
    required this.extra,
    required this.isSelected,
    required this.onChanged,
  });

  final ProductExtra extra;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !extra.available;
    final textColor = isDisabled
        ? KitchenColors.textMuted.withValues(alpha: 0.48)
        : KitchenColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: KitchenSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(KitchenRadius.md),
          onTap: isDisabled ? null : () => onChanged(!isSelected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.fromLTRB(
              KitchenSpacing.md,
              KitchenSpacing.sm,
              KitchenSpacing.sm,
              KitchenSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? KitchenColors.cognac.withValues(alpha: 0.1)
                  : KitchenColors.paperLight.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(KitchenRadius.md),
              border: Border.all(
                color: isSelected
                    ? KitchenColors.cognac
                    : KitchenColors.brown700.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    extra.name,
                    style: KitchenTypography.body.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: KitchenSpacing.sm),
                Text(
                  '+${formatPrice(extra.price)}',
                  style: KitchenTypography.label.copyWith(
                    color: isDisabled
                        ? KitchenColors.textMuted.withValues(alpha: 0.48)
                        : KitchenColors.cognac,
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: isDisabled ? null : (value) => onChanged(value!),
                  activeColor: KitchenColors.cognac,
                  checkColor: KitchenColors.whiteWarm,
                  side: BorderSide(
                    color: KitchenColors.brown700.withValues(alpha: 0.38),
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
