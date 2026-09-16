import 'package:flutter/material.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/features/cart/models/cart_item.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';

class KitchenOrderSummary extends StatelessWidget {
  const KitchenOrderSummary({
    super.key,
    required this.items,
    required this.deliveryMode,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.discountTotal = 0,
    this.address,
    this.estimatedMinutes,
    this.zoneName,
  });

  final List<CartItem> items;
  final DeliveryMode deliveryMode;
  final double subtotal;
  final double deliveryFee;
  final double discountTotal;
  final double total;
  final String? address;
  final int? estimatedMinutes;
  final String? zoneName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Votre commande',
          style: KitchenTypography.title.copyWith(fontSize: 28),
        ),
        const SizedBox(height: KitchenSpacing.sm),
        if (items.isEmpty)
          Text(
            'Aucun article dans le panier.',
            style:
                KitchenTypography.body.copyWith(color: KitchenColors.textMuted),
          )
        else
          for (final item in items) _CartSummaryRow(item: item),
        const SizedBox(height: KitchenSpacing.md),
        Divider(color: KitchenColors.brown700.withValues(alpha: 0.16)),
        const SizedBox(height: KitchenSpacing.sm),
        _SummaryLine(label: 'Sous-total', value: subtotal),
        if (deliveryFee > 0)
          _SummaryLine(label: 'Livraison', value: deliveryFee),
        if (discountTotal > 0)
          _SummaryLine(label: 'Reduction', value: -discountTotal),
        const SizedBox(height: KitchenSpacing.sm),
        _SummaryLine(label: 'Total estime', value: total, emphasize: true),
        const SizedBox(height: KitchenSpacing.md),
        _FulfillmentLine(
          deliveryMode: deliveryMode,
          address: address,
          estimatedMinutes: estimatedMinutes,
          zoneName: zoneName,
        ),
      ],
    );
  }
}

class _CartSummaryRow extends StatelessWidget {
  const _CartSummaryRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final selectedExtras = item.product.extras.where(
      (extra) => item.selectedExtraIds.contains(extra.id),
    );
    final details = <String>[
      if (item.selectedVariant != null) item.selectedVariant!.name,
      for (final extra in selectedExtras) '+ ${extra.name}',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KitchenSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.product.name} x ${item.quantity}',
                  style: KitchenTypography.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (details.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: KitchenSpacing.xxs),
                    child: Text(
                      details.join(', '),
                      style: KitchenTypography.body.copyWith(
                        color: KitchenColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: KitchenSpacing.sm),
          Text(
            formatPrice(item.totalPrice),
            style:
                KitchenTypography.label.copyWith(color: KitchenColors.espresso),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final double value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KitchenSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                (emphasize ? KitchenTypography.label : KitchenTypography.body)
                    .copyWith(
              color:
                  emphasize ? KitchenColors.espresso : KitchenColors.textMuted,
              fontSize: emphasize ? 16 : 15,
            ),
          ),
          Text(
            formatPrice(value),
            style:
                (emphasize ? KitchenTypography.label : KitchenTypography.body)
                    .copyWith(
              color: emphasize ? KitchenColors.cognac : KitchenColors.espresso,
              fontSize: emphasize ? 18 : 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _FulfillmentLine extends StatelessWidget {
  const _FulfillmentLine({
    required this.deliveryMode,
    this.address,
    this.estimatedMinutes,
    this.zoneName,
  });

  final DeliveryMode deliveryMode;
  final String? address;
  final int? estimatedMinutes;
  final String? zoneName;

  @override
  Widget build(BuildContext context) {
    final isDelivery = deliveryMode == DeliveryMode.delivery;
    final text = isDelivery
        ? [
            if (address != null && address!.isNotEmpty) address!,
            if (zoneName != null) 'Zone $zoneName',
            if (estimatedMinutes != null) 'Estimation $estimatedMinutes min',
          ].join(' - ')
        : 'Retrait en boutique';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isDelivery
              ? Icons.delivery_dining_outlined
              : Icons.storefront_outlined,
          color: KitchenColors.cognac,
          size: 20,
        ),
        const SizedBox(width: KitchenSpacing.xs),
        Expanded(
          child: Text(
            text.isEmpty ? 'Livraison' : text,
            style: KitchenTypography.body.copyWith(
              color: KitchenColors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
