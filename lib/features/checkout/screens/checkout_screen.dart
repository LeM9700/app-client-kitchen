import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/theme/kod_mome/kod_mome_design_pack.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/features/checkout/screens/steps/step_address.dart';
import 'package:app_client/features/checkout/screens/steps/step_delivery_mode.dart';
import 'package:app_client/features/checkout/screens/steps/step_recap.dart';
import 'package:app_client/features/checkout/screens/steps/step_revalidation.dart';
import 'package:app_client/features/checkout/widgets/checkout_auth_gate.dart';
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

  String _titleForStep(AppLocalizations l10n, CheckoutStep step) {
    switch (step) {
      case CheckoutStep.revalidation:
        return l10n.checkoutStepRevalidationTitle;
      case CheckoutStep.deliveryMode:
        return l10n.checkoutStepDeliveryModeTitle;
      case CheckoutStep.address:
        return l10n.checkoutStepAddressTitle;
      case CheckoutStep.recap:
        return l10n.checkoutStepRecapTitle;
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
    final isKodMome = Env.isKodMomeBuild;

    return Scaffold(
      backgroundColor: isKodMome ? KodMomeDesignPack.charcoal : null,
      appBar: AppBar(
        backgroundColor: isKodMome ? KodMomeDesignPack.charcoal : null,
        foregroundColor: isKodMome ? KodMomeDesignPack.cream : null,
        title: Text(
          isAuthenticated
              ? _titleForStep(l10n, currentStep)
              : l10n.checkoutGenericTitle,
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
              ? KeyedSubtree(
                  key: const ValueKey('steps'),
                  child: _bodyForStep(currentStep),
                )
              : const CheckoutAuthGate(key: ValueKey('auth')),
        ),
      ),
    );
  }
}
