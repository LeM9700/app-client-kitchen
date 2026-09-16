import 'package:flutter/material.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/widgets/order_status_presentation.dart';
import 'package:app_client/features/tracking/models/order_status.dart';

class KitchenOrderTimeline extends StatelessWidget {
  const KitchenOrderTimeline({
    super.key,
    required this.currentStatus,
    required this.orderType,
    this.history = const [],
  });

  final OrderStatusCode currentStatus;
  final OrderType orderType;
  final List<OrderStatusHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final statuses = currentStatus == OrderStatusCode.cancelled
        ? const [OrderStatusCode.cancelled]
        : kitchenTimelineStatusesFor(orderType);

    return Semantics(
      label: 'Chronologie de commande',
      child: Column(
        children: [
          for (var i = 0; i < statuses.length; i++)
            _KitchenTimelineStep(
              status: statuses[i],
              orderType: orderType,
              state: timelineStateFor(
                status: statuses[i],
                currentStatus: currentStatus,
                orderType: orderType,
              ),
              createdAt: _createdAtFor(statuses[i]),
              isLast: i == statuses.length - 1,
            ),
        ],
      ),
    );
  }

  DateTime? _createdAtFor(OrderStatusCode status) {
    for (final entry in history) {
      if (entry.status == status) return entry.createdAt;
    }
    return null;
  }
}

class _KitchenTimelineStep extends StatelessWidget {
  const _KitchenTimelineStep({
    required this.status,
    required this.orderType,
    required this.state,
    required this.createdAt,
    required this.isLast,
  });

  final OrderStatusCode status;
  final OrderType orderType;
  final KitchenTimelineState state;
  final DateTime? createdAt;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final presentation =
        OrderStatusPresentation.fromStatus(status, orderType: orderType);
    final active = state == KitchenTimelineState.active;
    final completed = state == KitchenTimelineState.completed;
    final failed = state == KitchenTimelineState.failed;
    final color = failed
        ? KitchenColors.terracotta
        : completed
            ? KitchenColors.olive
            : active
                ? KitchenColors.cognac
                : KitchenColors.textMuted.withValues(alpha: 0.42);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: active ? 38 : 30,
                  height: active ? 38 : 30,
                  decoration: BoxDecoration(
                    color: active || completed || failed
                        ? color
                        : KitchenColors.paperLight,
                    borderRadius: BorderRadius.circular(KitchenRadius.pill),
                    border: Border.all(
                      color: color.withValues(alpha: active ? 0.55 : 0.35),
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color:
                                  KitchenColors.cognac.withValues(alpha: 0.22),
                              blurRadius: 16,
                              offset: const Offset(0, 7),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    presentation.icon,
                    size: active ? 19 : 16,
                    color: active || completed || failed
                        ? KitchenColors.whiteWarm
                        : color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: (completed ? KitchenColors.olive : color)
                          .withValues(alpha: completed ? 0.58 : 0.24),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: KitchenSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: KitchenSpacing.lg),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: KitchenTypography.body.copyWith(
                  color: active || completed || failed
                      ? KitchenColors.textPrimary
                      : KitchenColors.textMuted,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presentation.label,
                      style: KitchenTypography.label.copyWith(
                        color: active || completed || failed
                            ? KitchenColors.espresso
                            : KitchenColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: KitchenSpacing.xxs),
                    Text(
                      presentation.description,
                      style: KitchenTypography.body.copyWith(
                        color: KitchenColors.textMuted,
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: KitchenSpacing.xxs),
                      Text(
                        _formatTime(createdAt!),
                        style: KitchenTypography.label.copyWith(
                          color: color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}
