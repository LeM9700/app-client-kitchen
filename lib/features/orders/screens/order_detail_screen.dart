import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/models/reorder_result.dart';
import 'package:app_client/features/orders/providers/order_provider.dart';
import 'package:app_client/features/orders/widgets/kitchen_order_item_row.dart';
import 'package:app_client/features/orders/widgets/kitchen_order_timeline.dart';
import 'package:app_client/features/orders/widgets/kitchen_status_badge.dart';
import 'package:app_client/features/tracking/models/order_status.dart';

/// Ecran recu : `GET /orders/{id}` reste la source de verite.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: KitchenColors.paper,
      appBar: AppBar(
        backgroundColor: KitchenColors.paper,
        foregroundColor: KitchenColors.espresso,
        title: Text('Commande #$orderId', style: KitchenTypography.title),
      ),
      body: orderAsync.when(
        loading: () => const Center(
          child: KitchenLoadingIndicator(color: KitchenColors.cognac),
        ),
        error: (e, _) => _KitchenDetailError(
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KitchenSpacing.lg,
        KitchenSpacing.md,
        KitchenSpacing.lg,
        KitchenSpacing.xl,
      ),
      children: [
        KitchenSurface(
          padding: const EdgeInsets.all(KitchenSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commande #${order.id}',
                          style: KitchenTypography.title.copyWith(fontSize: 32),
                        ),
                        const SizedBox(height: KitchenSpacing.xs),
                        Text(
                          _formatDateTime(order.createdAt),
                          style: KitchenTypography.body.copyWith(
                            color: KitchenColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  KitchenStatusBadge(
                    status: order.status,
                    orderType: order.orderType,
                    compact: true,
                  ),
                ],
              ),
              if (order.estimatedDeliveryAt != null) ...[
                const SizedBox(height: KitchenSpacing.md),
                _InfoLine(
                  icon: Icons.schedule_outlined,
                  text:
                      'Estimee : ${_formatDateTime(order.estimatedDeliveryAt)}',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: KitchenSpacing.md),
        _Section(
          title: 'Votre commande',
          child: order.items.isEmpty
              ? Text(
                  'Detail des articles indisponible.',
                  style: KitchenTypography.body.copyWith(
                    color: KitchenColors.textMuted,
                  ),
                )
              : Column(
                  children: [
                    for (final item in order.items)
                      KitchenOrderItemRow(item: item),
                  ],
                ),
        ),
        const SizedBox(height: KitchenSpacing.md),
        _Section(
          title: order.orderType == OrderType.pickup ? 'Retrait' : 'Livraison',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoLine(
                icon: order.orderType == OrderType.pickup
                    ? Icons.storefront_outlined
                    : Icons.delivery_dining_outlined,
                text: order.orderType == OrderType.pickup
                    ? 'Retrait en boutique'
                    : (order.deliveryAddress?.isNotEmpty == true
                        ? order.deliveryAddress!
                        : 'Adresse de livraison non disponible'),
              ),
              if (order.deliveryZoneId != null)
                _InfoLine(
                  icon: Icons.map_outlined,
                  text: 'Zone #${order.deliveryZoneId}',
                ),
            ],
          ),
        ),
        const SizedBox(height: KitchenSpacing.md),
        _Section(
          title: 'Paiement',
          child: _InfoLine(
            icon: Icons.payments_outlined,
            text: 'Statut : ${order.paymentStatus}',
          ),
        ),
        const SizedBox(height: KitchenSpacing.md),
        _Section(
          title: 'Totaux',
          child: Column(
            children: [
              _TotalRow(label: 'Sous-total', value: order.subtotal),
              if (order.discountTotal > 0)
                _TotalRow(
                  label: order.promoCode != null
                      ? 'Remise (${order.promoCode})'
                      : 'Remise',
                  value: -order.discountTotal,
                ),
              if (order.deliveryFee > 0)
                _TotalRow(label: 'Livraison', value: order.deliveryFee),
              Divider(color: KitchenColors.brown700.withValues(alpha: 0.16)),
              _TotalRow(label: 'Total', value: order.total, emphasize: true),
            ],
          ),
        ),
        if (order.statusHistory.isNotEmpty) ...[
          const SizedBox(height: KitchenSpacing.md),
          _Section(
            title: 'Historique',
            child: KitchenOrderTimeline(
              currentStatus: order.status,
              orderType: order.orderType,
              history: order.statusHistory,
            ),
          ),
        ],
        const SizedBox(height: KitchenSpacing.lg),
        _Actions(order: order),
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = <Widget>[];
    if (!order.isTerminal) {
      actions.add(
        KitchenEmbossedButton(
          onPressed: () =>
              context.push('${AppRoutes.orders}/${order.id}/tracking'),
          semanticLabel: 'Suivre la commande ${order.id}',
          child: const Text('Suivre ma commande'),
        ),
      );
    }
    if (order.status == OrderStatusCode.delivered) {
      actions.add(
        Padding(
          padding:
              EdgeInsets.only(top: actions.isEmpty ? 0 : KitchenSpacing.sm),
          child: KitchenEmbossedButton(
            onPressed: () => _handleReorder(context, ref, order.id),
            semanticLabel: 'Commander a nouveau la commande ${order.id}',
            child: const Text('Commander a nouveau'),
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return Text(
        order.status == OrderStatusCode.cancelled
            ? 'Aucune action disponible pour une commande annulee.'
            : 'Commande terminee.',
        style: KitchenTypography.body.copyWith(color: KitchenColors.textMuted),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: actions,
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
          builder: (_) => _UnavailableItemsDialog(
            items: outcome.unavailableItems,
          ),
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KitchenSurface(
      padding: const EdgeInsets.all(KitchenSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KitchenTypography.title.copyWith(fontSize: 26)),
          const SizedBox(height: KitchenSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KitchenSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: KitchenColors.cognac, size: 20),
          const SizedBox(width: KitchenSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.textMuted,
              ),
            ),
          ),
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
    final style =
        (emphasize ? KitchenTypography.label : KitchenTypography.body).copyWith(
      color: emphasize ? KitchenColors.cognac : KitchenColors.textMuted,
      fontSize: emphasize ? 17 : 15,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KitchenSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(formatPrice(value), style: style),
        ],
      ),
    );
  }
}

class _KitchenDetailError extends StatelessWidget {
  const _KitchenDetailError({required this.message, required this.onRetry});

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
                semanticLabel: 'Reessayer le chargement de la commande',
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

String _formatDateTime(DateTime? date) {
  if (date == null) return 'Date indisponible';
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} a '
      '${two(local.hour)}:${two(local.minute)}';
}
