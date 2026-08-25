import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/features/checkout/screens/steps/step_address.dart';
import 'package:app_client/features/checkout/screens/steps/step_delivery_mode.dart';
import 'package:app_client/features/checkout/screens/steps/step_recap.dart';
import 'package:app_client/features/checkout/screens/steps/step_revalidation.dart';
import 'package:app_client/features/checkout/widgets/checkout_auth_gate.dart';

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

  String _titleForStep(CheckoutStep step) {
    switch (step) {
      case CheckoutStep.revalidation:
        return 'Vérification du panier';
      case CheckoutStep.deliveryMode:
        return 'Livraison ou retrait ?';
      case CheckoutStep.address:
        return 'Adresse de livraison';
      case CheckoutStep.recap:
        return 'Récapitulatif';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isAuthenticated ? _titleForStep(currentStep) : 'Commander'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour au panier',
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
