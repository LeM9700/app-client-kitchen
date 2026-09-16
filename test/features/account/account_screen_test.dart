import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/features/account/screens/account_screen.dart';
import 'package:app_client/features/account/screens/favorites_screen.dart';
import 'package:app_client/features/account/screens/settings_screen.dart';
import 'package:app_client/features/auth/models/user.dart';
import 'package:app_client/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _user = User(
  id: 1,
  email: 'camille@example.com',
  fullName: 'Camille Duroc',
  phone: '0600000000',
  emailVerified: true,
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: AppRoutes.account,
      routes: [
        GoRoute(
          path: AppRoutes.account,
          builder: (_, __) => const AccountScreen(),
          routes: [
            GoRoute(
              path: 'settings',
              builder: (_, __) => const SettingsScreen(),
            ),
            GoRoute(
              path: 'profile/edit',
              builder: (_, __) => const Scaffold(body: Text('PROFILE_ROUTE')),
            ),
            GoRoute(
              path: 'loyalty',
              builder: (_, __) => const Scaffold(body: Text('LOYALTY_ROUTE')),
            ),
            GoRoute(
              path: 'favorites',
              builder: (_, __) => const FavoritesScreen(),
            ),
            GoRoute(
              path: 'change-password',
              builder: (_, __) => const Scaffold(body: Text('PASSWORD_ROUTE')),
            ),
            GoRoute(
              path: 'sessions',
              builder: (_, __) => const Scaffold(body: Text('SESSIONS_ROUTE')),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.orders,
          builder: (_, __) => const Scaffold(body: Text('ORDERS_ROUTE')),
        ),
        GoRoute(
          path: AppRoutes.privacy,
          builder: (_, __) => const Scaffold(body: Text('PRIVACY_ROUTE')),
        ),
        GoRoute(
          path: AppRoutes.generalConditions,
          builder: (_, __) => const Scaffold(body: Text('CONDITIONS_ROUTE')),
        ),
        GoRoute(
          path: AppRoutes.cgv,
          builder: (_, __) => const Scaffold(body: Text('CGV_ROUTE')),
        ),
        GoRoute(
          path: AppRoutes.cgu,
          builder: (_, __) => const Scaffold(body: Text('CGU_ROUTE')),
        ),
      ],
    );
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [
        accessTokenProvider.overrideWith((ref) => 'access-token'),
        currentUserProvider.overrideWith((ref) => _user),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('Account affiche les données utilisateur réelles',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Camille Duroc'), findsOneWidget);
    expect(find.text('camille@example.com'), findsOneWidget);
    expect(find.text('0600000000'), findsOneWidget);
    expect(find.text('Mes favoris'), findsOneWidget);
    expect(find.text('Malik'), findsNothing);
    expect(find.text('malik@example.com'), findsNothing);
  });

  testWidgets('Settings n’affiche pas les fonctionnalités non supportées',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final settingsTile = find.text('Plus / Paramètres');
    await tester.ensureVisible(settingsTile);
    await tester.pumpAndSettle();
    await tester.tap(settingsTile);
    await tester.pumpAndSettle();

    expect(find.text('Plus'), findsOneWidget);
    expect(find.text('Notifications'), findsNothing);
    expect(find.text('Langue'), findsNothing);
    expect(find.text('Apparence'), findsNothing);
    expect(find.text('Moyens de paiement'), findsNothing);
    expect(find.text('Mes adresses'), findsNothing);
    expect(find.text('FAQ'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer mon compte'), findsOneWidget);
  });
}
