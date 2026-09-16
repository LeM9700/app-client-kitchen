import 'package:flutter/material.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/widgets/order_status_presentation.dart';
import 'package:app_client/features/tracking/models/order_status.dart';

class KitchenStatusBadge extends StatelessWidget {
  const KitchenStatusBadge({
    super.key,
    required this.status,
    this.orderType = OrderType.delivery,
    this.compact = false,
  });

  final OrderStatusCode status;
  final OrderType orderType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final presentation = OrderStatusPresentation.fromStatus(
      status,
      orderType: orderType,
    );
    final isCancelled = status == OrderStatusCode.cancelled;
    final isDelivered = status == OrderStatusCode.delivered;
    final foreground = isCancelled
        ? KitchenColors.terracotta
        : isDelivered
            ? KitchenColors.olive
            : KitchenColors.cognac;

    return Semantics(
      label: 'Statut ${presentation.label}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(KitchenRadius.pill),
          border: Border.all(color: foreground.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(presentation.icon, size: compact ? 14 : 16, color: foreground),
            SizedBox(width: compact ? 5 : 7),
            Flexible(
              child: Text(
                presentation.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KitchenTypography.label.copyWith(
                  color: foreground,
                  fontSize: compact ? 12 : 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
