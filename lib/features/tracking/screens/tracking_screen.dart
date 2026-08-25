import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/widgets/error_view.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/tracking/models/order_status.dart';
import 'package:app_client/features/tracking/providers/tracking_provider.dart';

/// Écran de suivi de commande en temps réel — connexion WebSocket
/// (`TrackingNotifier`) + polling de secours, timeline des 8 statuts réels
/// (voir `order_status.dart`), état `cancelled` affiché à part (atteignable
/// depuis n'importe quelle étape, pas de position fixe dans la timeline).
class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(trackingProvider(orderId));
    final order = trackingState.order;

    return Scaffold(
      appBar: AppBar(
        title: Text('Commande #$orderId'),
        actions: [
          IconButton(
            tooltip: 'Rafraichir le statut',
            onPressed: trackingState.isLoadingOrder
                ? null
                : () async {
                    await ref
                        .read(trackingProvider(orderId).notifier)
                        .refreshNow();
                    final latest = ref.read(trackingProvider(orderId));
                    if (!context.mounted || latest.error == null) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(latest.error!)),
                    );
                  },
            icon: trackingState.isLoadingOrder
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!trackingState.isConnected)
            _ConnectionBanner(message: trackingState.error),
          if (order != null && order.status != OrderStatusCode.cancelled)
            _OrderConfirmationHeader(order: order),
          Expanded(
            child: order == null
                ? (trackingState.isLoadingOrder
                    ? const Center(child: CircularProgressIndicator())
                    : ErrorView(
                        message: 'Impossible de charger la commande.',
                        onRetry: () =>
                            ref.invalidate(trackingProvider(orderId)),
                      ))
                : order.status == OrderStatusCode.cancelled
                    ? const _CancelledView()
                    : _StatusTimeline(currentStatus: order.status),
          ),
          if (trackingState.isTerminal)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.orders),
                  child: const Text('Voir mes commandes'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderConfirmationHeader extends StatelessWidget {
  const _OrderConfirmationHeader({required this.order});
  final Order order;

  bool get _isPaid {
    const paidStatuses = {'paid', 'succeeded', 'confirmed'};
    return paidStatuses.contains(order.paymentStatus.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isPaid
                  ? Icons.check_circle_outline
                  : Icons.receipt_long_outlined,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isPaid ? 'Paiement confirmé' : order.status.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Suivi de la commande #${order.id} en temps réel.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: const Color(0xFFFFF9C4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message ?? 'Connexion en cours...',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledView extends StatelessWidget {
  const _CancelledView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              OrderStatusCode.cancelled.icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              OrderStatusCode.cancelled.label,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Cette commande a été annulée.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Timeline construite depuis [orderStatusTimelineOrder] — [queued] a une
/// place fixe dedans, donc un statut `queued` s'affiche normalement plutôt
/// que de faire planter ou masquer l'étape.
class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.currentStatus});
  final OrderStatusCode currentStatus;

  @override
  Widget build(BuildContext context) {
    final currentIndex = orderStatusTimelineOrder.indexOf(currentStatus);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orderStatusTimelineOrder.length,
      itemBuilder: (_, i) {
        final status = orderStatusTimelineOrder[i];
        final isDone = currentIndex >= 0 && i < currentIndex;
        final isActive = i == currentIndex;
        final isLast = i == orderStatusTimelineOrder.length - 1;

        return _StatusStep(
          status: status,
          isDone: isDone,
          isActive: isActive,
          isLast: isLast,
        );
      },
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.status,
    required this.isDone,
    required this.isActive,
    required this.isLast,
  });

  final OrderStatusCode status;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighlighted = isDone || isActive;
    final color =
        isHighlighted ? theme.colorScheme.primary : const Color(0xFF9E9E9E);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        isHighlighted ? color : color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child:
                        Text(status.icon, style: const TextStyle(fontSize: 16)),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDone ? color : const Color(0xFFE5E5E5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 4),
              child: Text(
                status.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isHighlighted ? null : const Color(0xFF9E9E9E),
                  fontWeight: isActive ? FontWeight.bold : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
