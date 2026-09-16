import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/core/router/app_router.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/theme/tenant_theme_provider.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_brand_logo.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_photo_background.dart';
import 'package:app_client/features/onboarding/providers/onboarding_provider.dart';
import 'package:app_client/features/tracking/services/push_notification_service.dart';

/// Ecran de demarrage: execute la sequence de boot de l'application.
///
/// Sequence preservee:
/// 1. Injecter le slug tenant dans le header HTTP global.
/// 2. Initialiser les notifications push en best-effort.
/// 3. Charger le branding en parallele avec les futurs prechargements.
/// 4. Naviguer vers l'onboarding si necessaire, sinon vers l'accueil public.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    const slug = Env.tenantSlug;

    ref.read(apiClientProvider).setTenantSlug(slug);

    unawaited(
      PushNotificationService.initialize(
        apiClient: ref.read(apiClientProvider),
        router: ref.read(routerProvider),
      ),
    );

    await Future.wait([
      ref.read(tenantBrandingProvider.notifier).load(slug),
      // [Plan 07] ref.read(catalogProvider.notifier).prefetch(),
    ]);

    final onboardingCompleted = await _onboardingCompleted();

    if (mounted) {
      context.go(
        onboardingCompleted ? AppRoutes.home : AppRoutes.onboarding,
      );
    }
  }

  Future<bool> _onboardingCompleted() async {
    try {
      return await ref.read(onboardingStorageProvider).isCompleted();
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: KitchenPhotoBackground(
        assetPath: KitchenAssets.splashBackground,
        alignment: Alignment.center,
        enableSlowScale: true,
        child: SafeArea(child: _SplashContent()),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 30),
      child: Column(
        children: [
          const Spacer(flex: 2),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: disableAnimations ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 560),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 16),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                const KitchenBrandLogo(size: 112, light: true),
                const SizedBox(height: 26),
                Text(
                  'KITCHEN',
                  textAlign: TextAlign.center,
                  style: KitchenTypography.label.copyWith(
                    color: KitchenColors.whiteWarm,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'PIZZAS DE CARACTERE\nA TOUT MOMENT',
                  textAlign: TextAlign.center,
                  style: KitchenTypography.body.copyWith(
                    color: KitchenColors.whiteWarm,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 58),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: disableAnimations ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 720),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: child,
            ),
            child: Text(
              'La pizza\nrassemble\ntoujours',
              textAlign: TextAlign.center,
              style: KitchenTypography.signature.copyWith(
                color: KitchenColors.whiteWarm,
                fontSize: 42,
                shadows: [
                  Shadow(
                    color: KitchenColors.espresso.withValues(alpha: 0.44),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(flex: 3),
          const KitchenLoadingIndicator(),
          const SizedBox(height: 14),
          Text(
            'Chargement...',
            style: KitchenTypography.body.copyWith(
              color: KitchenColors.whiteWarm,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
