import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/widgets/kitchen_order_timeline.dart';
import 'package:app_client/features/orders/widgets/kitchen_status_badge.dart';
import 'package:app_client/features/orders/widgets/order_status_presentation.dart';
import 'package:app_client/features/tracking/models/order_status.dart';
import 'package:app_client/features/tracking/providers/tracking_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

/// Suivi temps reel : garde le WebSocket + polling du TrackingNotifier.
class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(trackingProvider(orderId));
    final order = trackingState.order;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: KitchenColors.paper,
      appBar: AppBar(
        backgroundColor: KitchenColors.paper,
        foregroundColor: KitchenColors.espresso,
        title: Text(l10n.trackingOrderTitle(orderId)),
        actions: [
          IconButton(
            tooltip: l10n.trackingRefreshTooltip,
            color: KitchenColors.cognac,
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
      body: Column(
        children: [
          if (!trackingState.isConnected && !trackingState.isTerminal)
            _ConnectionBanner(message: trackingState.error),
          Expanded(
            child: order == null
                ? _LoadingOrError(
                    isLoading: trackingState.isLoadingOrder,
                    onRetry: () => ref.invalidate(trackingProvider(orderId)),
                  )
                : _TrackingBody(order: order),
          ),
          if (trackingState.isTerminal)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(KitchenSpacing.lg),
                child: KitchenEmbossedButton(
                  onPressed: () => context.go(AppRoutes.orders),
                  semanticLabel: 'Voir mes commandes',
                  child: Text(l10n.trackingViewOrdersButton),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrackingBody extends StatelessWidget {
  const _TrackingBody({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final presentation = OrderStatusPresentation.fromStatus(
      order.status,
      orderType: order.orderType,
    );

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
              Text(
                'La bonne pizza prend le bon chemin.',
                style: KitchenTypography.title.copyWith(fontSize: 32),
              ),
              const SizedBox(height: KitchenSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Commande #${order.id}',
                      style: KitchenTypography.body.copyWith(
                        color: KitchenColors.textMuted,
                      ),
                    ),
                  ),
                  KitchenStatusBadge(
                    status: order.status,
                    orderType: order.orderType,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: KitchenSpacing.md),
              _StatusHero(presentation: presentation),
            ],
          ),
        ),
        const SizedBox(height: KitchenSpacing.md),
        KitchenSurface(
          padding: const EdgeInsets.all(KitchenSpacing.lg),
          child: KitchenOrderTimeline(
            currentStatus: order.status,
            orderType: order.orderType,
            history: order.statusHistory,
          ),
        ),
        const SizedBox(height: KitchenSpacing.md),
        _EtaAndAddress(order: order),
        const SizedBox(height: KitchenSpacing.md),
        const _SupportCard(),
      ],
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.presentation});

  final OrderStatusPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final isCancelled = presentation.status == OrderStatusCode.cancelled;
    final color = isCancelled ? KitchenColors.terracotta : KitchenColors.cognac;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(KitchenSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(presentation.icon, color: color, size: 30),
          const SizedBox(width: KitchenSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presentation.label,
                  style: KitchenTypography.label.copyWith(
                    color: color,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: KitchenSpacing.xxs),
                Text(
                  presentation.description,
                  style: KitchenTypography.body.copyWith(
                    color: KitchenColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EtaAndAddress extends StatelessWidget {
  const _EtaAndAddress({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final eta = order.estimatedDeliveryAt;

    return KitchenSurface(
      elevation: KitchenElevation.inset,
      padding: const EdgeInsets.all(KitchenSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations',
            style: KitchenTypography.title.copyWith(fontSize: 26),
          ),
          const SizedBox(height: KitchenSpacing.md),
          _InfoLine(
            icon: Icons.schedule_outlined,
            title: 'Temps estime',
            value: eta != null
                ? _formatDateTime(eta)
                : order.status == OrderStatusCode.cancelled
                    ? 'Commande annulee'
                    : 'Votre commande est en cours de preparation.',
          ),
          const SizedBox(height: KitchenSpacing.sm),
          _InfoLine(
            icon: order.orderType == OrderType.pickup
                ? Icons.storefront_outlined
                : Icons.location_on_outlined,
            title: order.orderType == OrderType.pickup ? 'Retrait' : 'Adresse',
            value: order.orderType == OrderType.pickup
                ? 'Retrait en boutique'
                : (order.deliveryAddress?.isNotEmpty == true
                    ? order.deliveryAddress!
                    : 'Adresse non disponible'),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: KitchenColors.cognac, size: 21),
        const SizedBox(width: KitchenSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: KitchenTypography.label),
              const SizedBox(height: KitchenSpacing.xxs),
              Text(
                value,
                style: KitchenTypography.body.copyWith(
                  color: KitchenColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return KitchenSurface(
      padding: const EdgeInsets.all(KitchenSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.support_agent_outlined, color: KitchenColors.cognac),
          const SizedBox(width: KitchenSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Besoin d\'aide ?', style: KitchenTypography.label),
                const SizedBox(height: KitchenSpacing.xxs),
                Text(
                  'Contactez le restaurant si une information vous semble incoherente.',
                  style: KitchenTypography.body.copyWith(
                    color: KitchenColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(
        vertical: KitchenSpacing.xs,
        horizontal: KitchenSpacing.md,
      ),
      color: KitchenColors.cognac.withValues(alpha: 0.12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const KitchenLoadingIndicator(color: KitchenColors.cognac, size: 24),
          const SizedBox(width: KitchenSpacing.sm),
          Flexible(
            child: Text(
              message ??
                  AppLocalizations.of(context)!.trackingConnectingMessage,
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.cognac,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingOrError extends StatelessWidget {
  const _LoadingOrError({required this.isLoading, required this.onRetry});

  final bool isLoading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: KitchenLoadingIndicator(color: KitchenColors.cognac),
      );
    }

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
                AppLocalizations.of(context)!.trackingLoadErrorMessage,
                style: KitchenTypography.body.copyWith(
                  color: KitchenColors.terracotta,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KitchenSpacing.lg),
              KitchenEmbossedButton(
                onPressed: onRetry,
                semanticLabel: 'Reessayer le suivi de commande',
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} a '
      '${two(local.hour)}:${two(local.minute)}';
}
