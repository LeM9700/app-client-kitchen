import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/features/checkout/screens/steps/step_address.dart';
import 'package:app_client/features/checkout/screens/steps/step_delivery_mode.dart';
import 'package:app_client/features/checkout/screens/steps/step_recap.dart';
import 'package:app_client/features/checkout/screens/steps/step_revalidation.dart';
import 'package:app_client/features/checkout/widgets/checkout_auth_gate.dart';
import 'package:app_client/features/checkout/widgets/kitchen_checkout_step_header.dart';
import 'package:app_client/l10n/app_localizations.dart';

/// Tunnel de checkout — 4 étapes dans un seul écran (voir décision
/// d'architecture n°1 du plan) : la navigation entre étapes est pilotée par
/// [CheckoutState.currentStep], pas par des routes GoRouter séparées.
///
/// [Plan 12] Si l'utilisateur n'est pas authentifié (`accessTokenProvider`
/// null), les étapes sont masquées derrière [CheckoutAuthGate] — auth inline
/// sans quitter la route `/checkout`, panier et [CheckoutNotifier] préservés
/// (revalidation déjà lancée par [initState] ci-dessous, elle ne repart pas
/// quand l'utilisateur se connecte). Dès que `accessTokenProvider` est
/// renseigné (login/register réussi), l'`AnimatedSwitcher` révèle les étapes
/// checkout existantes sans navigation.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    // Revalidation des prix/disponibilités dès l'ouverture du checkout
    // (décision d'architecture n°2) — après le premier frame pour disposer
    // d'un `BuildContext`/`ref` valide.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkoutProvider.notifier).revalidateCart();
    });
  }

  int _progressIndexForStep(CheckoutStep step) {
    switch (step) {
      case CheckoutStep.revalidation:
      case CheckoutStep.deliveryMode:
      case CheckoutStep.address:
        return 0;
      case CheckoutStep.recap:
        return 1;
    }
  }

  Widget _bodyForStep(CheckoutStep step) {
    switch (step) {
      case CheckoutStep.revalidation:
        return const StepRevalidation();
      case CheckoutStep.deliveryMode:
        return const StepDeliveryMode();
      case CheckoutStep.address:
        return const StepAddress();
      case CheckoutStep.recap:
        return const StepRecap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(accessTokenProvider) != null;
    final currentStep =
        ref.watch(checkoutProvider.select((s) => s.currentStep));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: KitchenColors.paper,
      appBar: AppBar(
        backgroundColor: KitchenColors.paper,
        foregroundColor: KitchenColors.espresso,
        title: Text(
          isAuthenticated ? 'Finaliser ma commande' : l10n.checkoutGenericTitle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.checkoutBackToCart,
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isAuthenticated
              ? Column(
                  key: const ValueKey('steps'),
                  children: [
                    KitchenCheckoutStepHeader(
                      activeIndex: _progressIndexForStep(currentStep),
                    ),
                    Expanded(child: _bodyForStep(currentStep)),
                  ],
                )
              : const CheckoutAuthGate(key: ValueKey('auth')),
        ),
      ),
    );
  }
}
