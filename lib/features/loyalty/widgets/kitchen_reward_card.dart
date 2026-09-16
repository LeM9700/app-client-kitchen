import 'package:flutter/material.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/loyalty/models/loyalty_reward.dart';

class KitchenRewardCard extends StatelessWidget {
  const KitchenRewardCard({
    super.key,
    required this.reward,
    required this.onRedeem,
    this.isRedeeming = false,
  });

  final LoyaltyReward reward;
  final VoidCallback? onRedeem;
  final bool isRedeeming;

  @override
  Widget build(BuildContext context) {
    final inactive = !reward.isActive;
    final locked = !inactive && !reward.canRedeem;
    final available = reward.isActive && reward.canRedeem;
    final accent = available ? KitchenColors.olive : KitchenColors.textMuted;

    return Opacity(
      opacity: inactive ? 0.56 : 1,
      child: KitchenSurface(
        elevation: available ? KitchenElevation.raised : KitchenElevation.flat,
        padding: const EdgeInsets.all(KitchenSpacing.md),
        color: locked ? KitchenColors.flour.withValues(alpha: 0.56) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: available
                        ? KitchenColors.olive.withValues(alpha: 0.14)
                        : KitchenColors.paperLight.withValues(alpha: 0.72),
                  ),
                  child: Icon(
                    reward.rewardType == LoyaltyRewardType.freeProduct
                        ? Icons.local_pizza_outlined
                        : Icons.sell_outlined,
                    color:
                        available ? KitchenColors.olive : KitchenColors.cognac,
                  ),
                ),
                const SizedBox(width: KitchenSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: KitchenTypography.label.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _rewardDescription(reward),
                        style: KitchenTypography.body.copyWith(
                          color: KitchenColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: KitchenSpacing.sm),
                _StatePill(label: _stateLabel(reward), color: accent),
              ],
            ),
            const SizedBox(height: KitchenSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${reward.pointsRequired} points',
                    style: KitchenTypography.label.copyWith(
                      color: KitchenColors.espresso,
                    ),
                  ),
                ),
                if (locked && reward.missingPoints > 0)
                  Flexible(
                    child: Text(
                      'Encore ${reward.missingPoints}',
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: KitchenTypography.body.copyWith(
                        color: KitchenColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (available) ...[
              const SizedBox(height: KitchenSpacing.md),
              KitchenEmbossedButton(
                onPressed: isRedeeming ? null : onRedeem,
                isLoading: isRedeeming,
                semanticLabel: 'Échanger ${reward.name}',
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: const Text('Échanger'),
              ),
            ] else if (isRedeeming) ...[
              const SizedBox(height: KitchenSpacing.md),
              const Center(
                child: KitchenLoadingIndicator(
                  color: KitchenColors.cognac,
                  size: 28,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _rewardDescription(LoyaltyReward reward) {
    return switch (reward.rewardType) {
      LoyaltyRewardType.discountEuros => reward.discountAmount == null
          ? 'Réduction'
          : 'Réduction de ${formatPrice(reward.discountAmount!)}',
      LoyaltyRewardType.freeProduct => 'Produit offert',
    };
  }

  String _stateLabel(LoyaltyReward reward) {
    if (!reward.isActive) return 'Indisponible';
    if (reward.canRedeem) return 'Disponible';
    return 'Verrouillée';
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: KitchenTypography.label.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }
}
