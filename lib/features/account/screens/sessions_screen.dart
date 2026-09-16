import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/account/models/session.dart';
import 'package:app_client/features/account/providers/account_provider.dart';

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} à '
      '${two(local.hour)}:${two(local.minute)}';
}

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  final Set<int> _revokingIds = {};

  Future<void> _revoke(Session session) async {
    setState(() => _revokingIds.add(session.id));
    try {
      await ref.read(sessionActionsProvider).revoke(session.id);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _revokingIds.remove(session.id));
    }
  }

  Future<void> _confirmRevoke(Session session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Révoquer cette session ?'),
        content: const Text('Cet appareil sera déconnecté immédiatement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _revoke(session);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      backgroundColor: KitchenColors.paperLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(sessionsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Retour',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: KitchenColors.espresso,
                  ),
                  const SizedBox(width: KitchenSpacing.xs),
                  Expanded(
                    child: Text(
                      'Sessions actives',
                      style: KitchenTypography.title.copyWith(fontSize: 31),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KitchenSpacing.lg),
              sessionsAsync.when(
                loading: () => const _SessionsSkeleton(),
                error: (e, _) => _InlineState(
                  icon: Icons.error_outline,
                  title: 'Impossible de charger les sessions.',
                  subtitle: e is AppException ? e.message : null,
                  actionLabel: 'Réessayer',
                  onAction: () => ref.invalidate(sessionsProvider),
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return const _InlineState(
                      icon: Icons.devices_other_outlined,
                      title: 'Aucune session active.',
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < sessions.length; i += 1) ...[
                        _SessionCard(
                          session: sessions[i],
                          isRevoking: _revokingIds.contains(sessions[i].id),
                          onRevoke: sessions[i].isCurrent
                              ? null
                              : () => _confirmRevoke(sessions[i]),
                        ),
                        if (i < sessions.length - 1)
                          const SizedBox(height: KitchenSpacing.sm),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.isRevoking,
    required this.onRevoke,
  });

  final Session session;
  final bool isRevoking;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final title = session.userAgent?.trim().isNotEmpty == true
        ? session.userAgent!.trim()
        : 'Appareil inconnu';

    return KitchenSurface(
      padding: const EdgeInsets.all(KitchenSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KitchenColors.paperLight.withValues(alpha: 0.76),
            ),
            child: Icon(
              session.isMobileDevice
                  ? Icons.phone_android_outlined
                  : Icons.computer_outlined,
              color: KitchenColors.espresso,
            ),
          ),
          const SizedBox(width: KitchenSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: KitchenTypography.label.copyWith(fontSize: 14),
                      ),
                    ),
                    if (session.isCurrent) const _CurrentChip(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${session.ipAddress ?? 'IP inconnue'} · '
                  'créée le ${_formatDateTime(session.createdAt)}',
                  style: KitchenTypography.body.copyWith(
                    color: KitchenColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!session.isCurrent) ...[
            const SizedBox(width: KitchenSpacing.xs),
            isRevoking
                ? const KitchenLoadingIndicator(
                    size: 26,
                    color: KitchenColors.terracotta,
                  )
                : IconButton(
                    tooltip: 'Révoquer cette session',
                    onPressed: onRevoke,
                    icon: const Icon(Icons.logout_rounded),
                    color: KitchenColors.terracotta,
                  ),
          ],
        ],
      ),
    );
  }
}

class _CurrentChip extends StatelessWidget {
  const _CurrentChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: KitchenColors.olive.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(KitchenRadius.pill),
      ),
      child: Text(
        'Actuelle',
        style: KitchenTypography.label.copyWith(
          color: KitchenColors.olive,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _InlineState extends StatelessWidget {
  const _InlineState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return KitchenSurface(
      padding: const EdgeInsets.all(KitchenSpacing.lg),
      child: Column(
        children: [
          Icon(icon, color: KitchenColors.cognac, size: 34),
          const SizedBox(height: KitchenSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: KitchenTypography.label,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: KitchenSpacing.xs),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: KitchenSpacing.sm),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _SessionsSkeleton extends StatelessWidget {
  const _SessionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        KitchenSurface(
          padding: EdgeInsets.all(KitchenSpacing.lg),
          child: Center(child: KitchenLoadingIndicator()),
        ),
      ],
    );
  }
}
