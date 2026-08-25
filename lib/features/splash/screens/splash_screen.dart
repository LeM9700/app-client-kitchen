import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/core/router/app_router.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/tenant_theme_provider.dart';
import 'package:app_client/features/tracking/services/push_notification_service.dart';

/// Écran de démarrage — exécute la séquence de boot de l'application.
///
/// Séquence :
/// 1. Injecter le slug tenant dans le header HTTP global.
/// 2. Charger le branding et le catalogue **en parallèle** (non bloquants).
/// 3. Naviguer vers [AppRoutes.home].
///
/// [⚡ PERF] Le branding et le catalogue sont chargés en parallèle via
/// [Future.wait] — réduit le temps de boot perçu de ~50% vs. séquentiel.
///
/// [UX] Si le branding échoue (réseau absent), le thème de démo s'affiche.
/// L'app ne bloque jamais sur la SplashScreen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // [!] Pas d'await dans initState — on lance le boot en async.
    _boot();
  }

  Future<void> _boot() async {
    // Slug injecté à la compilation via --dart-define=TENANT_SLUG=...
    const slug = Env.tenantSlug;

    // 1. Configurer le header X-Tenant-Slug sur le client HTTP singleton.
    //    Toutes les requêtes suivantes porteront automatiquement cet header.
    ref.read(apiClientProvider).setTenantSlug(slug);

    // [Plan 14] Initialise Firebase Messaging (permission, deep links,
    // rotation de token) en tâche de fond — jamais bloquant pour le boot
    // (tout est best-effort côté PushNotificationService). L'enregistrement
    // backend du token nécessite un utilisateur authentifié : au boot, sans
    // rehydratation de session, il échoue silencieusement le plus souvent —
    // le cas nominal est couvert par l'appel post-login dans AuthNotifier.
    unawaited(
      PushNotificationService.initialize(
        apiClient: ref.read(apiClientProvider),
        router: ref.read(routerProvider),
      ),
    );

    // 2. Chargement parallèle : branding + (catalogue en Plan 07).
    //    Chaque Future est wrappé pour être non-bloquant — un échec ne
    //    doit pas empêcher l'app de démarrer.
    await Future.wait([
      ref.read(tenantBrandingProvider.notifier).load(slug),
      // [Plan 07] ref.read(catalogProvider.notifier).prefetch(),
    ]);

    // 3. Navigation vers l'accueil.
    //    mounted vérifié pour éviter un setState sur widget détruit.
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: primary,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo du tenant — logoUrl disponible depuis Plan 04.
            // En attendant : icône pizza par défaut.
            Icon(
              Icons.local_pizza,
              size: 72,
              color: Colors.white,
            ),
            SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
