import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
  LoyaltyQrToken? _qrToken;
  Timer? _qrClock;
  bool _qrLoading = false;

  @override
  void initState() {
    super.initState();
    _qrClock = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && _qrToken != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _qrClock?.cancel();
    super.dispose();
  }

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
                const SizedBox(height: KitchenSpacing.md),
                _LoyaltyQrPanel(
                  qrToken: _qrToken,
                  loading: _qrLoading,
                  onGenerate: _generateQrToken,
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

  Future<void> _generateQrToken() async {
    if (_qrLoading) return;
    setState(() => _qrLoading = true);
    try {
      final token = await ref.read(loyaltyRepositoryProvider).createQrToken();
      if (!mounted) return;
      setState(() => _qrToken = token);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _qrLoading = false);
      }
    }
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

class _LoyaltyQrPanel extends StatelessWidget {
  const _LoyaltyQrPanel({
    required this.qrToken,
    required this.loading,
    required this.onGenerate,
  });

  final LoyaltyQrToken? qrToken;
  final bool loading;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final token = qrToken;
    final isExpired = token != null && !token.expiresAt.isAfter(DateTime.now());
    final remainingSeconds = token == null || isExpired
        ? 0
        : token.expiresAt.difference(DateTime.now()).inSeconds;
    return KitchenSurface(
      padding: const EdgeInsets.all(KitchenSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2_outlined, color: KitchenColors.cognac),
              const SizedBox(width: KitchenSpacing.sm),
              Expanded(
                child: Text(
                  'QR code fidélité',
                  style: KitchenTypography.label.copyWith(fontSize: 14),
                ),
              ),
              TextButton.icon(
                onPressed: loading ? null : onGenerate,
                icon: loading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        token == null || isExpired
                            ? Icons.qr_code_2_outlined
                            : Icons.refresh,
                      ),
                label: Text(
                  token == null
                      ? 'Afficher mon QR code'
                      : isExpired
                          ? 'Nouveau QR'
                          : 'Renouveler',
                ),
              ),
            ],
          ),
          const SizedBox(height: KitchenSpacing.sm),
          Text(
            'Présentez-le au comptoir. Il change à chaque génération et reste valable 2 minutes.',
            style: KitchenTypography.body.copyWith(
              color: KitchenColors.textMuted,
              fontSize: 12,
            ),
          ),
          if (isExpired) ...[
            const SizedBox(height: KitchenSpacing.md),
            _ExpiredQrNotice(onGenerate: loading ? null : onGenerate),
          ] else if (token != null) ...[
            const SizedBox(height: KitchenSpacing.md),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KitchenColors.espresso,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: QrImageView(
                      data: token.token,
                      version: QrVersions.auto,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                      size: 204,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => _copyToken(context, token.token),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copier le code de secours'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SelectableText(
                    token.token,
                    textAlign: TextAlign.center,
                    style: KitchenTypography.body.copyWith(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KitchenSpacing.sm),
            Text(
              remainingSeconds > 0
                  ? 'Expire dans ${_formatRemaining(remainingSeconds)}'
                  : 'Expire à ${_formatDate(token.expiresAt)}',
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

  void _copyToken(BuildContext context, String token) {
    Clipboard.setData(ClipboardData(text: token));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code fidelite copie')),
    );
  }
}

String _formatRemaining(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  if (minutes <= 0) {
    return '$rest s';
  }
  return '$minutes min ${rest.toString().padLeft(2, '0')} s';
}

class _ExpiredQrNotice extends StatelessWidget {
  const _ExpiredQrNotice({required this.onGenerate});

  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KitchenSpacing.md),
      decoration: BoxDecoration(
        color: KitchenColors.cognac.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KitchenColors.cognac.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.timer_off_outlined, color: KitchenColors.cognac),
          const SizedBox(height: KitchenSpacing.xs),
          Text(
            'Ce QR code a expiré.',
            style: KitchenTypography.label.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Générez-en un nouveau lorsque le staff vous le demande.',
            textAlign: TextAlign.center,
            style: KitchenTypography.body.copyWith(
              color: KitchenColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: KitchenSpacing.sm),
          TextButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.refresh),
            label: const Text('Afficher un nouveau QR code'),
          ),
        ],
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
