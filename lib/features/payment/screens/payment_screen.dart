import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/checkout/widgets/kitchen_checkout_step_header.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/providers/order_provider.dart';
import 'package:app_client/features/payment/providers/payment_provider.dart';
import 'package:app_client/features/payment/repositories/payment_repository.dart';
import 'package:app_client/features/payment/services/stripe_payment_sheet_client.dart';
import 'package:app_client/l10n/app_localizations.dart';

/// Ecran de paiement : le CTA ouvre la vraie Stripe PaymentSheet.
///
/// Une livraison peut aussi etre payee a la remise : le client laisse alors une
/// empreinte bancaire (total pre-autorise, aucun debit) apres avoir accepte les
/// conditions affichees.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.orderId});
  final int orderId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _onDeliveryChoice = false;
  bool _termsAccepted = false;

  void _selectMode({required bool onDelivery}) {
    if (_onDeliveryChoice == onDelivery) return;
    setState(() {
      _onDeliveryChoice = onDelivery;
      _termsAccepted = false;
    });
    ref.read(paymentProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId;
    final paymentState = ref.watch(paymentProvider);
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final order = orderAsync.valueOrNull;
    final l10n = AppLocalizations.of(context)!;
    final total = order?.total;
    final canChooseOnDelivery = order != null &&
        order.orderType == OrderType.delivery &&
        order.paymentStatus == 'pending';
    final onDelivery = canChooseOnDelivery && _onDeliveryChoice;
    final termsAsync = onDelivery ? ref.watch(guaranteeTermsProvider) : null;
    final terms = termsAsync?.valueOrNull;
    final canSubmit = !onDelivery || (terms != null && _termsAccepted);
    final isLoading = paymentState.status == PaymentStatus.loading;
    final payLabel = isLoading
        ? 'Validation du paiement...'
        : paymentState.status == PaymentStatus.failure
            ? l10n.paymentRetryButton
            : total != null
                ? (onDelivery
                    ? l10n.paymentGuaranteeCta(formatPrice(total))
                    : 'Payer ${formatPrice(total)}')
                : l10n.paymentPayNowButton;

    ref.listen(paymentProvider, (_, next) {
      if (next.status == PaymentStatus.success) {
        context.go('/orders/$orderId/tracking');
      }
    });

    return Scaffold(
      backgroundColor: KitchenColors.paper,
      appBar: AppBar(
        backgroundColor: KitchenColors.paper,
        foregroundColor: KitchenColors.espresso,
        title: Text(l10n.paymentTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const KitchenCheckoutStepHeader(activeIndex: 2),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  KitchenSpacing.lg,
                  KitchenSpacing.md,
                  KitchenSpacing.lg,
                  KitchenSpacing.xl,
                ),
                children: [
                  if (canChooseOnDelivery) ...[
                    _PaymentModeSelector(
                      onDelivery: onDelivery,
                      enabled: !isLoading,
                      onChanged: (value) => _selectMode(onDelivery: value),
                    ),
                    const SizedBox(height: KitchenSpacing.lg),
                  ],
                  Text(
                    onDelivery
                        ? l10n.paymentGuaranteeHeading
                        : 'Montant a regler',
                    style: KitchenTypography.title.copyWith(fontSize: 30),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KitchenSpacing.sm),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: orderAsync.isLoading && total == null
                        ? const Center(
                            child: KitchenLoadingIndicator(
                              color: KitchenColors.cognac,
                            ),
                          )
                        : Text(
                            total != null
                                ? formatPrice(total)
                                : 'Montant confirme par Stripe',
                            key: ValueKey(total),
                            style: KitchenTypography.display.copyWith(
                              color: KitchenColors.cognac,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                  const SizedBox(height: KitchenSpacing.lg),
                  KitchenSurface(
                    padding: const EdgeInsets.all(KitchenSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Methode de paiement',
                          style: KitchenTypography.label.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: KitchenSpacing.md),
                        const _PaymentMethodCard(
                          icon: Icons.credit_card,
                          title: 'Carte bancaire',
                          subtitle: 'Saisie securisee par Stripe',
                          enabled: true,
                        ),
                        if (_showApplePay)
                          const _PaymentMethodCard(
                            icon: Icons.phone_iphone,
                            title: 'Apple Pay',
                            subtitle:
                                'Propose dans la PaymentSheet si disponible',
                            enabled: true,
                          ),
                        if (_showGooglePay)
                          const _PaymentMethodCard(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Google Pay',
                            subtitle:
                                'Propose dans la PaymentSheet si disponible',
                            enabled: true,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KitchenSpacing.md),
                  KitchenSurface(
                    elevation: KitchenElevation.inset,
                    padding: const EdgeInsets.all(KitchenSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PaymentFact(
                          icon: Icons.lock_outline,
                          text: l10n.paymentSecureSubtitle,
                        ),
                        const SizedBox(height: KitchenSpacing.xs),
                        const _PaymentFact(
                          icon: Icons.verified_user_outlined,
                          text:
                              'Stripe gere carte, wallets et authentification 3DS.',
                        ),
                      ],
                    ),
                  ),
                  if (onDelivery) ...[
                    const SizedBox(height: KitchenSpacing.md),
                    _GuaranteeTerms(
                      amount: total != null ? formatPrice(total) : '',
                      termsAsync: termsAsync!,
                      accepted: _termsAccepted,
                      onAcceptedChanged: (value) =>
                          setState(() => _termsAccepted = value),
                      onRetry: () => ref.invalidate(guaranteeTermsProvider),
                    ),
                  ],
                  if (paymentState.wasCancelled) ...[
                    const SizedBox(height: KitchenSpacing.md),
                    const _PaymentNotice(
                      icon: Icons.info_outline,
                      color: KitchenColors.cognac,
                      text:
                          'Paiement annule. La commande reste ouverte, vous pouvez reessayer.',
                    ),
                  ],
                  if (paymentState.status == PaymentStatus.failure &&
                      paymentState.error != null) ...[
                    const SizedBox(height: KitchenSpacing.md),
                    _PaymentNotice(
                      icon: Icons.error_outline,
                      color: KitchenColors.terracotta,
                      text: paymentState.error!,
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(KitchenSpacing.lg),
                child: Column(
                  children: [
                    KitchenEmbossedButton(
                      onPressed: canSubmit
                          ? () => ref.read(paymentProvider.notifier).pay(
                                orderId,
                                guarantee: onDelivery ? terms : null,
                              )
                          : null,
                      isLoading: isLoading,
                      semanticLabel: total != null
                          ? (onDelivery
                              ? l10n.paymentGuaranteeCta(formatPrice(total))
                              : 'Payer ${formatPrice(total)}')
                          : 'Payer la commande',
                      child: Text(payLabel),
                    ),
                    const SizedBox(height: KitchenSpacing.xs),
                    TextButton(
                      onPressed: isLoading ? null : () => context.pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: KitchenColors.cognac,
                        minimumSize: const Size(44, 44),
                      ),
                      child: Text(l10n.paymentCancelButton),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool get _showApplePay =>
      supportsNativeStripePaymentSheet &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.iOS;

  static bool get _showGooglePay =>
      supportsNativeStripePaymentSheet &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;
}

class _PaymentModeSelector extends StatelessWidget {
  const _PaymentModeSelector({
    required this.onDelivery,
    required this.enabled,
    required this.onChanged,
  });

  final bool onDelivery;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _PaymentModeOption(
          icon: Icons.credit_card,
          title: l10n.paymentModeOnlineTitle,
          subtitle: l10n.paymentModeOnlineSubtitle,
          selected: !onDelivery,
          onTap: enabled ? () => onChanged(false) : null,
        ),
        const SizedBox(height: KitchenSpacing.sm),
        _PaymentModeOption(
          icon: Icons.delivery_dining_outlined,
          title: l10n.paymentModeOnDeliveryTitle,
          subtitle: l10n.paymentModeOnDeliverySubtitle,
          selected: onDelivery,
          onTap: enabled ? () => onChanged(true) : null,
        ),
      ],
    );
  }
}

class _PaymentModeOption extends StatelessWidget {
  const _PaymentModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: title,
      hint: subtitle,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(KitchenSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? KitchenColors.cognac
                  : KitchenColors.brown700.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: KitchenColors.cognac),
              const SizedBox(width: KitchenSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: KitchenTypography.label),
                    const SizedBox(height: KitchenSpacing.xxs),
                    Text(
                      subtitle,
                      style: KitchenTypography.body.copyWith(
                        color: KitchenColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? KitchenColors.cognac
                    : KitchenColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuaranteeTerms extends StatelessWidget {
  const _GuaranteeTerms({
    required this.amount,
    required this.termsAsync,
    required this.accepted,
    required this.onAcceptedChanged,
    required this.onRetry,
  });

  final String amount;
  final AsyncValue<GuaranteeTerms> termsAsync;
  final bool accepted;
  final ValueChanged<bool> onAcceptedChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final terms = termsAsync.valueOrNull;
    return KitchenSurface(
      elevation: KitchenElevation.inset,
      padding: const EdgeInsets.all(KitchenSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PaymentFact(
            icon: Icons.shield_outlined,
            text: l10n.paymentGuaranteeExplainer(amount),
          ),
          const SizedBox(height: KitchenSpacing.xs),
          _PaymentFact(
            icon: Icons.info_outline,
            text: l10n.paymentGuaranteeChargeRule,
          ),
          if (terms != null) ...[
            const SizedBox(height: KitchenSpacing.xs),
            _PaymentFact(
              icon: Icons.schedule,
              text: l10n.paymentGuaranteeValidity(terms.holdValidityDays),
            ),
            const SizedBox(height: KitchenSpacing.xs),
            // Pas de CheckboxListTile : un ListTile sous une surface decoree leve une
            // assertion Flutter en debug (ses effets d'encre seraient masques).
            Semantics(
              container: true,
              excludeSemantics: true,
              checked: accepted,
              label: l10n.paymentGuaranteeAccept,
              onTap: () => onAcceptedChanged(!accepted),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onAcceptedChanged(!accepted),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Checkbox(
                        value: accepted,
                        activeColor: KitchenColors.cognac,
                        onChanged: (value) => onAcceptedChanged(value ?? false),
                      ),
                      Expanded(
                        child: Text(
                          l10n.paymentGuaranteeAccept,
                          style: KitchenTypography.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (termsAsync.hasError) ...[
            const SizedBox(height: KitchenSpacing.sm),
            _PaymentNotice(
              icon: Icons.error_outline,
              color: KitchenColors.terracotta,
              text: l10n.paymentGuaranteeTermsError,
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: KitchenColors.cognac,
                minimumSize: const Size(44, 44),
              ),
              child: Text(l10n.paymentRetryButton),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: KitchenSpacing.sm),
              child: Center(
                child: KitchenLoadingIndicator(color: KitchenColors.cognac),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KitchenSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: KitchenColors.cognac.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: KitchenColors.cognac),
          ),
          const SizedBox(width: KitchenSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: KitchenTypography.label),
                const SizedBox(height: KitchenSpacing.xxs),
                Text(
                  subtitle,
                  style: KitchenTypography.body.copyWith(
                    color: KitchenColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            enabled ? Icons.check_circle_outline : Icons.lock_outline,
            color: enabled ? KitchenColors.olive : KitchenColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _PaymentFact extends StatelessWidget {
  const _PaymentFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: KitchenColors.olive),
        const SizedBox(width: KitchenSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: KitchenTypography.body.copyWith(
              color: KitchenColors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentNotice extends StatelessWidget {
  const _PaymentNotice({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return KitchenSurface(
      elevation: KitchenElevation.inset,
      padding: const EdgeInsets.all(KitchenSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: KitchenSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: KitchenTypography.body.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
