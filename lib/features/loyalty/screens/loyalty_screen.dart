import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/widgets/empty_state.dart';
import 'package:app_client/core/widgets/error_view.dart';
import 'package:app_client/core/widgets/shimmer_skeleton.dart';
import 'package:app_client/features/loyalty/models/loyalty_account.dart';
import 'package:app_client/features/loyalty/models/loyalty_reward.dart';
import 'package:app_client/features/loyalty/models/loyalty_transaction.dart';
import 'package:app_client/features/loyalty/providers/loyalty_provider.dart';
import 'package:app_client/features/loyalty/repositories/loyalty_repository.dart';

String _formatPrice(double price) => '${price.toStringAsFixed(2)} €';

String _formatDate(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} à '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Écran fidélité (Plan 16) — solde, historique des transactions et
/// catalogue de récompenses avec échange.
///
/// [Décision d'architecture n°1, plan-16] Aucun calcul de points côté
/// client : l'écran affiche ce que le serveur renvoie (`GET /loyalty/me`,
/// `GET /loyalty/rewards` avec `can_redeem`/`missing_points` déjà calculés).
class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(loyaltyAccountProvider);
    final rewardsAsync = ref.watch(loyaltyRewardsProvider);
    final transactionsState = ref.watch(loyaltyTransactionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Fidélité')),
      body: RefreshIndicator(
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
            padding: const EdgeInsets.all(16),
            children: [
              // ── Solde ──────────────────────────────────────────────────
              accountAsync.when(
                data: (account) => _PointsBalance(account: account),
                loading: () => const _BalanceSkeleton(),
                error: (e, _) => _InlineError(
                  message: e is AppException ? e.message : 'Erreur inattendue.',
                  onRetry: () => ref.invalidate(loyaltyAccountProvider),
                ),
              ),

              const SizedBox(height: 24),

              // ── Récompenses ────────────────────────────────────────────
              Text('Récompenses', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              rewardsAsync.when(
                data: (rewards) => rewards.isEmpty
                    ? const EmptyState(
                        title: 'Aucune récompense',
                        subtitle:
                            'Aucune récompense disponible pour le moment.',
                        icon: Icons.card_giftcard_outlined,
                      )
                    : Column(
                        children: rewards
                            .map(
                              (reward) => _RewardTile(
                                reward: reward,
                                onRedeem: accountAsync.value == null
                                    ? null
                                    : () => _confirmRedeem(
                                          context,
                                          ref,
                                          reward,
                                          accountAsync.value!,
                                        ),
                              ),
                            )
                            .toList(),
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _InlineError(
                  message: e is AppException ? e.message : 'Erreur inattendue.',
                  onRetry: () => ref.invalidate(loyaltyRewardsProvider),
                ),
              ),

              const SizedBox(height: 24),

              // ── Historique ─────────────────────────────────────────────
              Text('Historique des points', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              _TransactionsSection(
                state: transactionsState,
                onRetry: () =>
                    ref.read(loyaltyTransactionsProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRedeem(
    BuildContext context,
    WidgetRef ref,
    LoyaltyReward reward,
    LoyaltyAccount account,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RedeemConfirmSheet(reward: reward, account: account),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref.read(loyaltyRedeemProvider).redeem(reward.id);
      if (!context.mounted) return;
      await _showRedeemResult(context, result);
    } on AppException catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
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

// ─────────────────────────────────────────────────────────────────────────
// Solde
// ─────────────────────────────────────────────────────────────────────────

class _PointsBalance extends StatelessWidget {
  const _PointsBalance({required this.account});
  final LoyaltyAccount account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Votre solde', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${account.points} points',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (account.pointValueEuros > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Soit environ ${_formatPrice(account.pointValueEuros)}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (account.expiringSoonPoints > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 18,
                    color: Color(0xFFB26A00),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${account.expiringSoonPoints} points expirent bientôt',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: const Color(0xFFB26A00)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BalanceSkeleton extends StatelessWidget {
  const _BalanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShimmerBlock(height: 16, width: 100),
            SizedBox(height: 12),
            ShimmerBlock(height: 28, width: 140),
            SizedBox(height: 8),
            ShimmerBlock(height: 14, width: 160),
          ],
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFB71C1C)),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Récompenses
// ─────────────────────────────────────────────────────────────────────────

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.reward, required this.onRedeem});
  final LoyaltyReward reward;
  final VoidCallback? onRedeem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // [🔒 api-corrections-phase-d.md §6] canRedeem/missingPoints viennent du
    // serveur — jamais recalculés ici (pointsRequired > currentPoints).
    final disabled = !reward.canRedeem;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reward.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      reward.rewardType == LoyaltyRewardType.discountEuros
                          ? 'Réduction de ${_formatPrice(reward.discountAmount ?? 0)}'
                          : 'Produit offert',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reward.pointsRequired} points',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (disabled && reward.missingPoints > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Encore ${reward.missingPoints} points nécessaires',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: disabled ? null : onRedeem,
                child: const Text('Échanger'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [Décision d'architecture n°2, plan-16] BottomSheet de confirmation
/// obligatoire avant l'échange — irréversible côté serveur.
class _RedeemConfirmSheet extends StatelessWidget {
  const _RedeemConfirmSheet({required this.reward, required this.account});
  final LoyaltyReward reward;
  final LoyaltyAccount account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = account.points - reward.pointsRequired;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirmer l\'échange', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(reward.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Confirmer'),
                  ),
                ),
              ],
            ),
          ],
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
    final style = emphasize
        ? Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Dialogue affiché après un échange réussi.
///
/// [🔒 api-corrections-phase-d.md §6] Pour `discount_euros`, le serveur
/// génère un code promo à usage unique (`promoCode`) — il n'est PAS appliqué
/// automatiquement. Ce dialogue l'affiche (copiable) et indique de le saisir
/// au panier/checkout, sans jamais prétendre que la réduction est déjà
/// active sur une commande.
class _RedeemResultDialog extends StatelessWidget {
  const _RedeemResultDialog({required this.result});
  final RedeemResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      '${_formatPrice(result.discountEuros!)}. Saisissez-le au '
                      'moment du paiement — il n\'est pas appliqué '
                      'automatiquement.'
                  : 'Voici votre code promo. Saisissez-le au moment du '
                      'paiement — il n\'est pas appliqué automatiquement.',
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _copyPromoCode(context, result.promoCode!),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      result.promoCode!,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.copy, size: 18),
                  ],
                ),
              ),
            ),
          ] else if (result.freeProductId != null) ...[
            const Text(
              'Votre produit offert a été enregistré. Il sera appliqué à '
              'votre prochaine commande.',
            ),
          ] else ...[
            const Text('Récompense échangée avec succès.'),
          ],
          const SizedBox(height: 16),
          Text(
            'Solde restant : ${result.remainingPoints} points',
            style: theme.textTheme.bodyMedium,
          ),
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

// ─────────────────────────────────────────────────────────────────────────
// Historique des transactions
// ─────────────────────────────────────────────────────────────────────────

class _TransactionsSection extends StatelessWidget {
  const _TransactionsSection({required this.state, required this.onRetry});
  final LoyaltyTransactionsState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.transactions.isEmpty) {
      return ErrorView(message: state.error!, onRetry: onRetry);
    }

    if (state.transactions.isEmpty) {
      return const EmptyState(
        title: 'Aucun mouvement',
        subtitle: 'Aucun mouvement de points pour le moment.',
        icon: Icons.history_outlined,
      );
    }

    return Column(
      children: [
        ...state.transactions.map((tx) => _TransactionTile(transaction: tx)),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final LoyaltyTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = transaction.pointsDelta >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.reason, style: theme.textTheme.bodyMedium),
                Text(
                  _formatDate(transaction.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${transaction.pointsDelta}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isPositive
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFB71C1C),
            ),
          ),
        ],
      ),
    );
  }
}
