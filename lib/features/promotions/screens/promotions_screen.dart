import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/widgets/empty_state.dart';
import 'package:app_client/core/widgets/error_view.dart';
import 'package:app_client/features/promotions/models/promotion.dart';
import 'package:app_client/features/promotions/providers/promotions_provider.dart';

String _formatPrice(double price) => '${price.toStringAsFixed(2)} €';

/// Écran promotions (Plan 17) — vitrine des promotions actives du
/// restaurant, accessible sans authentification. Informatif uniquement :
/// l'application d'un code au panier reste dans le flow checkout (Plan 09),
/// hors scope ici (voir doc de classe de [Promotion]).
class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsAsync = ref.watch(promotionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Offres & Promotions')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(promotionsProvider),
        child: promotionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _FullScreenCenter(
            child: ErrorView(
              message: e is AppException ? e.message : 'Erreur inattendue.',
              onRetry: () => ref.invalidate(promotionsProvider),
            ),
          ),
          data: (promos) => promos.isEmpty
              ? const _FullScreenCenter(
                  child: EmptyState(
                    title: 'Aucune offre',
                    subtitle: 'Aucune offre en ce moment. Revenez bientôt !',
                    icon: Icons.local_offer_outlined,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: promos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _PromoCard(promo: promos[i]),
                ),
        ),
      ),
    );
  }
}

/// Enveloppe un état vide/erreur dans un scroll toujours actif — nécessaire
/// pour que [RefreshIndicator] (pull-to-refresh) reste utilisable même quand
/// le contenu ne remplit pas l'écran (liste vide ou en erreur).
class _FullScreenCenter extends StatelessWidget {
  const _FullScreenCenter({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo});
  final Promotion promo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: promo.isExpiringSoon
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: promo.isExpiringSoon ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Badge réduction
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    promo.displayDiscount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                // Countdown si expire bientôt
                if (promo.isExpiringSoon && promo.expiresAt != null)
                  _ExpiryCountdown(expiresAt: promo.expiresAt!),
              ],
            ),

            const SizedBox(height: 12),
            Text(promo.displayTitle, style: theme.textTheme.titleLarge),
            if (promo.minimumOrderAmount > 0) ...[
              const SizedBox(height: 4),
              Text(
                'À partir de ${_formatPrice(promo.minimumOrderAmount)}',
                style: theme.textTheme.labelSmall,
              ),
            ],

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Code copiable
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: promo.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copié !')),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text(
                      promo.code,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.copy, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Copier',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
