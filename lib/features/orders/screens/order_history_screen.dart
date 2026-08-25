import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/widgets/empty_state.dart';
import 'package:app_client/core/widgets/error_view.dart';
import 'package:app_client/core/widgets/shimmer_skeleton.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/models/reorder_result.dart';
import 'package:app_client/features/orders/providers/order_provider.dart';
import 'package:app_client/features/tracking/models/order_status.dart';

String _formatPrice(double price) => '${price.toStringAsFixed(2)} €';

String _formatDate(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} à '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Historique des commandes — liste paginée par OFFSET (`page`/`page_size`,
/// PAS un curseur, voir api-corrections-phase-d.md §5). Chaque commande
/// affiche date/statut/total ; le "résumé articles" du DoD d'origine n'est
/// PAS affichable ici : `OrderListOut` (réponse `GET /orders/me`) ne contient
/// pas `items` (uniquement `GET /orders/{id}` les expose) — afficher un
/// résumé exigerait un fetch détail par ligne (N+1), hors de propos pour une
/// liste paginée. Le résumé complet des articles vit sur l'écran détail.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes commandes'),
        actions: [
          IconButton(
            tooltip: 'Rafraichir les commandes',
            onPressed: state.isLoading
                ? null
                : () async {
                    await ref.read(orderHistoryProvider.notifier).refresh();
                    final latest = ref.read(orderHistoryProvider);
                    if (!context.mounted ||
                        latest.error == null ||
                        latest.orders.isEmpty) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(latest.error!)),
                    );
                  },
            icon: state.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(orderHistoryProvider.notifier).refresh(),
        child: _Body(state: state),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});
  final OrderHistoryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.orders.isEmpty) {
      return const _OrderHistorySkeleton();
    }

    if (state.error != null && state.orders.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () => ref.read(orderHistoryProvider.notifier).refresh(),
      );
    }

    if (state.orders.isEmpty) {
      return const EmptyState(
        title: 'Aucune commande pour le moment',
        subtitle: 'Vos commandes passées apparaîtront ici.',
        icon: Icons.receipt_long_outlined,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (metrics.pixels >= metrics.maxScrollExtent - 200 &&
            state.hasMore &&
            !state.isLoadingMore) {
          ref.read(orderHistoryProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.orders.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == state.orders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final order = state.orders[index];
          return _OrderTile(
            order: order,
            onTap: () => context.push('${AppRoutes.orders}/${order.id}'),
            onTrack: () =>
                context.push('${AppRoutes.orders}/${order.id}/tracking'),
            onReorder: () => _handleReorder(context, ref, order.id),
          );
        },
      ),
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
          builder: (_) =>
              _UnavailableItemsDialog(items: outcome.unavailableItems),
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

// ─────────────────────────────────────────────────────────────────────────
// Skeleton de chargement
// ─────────────────────────────────────────────────────────────────────────

class _OrderHistorySkeleton extends StatelessWidget {
  const _OrderHistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShimmerBlock(height: 18, width: 140),
              SizedBox(height: 12),
              ShimmerBlock(height: 12, width: 100),
              SizedBox(height: 8),
              ShimmerBlock(height: 12, width: 90),
              SizedBox(height: 16),
              ShimmerBlock(height: 20, width: 70),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Ligne commande
// ─────────────────────────────────────────────────────────────────────────

class _OrderTile extends StatelessWidget {
  const _OrderTile({
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Commande #${order.id}',
                    style: theme.textTheme.titleMedium,
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(order.createdAt),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                order.orderType == OrderType.pickup
                    ? 'Retrait en boutique'
                    : 'Livraison',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatPrice(order.total),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      if (!order.isTerminal)
                        TextButton.icon(
                          onPressed: onTrack,
                          icon: const Icon(
                            Icons.local_shipping_outlined,
                            size: 18,
                          ),
                          label: const Text('Suivi'),
                        ),
                      TextButton.icon(
                        onPressed: onReorder,
                        icon: const Icon(Icons.replay, size: 18),
                        label: const Text('Recommander'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
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

// ─────────────────────────────────────────────────────────────────────────
// Dialogue articles indisponibles (reorder)
// ─────────────────────────────────────────────────────────────────────────

/// [🔒 api-corrections-phase-d.md §5] Les articles indisponibles ne sont
/// JAMAIS silencieusement ignorés — toujours listés à l'utilisateur avant/
/// pendant l'ajout des articles disponibles au panier.
class _UnavailableItemsDialog extends StatelessWidget {
  const _UnavailableItemsDialog({required this.items});
  final List<ReorderItem> items;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Certains articles ne sont plus disponibles'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: items
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
    );
  }
}
