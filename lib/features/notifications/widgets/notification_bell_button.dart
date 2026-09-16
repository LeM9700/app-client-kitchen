import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/features/notifications/providers/notifications_provider.dart';

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(accessTokenProvider) != null;
    final unreadCount =
        isAuthenticated ? ref.watch(unreadNotificationsProvider) : 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        KitchenEmbossedButton(
          onPressed: () {
            if (!isAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connectez-vous')),
              );
              context.push(
                '${AppRoutes.login}?redirect=${Uri.encodeComponent(AppRoutes.notifications)}',
              );
              return;
            }
            context.push(AppRoutes.notifications);
          },
          shape: BoxShape.circle,
          padding: EdgeInsets.zero,
          semanticLabel: 'Notifications',
          child: const Icon(Icons.notifications_none_rounded, size: 22),
        ),
        if (unreadCount > 0)
          Positioned(
            right: -2,
            top: -3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: const BoxDecoration(
                color: KitchenColors.terracotta,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: KitchenTypography.label.copyWith(
                  color: KitchenColors.whiteWarm,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
