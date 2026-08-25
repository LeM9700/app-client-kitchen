import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/widgets/scaffold_with_nav.dart';
import 'package:app_client/features/account/screens/account_screen.dart';
import 'package:app_client/features/account/screens/change_password_screen.dart';
import 'package:app_client/features/account/screens/profile_edit_screen.dart';
import 'package:app_client/features/account/screens/sessions_screen.dart';
import 'package:app_client/features/auth/screens/login_screen.dart';
import 'package:app_client/features/auth/screens/register_screen.dart';
import 'package:app_client/features/auth/screens/forgot_password_screen.dart';
import 'package:app_client/features/cart/screens/cart_screen.dart';
import 'package:app_client/features/checkout/screens/checkout_screen.dart';
import 'package:app_client/features/catalog/screens/home_screen.dart';
import 'package:app_client/features/catalog/screens/product_detail_screen.dart';
import 'package:app_client/features/catalog/screens/search_screen.dart';
import 'package:app_client/features/legal/screens/legal_document_screen.dart';
import 'package:app_client/features/loyalty/screens/loyalty_screen.dart';
import 'package:app_client/features/orders/screens/order_detail_screen.dart';
import 'package:app_client/features/orders/screens/order_history_screen.dart';
import 'package:app_client/features/payment/screens/payment_screen.dart';
import 'package:app_client/features/promotions/screens/promotions_screen.dart';
import 'package:app_client/features/splash/screens/splash_screen.dart';
import 'package:app_client/features/tracking/screens/tracking_screen.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Bridge Riverpod → ChangeNotifier (requis par GoRouter.refreshListenable)
// ──────────────────────────────────────────────────────────────────────────────

/// Écoute [accessTokenProvider] et notifie GoRouter à chaque changement.
///
/// GoRouter n'écoute que des [Listenable] (ChangeNotifier) — ce bridge
/// traduit les changements Riverpod en notifications pour le router.
/// Résultat : le `redirect` est réévalué automatiquement à chaque
/// connexion / déconnexion sans navigation impérative.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    // Écouter les changements du token depuis le premier build du provider.
    _ref.listen<String?>(accessTokenProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

// ──────────────────────────────────────────────────────────────────────────────
// Provider du router
// ──────────────────────────────────────────────────────────────────────────────

/// Instance GoRouter singleton injectée par Riverpod.
///
/// Jamais d'instanciation directe de GoRouter dans l'arbre de widgets —
/// toujours via `ref.watch(routerProvider)`.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    debugLogDiagnostics: false, // Passer à true pour déboguer la navigation

    // ──────────────────────────────────────────────────────────────────────
    // Auth guard global
    // Catalogue = 100% public (maximize la rétention avant auth).
    // Auth requise uniquement à partir du checkout.
    // ──────────────────────────────────────────────────────────────────────
    redirect: (context, state) {
      final isAuthenticated = ref.read(accessTokenProvider) != null;
      final location = state.uri.toString();

      // Chemins protégés — auth obligatoire
      const protectedPrefixes = [
        AppRoutes.checkout,
        AppRoutes.payment,
        AppRoutes.orders,
        AppRoutes.account,
        AppRoutes.loyalty,
      ];

      final requiresAuth = protectedPrefixes.any((p) => location.startsWith(p));

      if (requiresAuth && !isAuthenticated) {
        // Préserver la destination pour redirection post-login.
        return '${AppRoutes.login}?redirect=${Uri.encodeComponent(location)}';
      }

      // Rediriger depuis les écrans auth si déjà connecté.
      if (isAuthenticated && location.startsWith('/auth/')) {
        return AppRoutes.home;
      }

      return null;
    },

    routes: [
      // ── Splash ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Auth (hors shell) ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (_, state) => LoginScreen(
          redirectTo: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, state) => RegisterScreen(
          redirectTo: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (_, __) => const LegalDocumentScreen(
          type: LegalDocumentType.privacy,
        ),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (_, __) => const LegalDocumentScreen(
          type: LegalDocumentType.generalConditions,
        ),
      ),
      GoRoute(
        path: AppRoutes.generalConditions,
        builder: (_, __) => const LegalDocumentScreen(
          type: LegalDocumentType.generalConditions,
        ),
      ),
      GoRoute(
        path: AppRoutes.cgv,
        builder: (_, __) => const LegalDocumentScreen(
          type: LegalDocumentType.cgv,
        ),
      ),
      GoRoute(
        path: AppRoutes.cgu,
        builder: (_, __) => const LegalDocumentScreen(
          type: LegalDocumentType.cgu,
        ),
      ),

      // ── Shell avec bottom navigation ─────────────────────────────────────
      // StatefulShellRoute.indexedStack maintient l'état de chaque branche
      // indépendamment — scroll position, navigation imbriquée, etc.
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ScaffoldWithNav(shell: shell),
        branches: [
          // Branche 0 : Catalogue
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'product/:id',
                    builder: (_, state) => ProductDetailScreen(
                      productId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'search',
                    builder: (_, __) => const SearchScreen(),
                  ),
                  GoRoute(
                    path: 'promotions',
                    builder: (_, __) => const PromotionsScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Branche 1 : Panier & Checkout
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (_, __) => const CartScreen(),
              ),
            ],
          ),

          // Branche 2 : Commandes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (_, __) => const OrderHistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) {
                      final rawId = state.pathParameters['id'];
                      final orderId =
                          rawId != null ? int.tryParse(rawId) : null;
                      if (orderId == null) {
                        return const _RouteMessageScreen(
                          title: 'Commande introuvable',
                          message:
                              'Verifiez le lien ou retournez a vos commandes.',
                          actionLabel: 'Mes commandes',
                          actionRoute: AppRoutes.orders,
                        );
                      }
                      return OrderDetailScreen(orderId: orderId);
                    },
                    routes: [
                      GoRoute(
                        path: 'tracking',
                        builder: (_, state) {
                          final rawId = state.pathParameters['id'];
                          final orderId =
                              rawId != null ? int.tryParse(rawId) : null;
                          if (orderId == null) {
                            return const _RouteMessageScreen(
                              title: 'Commande introuvable',
                              message:
                                  'Verifiez le lien ou retournez a vos commandes.',
                              actionLabel: 'Mes commandes',
                              actionRoute: AppRoutes.orders,
                            );
                          }
                          return TrackingScreen(orderId: orderId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Branche 3 : Compte
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                builder: (_, __) => const AccountScreen(),
                routes: [
                  GoRoute(
                    path: 'loyalty',
                    builder: (_, __) => const LoyaltyScreen(),
                  ),
                  GoRoute(
                    path: 'profile/edit',
                    builder: (_, __) => const ProfileEditScreen(),
                  ),
                  GoRoute(
                    path: 'change-password',
                    builder: (_, __) => const ChangePasswordScreen(),
                  ),
                  GoRoute(
                    path: 'sessions',
                    builder: (_, __) => const SessionsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── Checkout (hors shell — flow plein écran) ─────────────────────────
      GoRoute(
        path: AppRoutes.checkout,
        builder: (_, __) => const CheckoutScreen(),
        routes: [
          GoRoute(
            path: 'payment',
            // orderId arrive en query param depuis step_recap.dart
            // (`context.push('${AppRoutes.payment}?orderId=$orderId')`, Plan 11).
            builder: (_, state) {
              final rawOrderId = state.uri.queryParameters['orderId'];
              final orderId =
                  rawOrderId != null ? int.tryParse(rawOrderId) : null;
              if (orderId == null) {
                return const _RouteMessageScreen(
                  title: 'Commande introuvable',
                  message: 'Le lien de paiement ne contient pas de commande.',
                  actionLabel: 'Retour au panier',
                  actionRoute: AppRoutes.cart,
                );
              }
              return PaymentScreen(orderId: orderId);
            },
          ),
          // Route de compatibilite: le flux normal navigue directement vers le
          // suivi depuis PaymentScreen, mais un deep link ancien reste lisible.
          GoRoute(
            path: 'success',
            builder: (_, __) => const _RouteMessageScreen(
              title: 'Commande confirmée',
              message:
                  'Votre paiement est confirmé. Retrouvez le suivi depuis vos commandes.',
              actionLabel: 'Mes commandes',
              actionRoute: AppRoutes.orders,
            ),
          ),
        ],
      ),
    ],

    errorBuilder: (_, state) => Scaffold(
      appBar: AppBar(title: const Text('Erreur')),
      body: Center(
        child: Text(
          'Page introuvable\n${state.error}',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
});

// ──────────────────────────────────────────────────────────────────────────────
// Ecran de message pour les routes de compatibilite ou les parametres invalides.
// ──────────────────────────────────────────────────────────────────────────────

class _RouteMessageScreen extends StatelessWidget {
  const _RouteMessageScreen({
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionRoute,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final String? actionRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (actionLabel != null && actionRoute != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(actionRoute!),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
