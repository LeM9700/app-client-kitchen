import 'package:flutter/material.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/features/orders/models/order.dart';

class KitchenOrderItemRow extends StatelessWidget {
  const KitchenOrderItemRow({super.key, required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final extras = item.extras.map((e) => '+ ${e.name}').join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KitchenSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: KitchenColors.cognac.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${item.quantity}x',
              style: KitchenTypography.label.copyWith(
                color: KitchenColors.cognac,
              ),
            ),
          ),
          const SizedBox(width: KitchenSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'Article #${item.productId}',
                  style: KitchenTypography.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.variantName != null) ...[
                  const SizedBox(height: KitchenSpacing.xxs),
                  Text(
                    item.variantName!,
                    style: KitchenTypography.body.copyWith(
                      color: KitchenColors.textMuted,
                    ),
                  ),
                ],
                if (extras.isNotEmpty) ...[
                  const SizedBox(height: KitchenSpacing.xxs),
                  Text(
                    extras,
                    style: KitchenTypography.body.copyWith(
                      color: KitchenColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: KitchenSpacing.sm),
          Text(
            formatPrice(item.total),
            style: KitchenTypography.label.copyWith(
              color: KitchenColors.espresso,
            ),
          ),
        ],
      ),
    );
  }
}
