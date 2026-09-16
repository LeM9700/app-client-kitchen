import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/core/widgets/shimmer_skeleton.dart';
import 'package:app_client/features/loyalty/models/loyalty_account.dart';
import 'package:app_client/features/loyalty/models/loyalty_reward.dart';
import 'package:app_client/features/loyalty/models/loyalty_transaction.dart';
import 'package:app_client/features/loyalty/providers/loyalty_provider.dart';
import 'package:app_client/features/loyalty/repositories/loyalty_repository.dart';
import 'package:app_client/features/loyalty/widgets/kitchen_loyalty_card.dart';
import 'package:app_client/features/loyalty/widgets/kitchen_reward_card.dart';

String _formatDate(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} à '
      '${two(local.hour)}:${two(local.minute)}';
}

class LoyaltyScreen extends ConsumerStatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  ConsumerState<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends ConsumerState<LoyaltyScreen> {
  final Set<int> _redeemingRewardIds = {};

  @override
  Widget build(BuildContext context) {
    final accountAsync = ref.watch(loyaltyAccountProvider);
    final rewardsAsync = ref.watch(loyaltyRewardsProvider);
    final transactionsState = ref.watch(loyaltyTransactionsProvider);

    return Scaffold(
      backgroundColor: KitchenColors.paperLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(loyaltyAccountProvider);
            ref.invalidate(loyaltyRewardsProvider);
            await ref.read(loyaltyTransactionsProvider.notifier).refresh();
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              final metrics = notification.metrics;
              if (metrics.pixels >= metrics.maxScrollExtent - 200 &&
                  transactionsState.hasMore &&
                  !transactionsState.isLoadingMore) {
                ref.read(loyaltyTransactionsProvider.notifier).loadMore();
              }
              return false;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
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
                        'Ma fidélité',
                        style: KitchenTypography.title.copyWith(fontSize: 32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KitchenSpacing.lg),
                accountAsync.when(
                  data: (account) => KitchenLoyaltyCard(
                    account: account,
                    nextReward: _nextReward(account, rewardsAsync.valueOrNull),
                  ),
                  loading: () => const _LoyaltyCardSkeleton(),
                  error: (e, _) => _InlineError(
                    message: e is AppException
                        ? e.message
                        : 'Impossible de récupérer votre fidélité.',
                    onRetry: () => ref.invalidate(loyaltyAccountProvider),
                  ),
                ),
                const SizedBox(height: KitchenSpacing.xl),
                const _SectionTitle('Vos récompenses'),
                const SizedBox(height: KitchenSpacing.sm),
                rewardsAsync.when(
                  data: (rewards) => rewards.isEmpty
                      ? const _EmptyPanel(
                          icon: Icons.card_giftcard_outlined,
                          title: 'Aucune récompense',
                          subtitle:
                              'Le catalogue de récompenses est vide pour le moment.',
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < rewards.length; i += 1) ...[
                              KitchenRewardCard(
                                reward: rewards[i],
                                isRedeeming:
                                    _redeemingRewardIds.contains(rewards[i].id),
                                onRedeem: accountAsync.valueOrNull == null
                                    ? null
                                    : () => _confirmRedeem(
                                          rewards[i],
                                          accountAsync.valueOrNull!,
                                        ),
                              ),
                              if (i < rewards.length - 1)
                                const SizedBox(height: KitchenSpacing.sm),
                            ],
                          ],
                        ),
                  loading: () => const _RewardsSkeleton(),
                  error: (e, _) => _InlineError(
                    message: e is AppException
                        ? e.message
                        : 'Impossible de charger les récompenses.',
                    onRetry: () => ref.invalidate(loyaltyRewardsProvider),
                  ),
                ),
                const SizedBox(height: KitchenSpacing.xl),
                const _SectionTitle('Historique des points'),
                const SizedBox(height: KitchenSpacing.sm),
                _TransactionsSection(
                  state: transactionsState,
                  onRetry: () =>
                      ref.read(loyaltyTransactionsProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LoyaltyReward? _nextReward(
    LoyaltyAccount account,
    List<LoyaltyReward>? rewards,
  ) {
    final candidates = (rewards ?? [])
        .where(
          (reward) => reward.isActive && reward.pointsRequired > account.points,
        )
        .toList()
      ..sort((a, b) => a.pointsRequired.compareTo(b.pointsRequired));
    return candidates.isEmpty ? null : candidates.first;
  }

  Future<void> _confirmRedeem(
    LoyaltyReward reward,
    LoyaltyAccount account,
  ) async {
    if (_redeemingRewardIds.contains(reward.id)) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RedeemConfirmSheet(reward: reward, account: account),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _redeemingRewardIds.add(reward.id));
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref.read(loyaltyRedeemProvider).redeem(reward.id);
      if (!mounted) return;
      await _showRedeemResult(context, result);
    } on AppException catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _redeemingRewardIds.remove(reward.id));
      }
    }
  }

  Future<void> _showRedeemResult(
    BuildContext context,
    RedeemResult result,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => _RedeemResultDialog(result: result),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: KitchenTypography.label.copyWith(
        color: KitchenColors.brown700,
        fontSize: 13,
      ),
    );
  }
}

class _RedeemConfirmSheet extends StatelessWidget {
  const _RedeemConfirmSheet({required this.reward, required this.account});

  final LoyaltyReward reward;
  final LoyaltyAccount account;

  @override
  Widget build(BuildContext context) {
    final remaining = account.points - reward.pointsRequired;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: KitchenSurface(
          padding: const EdgeInsets.all(KitchenSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Confirmer l’échange',
                style: KitchenTypography.title.copyWith(fontSize: 28),
              ),
              const SizedBox(height: KitchenSpacing.sm),
              Text(
                reward.name,
                style: KitchenTypography.label.copyWith(fontSize: 15),
              ),
              const SizedBox(height: KitchenSpacing.md),
              _SummaryRow(
                label: 'Points requis',
                value: '${reward.pointsRequired}',
              ),
              _SummaryRow(label: 'Solde actuel', value: '${account.points}'),
              _SummaryRow(
                label: 'Solde après échange',
                value: '$remaining',
                emphasize: true,
              ),
              const SizedBox(height: KitchenSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: KitchenSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Confirmer'),
                    ),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = KitchenTypography.body.copyWith(
      color: emphasize ? KitchenColors.espresso : KitchenColors.textMuted,
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: KitchenSpacing.sm),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _RedeemResultDialog extends StatelessWidget {
  const _RedeemResultDialog({required this.result});

  final RedeemResult result;

  @override
  Widget build(BuildContext context) {
    final hasPromoCode = result.promoCode != null;

    return AlertDialog(
      title: const Text('Récompense échangée'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPromoCode) ...[
            Text(
              result.discountEuros != null
                  ? 'Voici votre code promo pour une réduction de '
                      '${formatPrice(result.discountEuros!)}. Saisissez-le au '
                      'moment du paiement : il n’est pas appliqué automatiquement.'
                  : 'Voici votre code promo. Saisissez-le au moment du '
                      'paiement : il n’est pas appliqué automatiquement.',
            ),
            const SizedBox(height: KitchenSpacing.md),
            InkWell(
              onTap: () => _copyPromoCode(context, result.promoCode!),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: KitchenColors.paperLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: KitchenColors.brown700.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.promoCode!,
                        style: KitchenTypography.label.copyWith(fontSize: 15),
                      ),
                    ),
                    const Icon(Icons.copy, size: 18),
                  ],
                ),
              ),
            ),
          ] else if (result.freeProductId != null) ...[
            const Text(
              'Votre produit offert a été enregistré. Il sera appliqué selon '
              'les règles serveur du programme fidélité.',
            ),
          ] else ...[
            const Text('Récompense échangée avec succès.'),
          ],
          const SizedBox(height: KitchenSpacing.md),
          Text('Solde restant : ${result.remainingPoints} points'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  void _copyPromoCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copié')),
    );
  }
}

class _TransactionsSection extends StatelessWidget {
  const _TransactionsSection({required this.state, required this.onRetry});

  final LoyaltyTransactionsState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.transactions.isEmpty) {
      return const _TransactionsSkeleton();
    }

    if (state.error != null && state.transactions.isEmpty) {
      return _InlineError(message: state.error!, onRetry: onRetry);
    }

    if (state.transactions.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.history_outlined,
        title: 'Votre aventure gourmande commence ici.',
        subtitle: 'Vos mouvements de points apparaîtront après vos commandes.',
      );
    }

    return Column(
      children: [
        for (var i = 0; i < state.transactions.length; i += 1) ...[
          _TransactionCard(transaction: state.transactions[i]),
          if (i < state.transactions.length - 1)
            const SizedBox(height: KitchenSpacing.sm),
        ],
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: KitchenLoadingIndicator(
                color: KitchenColors.cognac,
              ),
            ),
          ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final LoyaltyTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.pointsDelta >= 0;
    final color = isPositive ? KitchenColors.olive : KitchenColors.terracotta;

    return KitchenSurface(
      elevation: KitchenElevation.flat,
      padding: const EdgeInsets.all(KitchenSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.reason,
                  style: KitchenTypography.label.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction.createdAt),
                  style: KitchenTypography.body.copyWith(
                    color: KitchenColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KitchenSpacing.sm),
          Text(
            '${isPositive ? '+' : ''}${transaction.pointsDelta}',
            style: KitchenTypography.label.copyWith(
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return KitchenSurface(
      padding: const EdgeInsets.all(KitchenSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: KitchenColors.terracotta),
          const SizedBox(width: KitchenSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.textMuted,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

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
        ],
      ),
    );
  }
}

class _LoyaltyCardSkeleton extends StatelessWidget {
  const _LoyaltyCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const KitchenSurface(
      padding: EdgeInsets.all(KitchenSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShimmerBlock(height: 14, width: 82),
          SizedBox(height: 36),
          ShimmerBlock(height: 40, width: 180),
          SizedBox(height: 12),
          ShimmerBlock(height: 12, width: 130),
          SizedBox(height: 24),
          ShimmerBlock(height: 8, width: double.infinity, borderRadius: 999),
        ],
      ),
    );
  }
}

class _RewardsSkeleton extends StatelessWidget {
  const _RewardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        KitchenSurface(
          padding: EdgeInsets.all(KitchenSpacing.lg),
          child: ShimmerBlock(height: 82),
        ),
        SizedBox(height: KitchenSpacing.sm),
        KitchenSurface(
          padding: EdgeInsets.all(KitchenSpacing.lg),
          child: ShimmerBlock(height: 82),
        ),
      ],
    );
  }
}

class _TransactionsSkeleton extends StatelessWidget {
  const _TransactionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const KitchenSurface(
      padding: EdgeInsets.all(KitchenSpacing.lg),
      child: Center(
        child: KitchenLoadingIndicator(color: KitchenColors.cognac),
      ),
    );
  }
}
