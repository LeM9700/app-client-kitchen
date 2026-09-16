import 'package:flutter/material.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_shadows.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/features/loyalty/models/loyalty_account.dart';
import 'package:app_client/features/loyalty/models/loyalty_reward.dart';

class KitchenLoyaltyCard extends StatelessWidget {
  const KitchenLoyaltyCard({
    super.key,
    required this.account,
    this.nextReward,
  });

  final LoyaltyAccount account;
  final LoyaltyReward? nextReward;

  @override
  Widget build(BuildContext context) {
    final reward = nextReward;
    final target = reward?.pointsRequired ?? 0;
    final progress =
        target > 0 ? (account.points / target).clamp(0.0, 1.0).toDouble() : 0.0;
    final missing = reward == null
        ? 0
        : reward.missingPoints > 0
            ? reward.missingPoints
            : (reward.pointsRequired - account.points)
                .clamp(0, reward.pointsRequired);

    return Semantics(
      label: 'Carte fidélité, ${account.points} points',
      child: Container(
        padding: const EdgeInsets.all(KitchenSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: KitchenRadius.card,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB56A2C),
              KitchenColors.cognac,
              Color(0xFF5A2F18),
            ],
          ),
          border: Border.all(
            color: KitchenColors.whiteWarm.withValues(alpha: 0.24),
          ),
          boxShadow: KitchenShadows.raised,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'KITCHEN',
                  style: KitchenTypography.label.copyWith(
                    color: KitchenColors.whiteWarm,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  'CARTE MEMBRE',
                  style: KitchenTypography.label.copyWith(
                    color: KitchenColors.whiteWarm.withValues(alpha: 0.78),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KitchenSpacing.xl),
            Text(
              '${account.points} points',
              style: KitchenTypography.display.copyWith(
                color: KitchenColors.whiteWarm,
                fontSize: 42,
              ),
            ),
            if (account.pointValueEuros > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Valeur estimée : ${formatPrice(account.pointValueEuros)}',
                style: KitchenTypography.body.copyWith(
                  color: KitchenColors.whiteWarm.withValues(alpha: 0.82),
                  fontSize: 12,
                ),
              ),
            ],
            if (reward != null) ...[
              const SizedBox(height: KitchenSpacing.lg),
              ClipRRect(
                borderRadius: BorderRadius.circular(KitchenRadius.pill),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress,
                  backgroundColor:
                      KitchenColors.espresso.withValues(alpha: 0.26),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    KitchenColors.whiteWarm,
                  ),
                ),
              ),
              const SizedBox(height: KitchenSpacing.sm),
              Text(
                missing > 0
                    ? 'Plus que $missing points avant ${reward.name}'
                    : '${reward.name} est disponible',
                style: KitchenTypography.body.copyWith(
                  color: KitchenColors.whiteWarm.withValues(alpha: 0.88),
                  fontSize: 13,
                  height: 1.25,
                ),
              ),
            ],
            if (account.expiringSoonPoints > 0) ...[
              const SizedBox(height: KitchenSpacing.md),
              _ExpiringPill(points: account.expiringSoonPoints),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpiringPill extends StatelessWidget {
  const _ExpiringPill({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KitchenColors.espresso.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(KitchenRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: KitchenColors.whiteWarm,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$points points expirent bientôt',
            style: KitchenTypography.label.copyWith(
              color: KitchenColors.whiteWarm,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
