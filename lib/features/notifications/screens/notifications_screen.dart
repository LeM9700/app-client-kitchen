import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/notifications/models/app_notification.dart';
import 'package:app_client/features/notifications/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: KitchenColors.paper,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(state: state)),
            SliverToBoxAdapter(child: _Actions(state: state)),
            if (state.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: KitchenLoadingIndicator(
                    color: KitchenColors.cognac,
                    size: 36,
                  ),
                ),
              )
            else if (state.notifications.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyNotifications(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  KitchenSpacing.lg,
                  KitchenSpacing.sm,
                  KitchenSpacing.lg,
                  120,
                ),
                sliver: SliverList.separated(
                  itemCount: state.notifications.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: KitchenSpacing.md),
                  itemBuilder: (context, index) => _NotificationTile(
                    notification: state.notifications[index],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final NotificationsState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KitchenSpacing.lg,
        KitchenSpacing.md,
        KitchenSpacing.lg,
        KitchenSpacing.sm,
      ),
      child: Row(
        children: [
          KitchenEmbossedButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.home),
            shape: BoxShape.circle,
            padding: EdgeInsets.zero,
            semanticLabel: 'Retour',
            child: const Icon(Icons.arrow_back_rounded, size: 21),
          ),
          const SizedBox(width: KitchenSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: KitchenTypography.title.copyWith(fontSize: 31),
                ),
                const SizedBox(height: KitchenSpacing.xxs),
                Row(
                  children: [
                    Icon(
                      state.isConnected
                          ? Icons.wifi_tethering_rounded
                          : Icons.wifi_tethering_off_rounded,
                      size: 15,
                      color: state.isConnected
                          ? KitchenColors.olive
                          : KitchenColors.textMuted,
                    ),
                    const SizedBox(width: KitchenSpacing.xs),
                    Expanded(
                      child: Text(
                        state.isConnected
                            ? 'Temps reel actif'
                            : 'Reconnexion en cours',
                        style: KitchenTypography.body.copyWith(
                          color: KitchenColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.state});

  final NotificationsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KitchenSpacing.lg,
        KitchenSpacing.sm,
        KitchenSpacing.lg,
        KitchenSpacing.md,
      ),
      child: KitchenSurface(
        elevation: KitchenElevation.inset,
        padding: const EdgeInsets.all(KitchenSpacing.md),
        borderRadius: BorderRadius.circular(KitchenRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    state.unreadCount == 0
                        ? 'Tout est a jour'
                        : '${state.unreadCount} non lue(s)',
                    style: KitchenTypography.label.copyWith(
                      color: KitchenColors.espresso,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: state.unreadCount == 0
                      ? null
                      : () => ref
                          .read(notificationsProvider.notifier)
                          .markAllRead(),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Tout marquer comme lu'),
                ),
              ],
            ),
            const SizedBox(height: KitchenSpacing.sm),
            KitchenEmbossedButton(
              onPressed: () => ref
                  .read(notificationsProvider.notifier)
                  .requestPushPermission(),
              isLoading: state.isRegisteringPush,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_active_outlined),
                  SizedBox(width: KitchenSpacing.xs),
                  Text('Activer les push navigateur'),
                ],
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: KitchenSpacing.sm),
              Text(
                state.error!,
                style: KitchenTypography.body.copyWith(
                  color: KitchenColors.terracotta,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = _categoryFor(notification.event);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: KitchenRadius.card,
        onTap: () {
          ref.read(notificationsProvider.notifier).markRead(notification.id);
          final orderId = _orderId(notification.data);
          if (orderId != null) {
            context.push('/orders/$orderId/tracking');
          }
        },
        child: KitchenSurface(
          borderRadius: KitchenRadius.card,
          padding: const EdgeInsets.all(KitchenSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: category.color.withValues(alpha: 0.14),
                ),
                child: Icon(category.icon, color: category.color, size: 22),
              ),
              const SizedBox(width: KitchenSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: KitchenTypography.body.copyWith(
                              fontWeight: FontWeight.w900,
                              color: notification.isRead
                                  ? KitchenColors.textMuted
                                  : KitchenColors.espresso,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: KitchenColors.terracotta,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: KitchenSpacing.xxs),
                    Text(
                      notification.body,
                      style: KitchenTypography.body.copyWith(
                        color: KitchenColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: KitchenSpacing.xs),
                    Text(
                      _relativeTime(notification.timestamp),
                      style: KitchenTypography.label.copyWith(
                        color: KitchenColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KitchenSpacing.xs),
              IconButton(
                tooltip: 'Supprimer',
                icon: const Icon(Icons.delete_outline_rounded),
                color: KitchenColors.textMuted,
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).delete(
                          notification.id,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(KitchenSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: KitchenColors.cognac,
            size: 46,
          ),
          const SizedBox(height: KitchenSpacing.md),
          Text(
            'Aucune notification',
            style: KitchenTypography.title.copyWith(fontSize: 30),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KitchenSpacing.xs),
          Text(
            'Les commandes, promos, paiements, livraisons et nouveautes apparaitront ici.',
            style: KitchenTypography.body.copyWith(
              color: KitchenColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotificationCategory {
  const _NotificationCategory({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

_NotificationCategory _categoryFor(String event) {
  final normalized = event.toLowerCase();
  if (normalized.contains('promo')) {
    return const _NotificationCategory(
      icon: Icons.local_offer_outlined,
      color: KitchenColors.terracotta,
    );
  }
  if (normalized.contains('loyal')) {
    return const _NotificationCategory(
      icon: Icons.stars_rounded,
      color: KitchenColors.cognac,
    );
  }
  if (normalized.contains('delivery') || normalized.contains('livraison')) {
    return const _NotificationCategory(
      icon: Icons.delivery_dining_outlined,
      color: KitchenColors.olive,
    );
  }
  if (normalized.contains('payment') || normalized.contains('paiement')) {
    return const _NotificationCategory(
      icon: Icons.credit_card_rounded,
      color: KitchenColors.espresso,
    );
  }
  if (normalized.contains('new') || normalized.contains('catalog')) {
    return const _NotificationCategory(
      icon: Icons.auto_awesome_outlined,
      color: KitchenColors.cognac,
    );
  }
  return const _NotificationCategory(
    icon: Icons.local_pizza_outlined,
    color: KitchenColors.cognac,
  );
}

int? _orderId(Map<String, dynamic> data) {
  final raw = data['order_id'];
  return switch (raw) {
    int value => value,
    String value => int.tryParse(value),
    _ => null,
  };
}

String _relativeTime(DateTime timestamp) {
  final diff = DateTime.now().toUtc().difference(timestamp.toUtc());
  if (diff.inMinutes < 1) return 'A l instant';
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
  return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
}
