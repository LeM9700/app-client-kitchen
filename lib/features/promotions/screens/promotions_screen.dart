import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/promotions/models/promotion.dart';
import 'package:app_client/features/promotions/providers/promotions_provider.dart';

/// Vitrine des promotions actives, accessible sans authentification.
class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsAsync = ref.watch(promotionsProvider);

    return Scaffold(
      backgroundColor: KitchenColors.paper,
      appBar: AppBar(
        backgroundColor: KitchenColors.paper,
        foregroundColor: KitchenColors.espresso,
        title: Text('Offres', style: KitchenTypography.title),
      ),
      body: RefreshIndicator(
        color: KitchenColors.cognac,
        onRefresh: () async => ref.invalidate(promotionsProvider),
        child: promotionsAsync.when(
          loading: () => const _LoadingState(),
          error: (e, _) => _FullScreenCenter(
            child: _KitchenErrorState(
              message: e is AppException ? e.message : 'Erreur inattendue.',
              onRetry: () => ref.invalidate(promotionsProvider),
            ),
          ),
          data: (promos) => promos.isEmpty
              ? const _FullScreenCenter(child: _KitchenEmptyPromos())
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    KitchenSpacing.lg,
                    KitchenSpacing.md,
                    KitchenSpacing.lg,
                    KitchenSpacing.xl,
                  ),
                  itemCount: promos.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: KitchenSpacing.md),
                  itemBuilder: (_, i) => _PromoCard(promo: promos[i]),
                ),
        ),
      ),
    );
  }
}

class _FullScreenCenter extends StatelessWidget {
  const _FullScreenCenter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(KitchenSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: KitchenLoadingIndicator(color: KitchenColors.cognac),
    );
  }
}

class _KitchenEmptyPromos extends StatelessWidget {
  const _KitchenEmptyPromos();

  @override
  Widget build(BuildContext context) {
    return KitchenSurface(
      padding: const EdgeInsets.all(KitchenSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_offer_outlined,
            color: KitchenColors.cognac,
            size: 42,
          ),
          const SizedBox(height: KitchenSpacing.md),
          Text(
            'Aucune offre en ce moment',
            textAlign: TextAlign.center,
            style: KitchenTypography.title.copyWith(fontSize: 28),
          ),
          const SizedBox(height: KitchenSpacing.xs),
          Text(
            'Revenez bientôt, l’atelier prépare souvent de nouvelles attentions.',
            textAlign: TextAlign.center,
            style: KitchenTypography.body.copyWith(
              color: KitchenColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _KitchenErrorState extends StatelessWidget {
  const _KitchenErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return KitchenSurface(
      padding: const EdgeInsets.all(KitchenSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: KitchenColors.terracotta,
            size: 42,
          ),
          const SizedBox(height: KitchenSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: KitchenTypography.body.copyWith(
              color: KitchenColors.terracotta,
            ),
          ),
          const SizedBox(height: KitchenSpacing.lg),
          KitchenEmbossedButton(
            onPressed: onRetry,
            semanticLabel: 'Réessayer le chargement des offres',
            child: const Text('RÉESSAYER'),
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo});

  final Promotion promo;

  @override
  Widget build(BuildContext context) {
    final accent =
        promo.isExpiringSoon ? KitchenColors.terracotta : KitchenColors.cognac;

    return KitchenSurface(
      padding: const EdgeInsets.all(KitchenSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DiscountBadge(label: promo.displayDiscount, color: accent),
              const Spacer(),
              if (promo.isExpiringSoon && promo.expiresAt != null)
                _ExpiryCountdown(expiresAt: promo.expiresAt!),
            ],
          ),
          const SizedBox(height: KitchenSpacing.md),
          Text(
            promo.displayTitle,
            style: KitchenTypography.title.copyWith(fontSize: 27),
          ),
          if (promo.minimumOrderAmount > 0) ...[
            const SizedBox(height: KitchenSpacing.xs),
            Text(
              'À partir de ${formatPrice(promo.minimumOrderAmount)}',
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: KitchenSpacing.md),
          Divider(color: KitchenColors.brown700.withValues(alpha: 0.16)),
          const SizedBox(height: KitchenSpacing.sm),
          _PromoCodeCopy(code: promo.code),
        ],
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KitchenSpacing.sm,
        vertical: KitchenSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(KitchenRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        style: KitchenTypography.label.copyWith(color: color),
      ),
    );
  }
}

class _PromoCodeCopy extends StatelessWidget {
  const _PromoCodeCopy({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Copier le code promotion $code',
      child: InkWell(
        borderRadius: BorderRadius.circular(KitchenRadius.md),
        onTap: () {
          Clipboard.setData(ClipboardData(text: code));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Code copié')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KitchenSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KitchenSpacing.sm,
                  vertical: KitchenSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: KitchenColors.paperLight.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(KitchenRadius.md),
                  border: Border.all(
                    color: KitchenColors.brown700.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  code,
                  style: KitchenTypography.label.copyWith(
                    color: KitchenColors.cognac,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: KitchenSpacing.xs),
              const Icon(Icons.copy, size: 18, color: KitchenColors.cognac),
              const SizedBox(width: KitchenSpacing.xs),
              Text(
                'Copier',
                style: KitchenTypography.label.copyWith(
                  color: KitchenColors.cognac,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpiryCountdown extends StatefulWidget {
  const _ExpiryCountdown({required this.expiresAt});

  final DateTime expiresAt;

  @override
  State<_ExpiryCountdown> createState() => _ExpiryCountdownState();
}

class _ExpiryCountdownState extends State<_ExpiryCountdown> {
  late Duration _remaining;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresAt.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = widget.expiresAt.difference(DateTime.now()));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clamped = _remaining.isNegative ? Duration.zero : _remaining;
    final h = clamped.inHours;
    final m = clamped.inMinutes % 60;

    return Text(
      'Expire dans ${h}h${m.toString().padLeft(2, '0')}',
      style: KitchenTypography.label.copyWith(
        color: KitchenColors.terracotta,
        fontSize: 12,
      ),
    );
  }
}
