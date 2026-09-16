import 'package:flutter/material.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_brand_logo.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/widgets/kitchen_status_badge.dart';

class KitchenOrderCard extends StatefulWidget {
  const KitchenOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onTrack,
    required this.onReorder,
  });

  final Order order;
  final VoidCallback onTap;
  final VoidCallback onTrack;
  final VoidCallback onReorder;

  @override
  State<KitchenOrderCard> createState() => _KitchenOrderCardState();
}

class _KitchenOrderCardState extends State<KitchenOrderCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Semantics(
      button: true,
      label: 'Voir le detail de la commande ${order.id}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: _pressed ? 0.985 : 1,
          child: KitchenSurface(
            padding: const EdgeInsets.all(KitchenSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: KitchenColors.cognac.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(KitchenRadius.md),
                      ),
                      child: const Center(child: KitchenBrandLogo(size: 42)),
                    ),
                    const SizedBox(width: KitchenSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Commande #${order.id}',
                            style: KitchenTypography.label.copyWith(
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: KitchenSpacing.xxs),
                          Text(
                            _formatDate(order.createdAt),
                            style: KitchenTypography.body.copyWith(
                              color: KitchenColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: KitchenSpacing.xs),
                          KitchenStatusBadge(
                            status: order.status,
                            orderType: order.orderType,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: KitchenSpacing.sm),
                    Text(
                      formatPrice(order.total),
                      style: KitchenTypography.label.copyWith(
                        color: KitchenColors.cognac,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KitchenSpacing.md),
                Wrap(
                  spacing: KitchenSpacing.xs,
                  runSpacing: KitchenSpacing.xs,
                  alignment: WrapAlignment.end,
                  children: [
                    _CardAction(
                      icon: Icons.receipt_long_outlined,
                      label: 'Detail',
                      onPressed: widget.onTap,
                    ),
                    if (!order.isTerminal)
                      _CardAction(
                        icon: Icons.local_shipping_outlined,
                        label: 'Suivi',
                        onPressed: widget.onTrack,
                      ),
                    _CardAction(
                      icon: Icons.replay,
                      label: 'Recommander',
                      onPressed: widget.onReorder,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: KitchenColors.cognac,
        textStyle: KitchenTypography.label.copyWith(fontSize: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: KitchenSpacing.sm,
          vertical: KitchenSpacing.xs,
        ),
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KitchenRadius.pill),
        ),
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Date indisponible';
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} a '
      '${two(local.hour)}:${two(local.minute)}';
}
