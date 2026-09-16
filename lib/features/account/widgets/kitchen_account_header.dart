import 'package:flutter/material.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_shadows.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/core/widgets/shimmer_skeleton.dart';
import 'package:app_client/features/auth/models/user.dart';

class KitchenAccountHeader extends StatelessWidget {
  const KitchenAccountHeader({
    super.key,
    required this.user,
    this.onEdit,
  });

  final User? user;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    if (currentUser == null) {
      return const KitchenSurface(
        padding: EdgeInsets.all(KitchenSpacing.lg),
        child: _HeaderSkeleton(),
      );
    }

    final displayName = _displayName(currentUser);
    final secondary = currentUser.email;
    final phone = currentUser.phone?.trim();

    return KitchenSurface(
      padding: const EdgeInsets.all(KitchenSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Avatar(initials: _initials(currentUser)),
          const SizedBox(height: KitchenSpacing.md),
          Text(
            displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: KitchenTypography.title.copyWith(fontSize: 32),
          ),
          const SizedBox(height: KitchenSpacing.xs),
          Text(
            secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: KitchenTypography.body.copyWith(
              color: KitchenColors.textMuted,
              fontSize: 13,
            ),
          ),
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: KitchenSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: KitchenSpacing.sm,
            runSpacing: KitchenSpacing.xs,
            children: [
              _StatusPill(
                icon: currentUser.emailVerified
                    ? Icons.verified_outlined
                    : Icons.mark_email_unread_outlined,
                label: currentUser.emailVerified
                    ? 'Email vérifié'
                    : 'Email non vérifié',
                color: currentUser.emailVerified
                    ? KitchenColors.olive
                    : KitchenColors.terracotta,
              ),
              if (onEdit != null)
                _EditPill(
                  onTap: onEdit!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _displayName(User user) {
    final name = user.fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return user.email;
  }

  String _initials(User user) {
    final name = user.fullName?.trim();
    if (name != null && name.isNotEmpty) {
      final parts = name
          .split(RegExp(r'\s+'))
          .where((part) => part.trim().isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        return '${parts.first.characters.first}${parts.last.characters.first}'
            .toUpperCase();
      }
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    if (user.email.isNotEmpty) {
      return user.email.characters.first.toUpperCase();
    }
    return 'K';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: KitchenGradients.cognac,
        border: Border.all(
          color: KitchenColors.whiteWarm.withValues(alpha: 0.42),
          width: 1.4,
        ),
        boxShadow: KitchenShadows.raised,
      ),
      child: Text(
        initials,
        maxLines: 1,
        style: KitchenTypography.title.copyWith(
          color: KitchenColors.whiteWarm,
          fontSize: 30,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(KitchenRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: KitchenTypography.label.copyWith(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditPill extends StatelessWidget {
  const _EditPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Modifier mes informations',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KitchenRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: KitchenColors.paperLight.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(KitchenRadius.pill),
            border: Border.all(
              color: KitchenColors.brown700.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.edit_outlined,
                size: 15,
                color: KitchenColors.cognac,
              ),
              const SizedBox(width: 6),
              Text(
                'Modifier',
                style: KitchenTypography.label.copyWith(
                  color: KitchenColors.cognac,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ShimmerBlock(height: 84, width: 84, borderRadius: 42),
        SizedBox(height: KitchenSpacing.md),
        ShimmerBlock(height: 24, width: 170),
        SizedBox(height: KitchenSpacing.sm),
        ShimmerBlock(height: 14, width: 210),
        SizedBox(height: KitchenSpacing.md),
        ShimmerBlock(height: 30, width: 126, borderRadius: 18),
      ],
    );
  }
}
