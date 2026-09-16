import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_brand_logo.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/orders/models/reorder_result.dart';
import 'package:app_client/features/orders/providers/order_provider.dart';
import 'package:app_client/features/orders/widgets/kitchen_order_card.dart';

/// Historique des commandes, conserve la pagination OFFSET existante.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderHistoryProvider);

    return Scaffold(
      backgroundColor: KitchenColors.paper,
      appBar: AppBar(
        backgroundColor: KitchenColors.paper,
        foregroundColor: KitchenColors.espresso,
        title: Text('Mes commandes', style: KitchenTypography.title),
        actions: [
          IconButton(
            tooltip: 'Rafraichir les commandes',
            color: KitchenColors.cognac,
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
                    dimension: 22,
                    child: KitchenLoadingIndicator(
                      color: KitchenColors.cognac,
                      size: 22,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: KitchenColors.cognac,
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
      return _KitchenErrorState(
        message: state.error!,
        onRetry: () => ref.read(orderHistoryProvider.notifier).refresh(),
      );
    }

    if (state.orders.isEmpty) {
      return const _KitchenEmptyOrders();
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
        padding: const EdgeInsets.all(KitchenSpacing.lg),
        itemCount: state.orders.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: KitchenSpacing.md),
        itemBuilder: (context, index) {
          if (index == state.orders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: KitchenSpacing.lg),
              child: Center(
                child: KitchenLoadingIndicator(color: KitchenColors.cognac),
              ),
            );
          }
          final order = state.orders[index];
          return KitchenOrderCard(
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
              '${outcome.addedCount} article(s) ajoute(s) au panier.',
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

class _OrderHistorySkeleton extends StatelessWidget {
  const _OrderHistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(KitchenSpacing.lg),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: KitchenSpacing.md),
      itemBuilder: (_, __) => KitchenSurface(
        padding: const EdgeInsets.all(KitchenSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 18, width: 150, color: KitchenColors.flour),
            const SizedBox(height: KitchenSpacing.sm),
            Container(height: 12, width: 110, color: KitchenColors.flour),
            const SizedBox(height: KitchenSpacing.md),
            const KitchenLoadingIndicator(color: KitchenColors.cognac),
          ],
        ),
      ),
    );
  }
}

class _KitchenEmptyOrders extends StatelessWidget {
  const _KitchenEmptyOrders();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(KitchenSpacing.lg),
      children: [
        KitchenSurface(
          padding: const EdgeInsets.all(KitchenSpacing.xl),
          child: Column(
            children: [
              const KitchenBrandLogo(size: 90),
              const SizedBox(height: KitchenSpacing.lg),
              Text(
                'Pas encore de commande.',
                style: KitchenTypography.title.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KitchenSpacing.xs),
              Text(
                'Votre premiere pizza vous attend.',
                style: KitchenTypography.body.copyWith(
                  color: KitchenColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KitchenSpacing.lg),
              KitchenEmbossedButton(
                onPressed: () => context.go(AppRoutes.home),
                semanticLabel: 'Decouvrir le menu',
                child: const Text('Decouvrir le menu'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KitchenErrorState extends StatelessWidget {
  const _KitchenErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(KitchenSpacing.lg),
      children: [
        KitchenSurface(
          padding: const EdgeInsets.all(KitchenSpacing.lg),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: KitchenColors.terracotta,
                size: 36,
              ),
              const SizedBox(height: KitchenSpacing.md),
              Text(
                message,
                style: KitchenTypography.body.copyWith(
                  color: KitchenColors.terracotta,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KitchenSpacing.lg),
              KitchenEmbossedButton(
                onPressed: onRetry,
                semanticLabel: 'Reessayer le chargement des commandes',
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
