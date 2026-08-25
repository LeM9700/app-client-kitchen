import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/widgets/error_view.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/providers/order_provider.dart';
import 'package:app_client/features/tracking/models/order_status.dart';

String _formatPrice(double price) => '${price.toStringAsFixed(2)} €';

String _formatDateTime(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} à '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Écran "reçu" — `GET /orders/{id}` (`OrderDetailOut`). Aucun endpoint
/// `/orders/{id}/receipt` accessible côté client (staff/admin uniquement) —
/// voir api-corrections-phase-d.md §5 : ce détail EST le reçu, pas de
/// génération PDF (décision d'architecture n°3 du plan d'origine, toujours
/// valide).
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text('Commande #$orderId')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e is AppException ? e.message : 'Erreur inattendue.',
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (order) => _OrderDetailBody(order: order),
      ),
    );
  }
}

class _OrderDetailBody extends ConsumerWidget {
  const _OrderDetailBody({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── En-tête ────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDateTime(order.createdAt),
              style: theme.textTheme.bodyMedium,
            ),
            _StatusChip(status: order.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          order.orderType == OrderType.pickup
              ? 'Retrait en boutique'
              : 'Livraison${order.deliveryAddress != null ? ' — ${order.deliveryAddress}' : ''}',
          style: theme.textTheme.bodyMedium,
        ),
        if (order.estimatedDeliveryAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Estimée : ${_formatDateTime(order.estimatedDeliveryAt)}',
            style: theme.textTheme.bodySmall,
          ),
        ],

        if (!order.isTerminal) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                context.push('${AppRoutes.orders}/${order.id}/tracking'),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Suivre la commande'),
          ),
        ],

        const SizedBox(height: 24),

        // ── Articles ───────────────────────────────────────────────────
        Text('Articles', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (order.items.isEmpty)
          const Text('Détail des articles indisponible.')
        else
          ...order.items.map((item) => _OrderItemTile(item: item)),

        const Divider(height: 32),

        // ── Totaux ─────────────────────────────────────────────────────
        _TotalRow(label: 'Sous-total', value: order.subtotal),
        if (order.discountTotal > 0)
          _TotalRow(
            label: order.promoCode != null
                ? 'Remise (${order.promoCode})'
                : 'Remise',
            value: -order.discountTotal,
          ),
        if (order.deliveryFee > 0)
          _TotalRow(label: 'Frais de livraison', value: order.deliveryFee),
        const Divider(),
        _TotalRow(label: 'Total', value: order.total, emphasize: true),

        // ── Historique de statut ──────────────────────────────────────
        if (order.statusHistory.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Historique', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...order.statusHistory
              .map((entry) => _StatusHistoryTile(entry: entry)),
        ],

        const SizedBox(height: 24),

        // ── Recommander ────────────────────────────────────────────────
        ElevatedButton.icon(
          onPressed: () => _handleReorder(context, ref, order.id),
          icon: const Icon(Icons.replay),
          label: const Text('Recommander'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _handleReorder(
    BuildContext context,
    WidgetRef ref,
    int orderId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final outcome = await ref.read(reorderProvider).reorder(orderId);
      if (!context.mounted) return;

      if (outcome.unavailableItems.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Certains articles ne sont plus disponibles'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: outcome.unavailableItems
                    .map(
                      (item) => ListTile(
                        leading: const Icon(Icons.warning_amber_rounded),
                        title: Text('Article #${item.productId}'),
                        subtitle: Text(
                          item.warning ?? 'Cet article n\'est plus disponible.',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      if (!context.mounted) return;

      if (outcome.addedCount > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${outcome.addedCount} article(s) ajouté(s) au panier.',
            ),
          ),
        );
        context.push(AppRoutes.cart);
      } else if (outcome.unavailableItems.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Aucun article disponible pour cette commande.'),
          ),
        );
      }
    } on AppException catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final OrderStatusCode status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status.icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(status.label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${item.quantity}×', style: theme.textTheme.bodyMedium),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'Article #${item.productId}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (item.variantName != null)
                  Text(item.variantName!, style: theme.textTheme.bodySmall),
                if (item.extras.isNotEmpty)
                  Text(
                    item.extras.map((e) => e.name).join(', '),
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Text(_formatPrice(item.total), style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final double value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(_formatPrice(value), style: style),
        ],
      ),
    );
  }
}

class _StatusHistoryTile extends StatelessWidget {
  const _StatusHistoryTile({required this.entry});
  final OrderStatusHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.status.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.status.label, style: theme.textTheme.bodyMedium),
                if (entry.note != null)
                  Text(entry.note!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            _formatDateTime(entry.createdAt),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
