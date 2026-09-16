import 'package:flutter/material.dart';

import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/tracking/models/order_status.dart';

enum KitchenTimelineState { completed, active, upcoming, failed }

class OrderStatusPresentation {
  const OrderStatusPresentation({
    required this.status,
    required this.label,
    required this.description,
    required this.icon,
  });

  final OrderStatusCode status;
  final String label;
  final String description;
  final IconData icon;

  static OrderStatusPresentation fromStatus(
    OrderStatusCode status, {
    OrderType orderType = OrderType.delivery,
  }) {
    return switch (status) {
      OrderStatusCode.pending => const OrderStatusPresentation(
          status: OrderStatusCode.pending,
          label: 'Commande recue',
          description: 'Nous avons bien recu votre commande.',
          icon: Icons.receipt_long_outlined,
        ),
      OrderStatusCode.confirmed => const OrderStatusPresentation(
          status: OrderStatusCode.confirmed,
          label: 'Commande confirmee',
          description: 'La cuisine prepare votre passage en production.',
          icon: Icons.check_circle_outline,
        ),
      OrderStatusCode.queued => const OrderStatusPresentation(
          status: OrderStatusCode.queued,
          label: 'En file cuisine',
          description: 'Votre commande attend son tour au four.',
          icon: Icons.hourglass_bottom_rounded,
        ),
      OrderStatusCode.preparing => const OrderStatusPresentation(
          status: OrderStatusCode.preparing,
          label: 'En preparation',
          description: 'Les pizzaiolos assemblent votre commande.',
          icon: Icons.local_pizza_outlined,
        ),
      OrderStatusCode.ready => OrderStatusPresentation(
          status: OrderStatusCode.ready,
          label: orderType == OrderType.pickup
              ? 'Prete au retrait'
              : 'Prete a partir',
          description: orderType == OrderType.pickup
              ? 'Votre commande vous attend en boutique.'
              : 'Votre commande attend le depart en livraison.',
          icon: Icons.inventory_2_outlined,
        ),
      OrderStatusCode.outForDelivery => const OrderStatusPresentation(
          status: OrderStatusCode.outForDelivery,
          label: 'En chemin',
          description: 'La commande est partie en livraison.',
          icon: Icons.delivery_dining_outlined,
        ),
      OrderStatusCode.delivered => OrderStatusPresentation(
          status: OrderStatusCode.delivered,
          label: orderType == OrderType.pickup ? 'Retiree' : 'Livree',
          description: orderType == OrderType.pickup
              ? 'La commande a ete remise en boutique.'
              : 'La commande a ete livree.',
          icon: Icons.verified_outlined,
        ),
      OrderStatusCode.cancelled => const OrderStatusPresentation(
          status: OrderStatusCode.cancelled,
          label: 'Annulee',
          description: 'Cette commande a ete annulee.',
          icon: Icons.cancel_outlined,
        ),
    };
  }
}

List<OrderStatusCode> kitchenTimelineStatusesFor(OrderType orderType) {
  if (orderType == OrderType.pickup) {
    return const [
      OrderStatusCode.pending,
      OrderStatusCode.confirmed,
      OrderStatusCode.queued,
      OrderStatusCode.preparing,
      OrderStatusCode.ready,
      OrderStatusCode.delivered,
    ];
  }

  return orderStatusTimelineOrder;
}

KitchenTimelineState timelineStateFor({
  required OrderStatusCode status,
  required OrderStatusCode currentStatus,
  required OrderType orderType,
}) {
  if (currentStatus == OrderStatusCode.cancelled) {
    return status == OrderStatusCode.cancelled
        ? KitchenTimelineState.failed
        : KitchenTimelineState.upcoming;
  }

  final statuses = kitchenTimelineStatusesFor(orderType);
  final currentIndex = statuses.indexOf(currentStatus);
  final statusIndex = statuses.indexOf(status);

  if (currentIndex < 0 || statusIndex < 0) {
    return KitchenTimelineState.upcoming;
  }
  if (statusIndex < currentIndex) return KitchenTimelineState.completed;
  if (statusIndex == currentIndex) return KitchenTimelineState.active;
  return KitchenTimelineState.upcoming;
}
