import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/features/auth/models/auth_tokens.dart';
import 'package:app_client/features/auth/models/user.dart';
import 'package:app_client/features/auth/providers/auth_provider.dart';
import 'package:app_client/features/auth/repositories/auth_repository.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/checkout/widgets/checkout_auth_gate.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  const testProduct = Product(id: 1, name: 'Margherita', price: 12);
  const testTokens = AuthTokens(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    sessionId: 1,
  );
  const testUser = User(
    id: 1,
    email: 'client@test.fr',
    fullName: 'Client Test',
    emailVerified: false,
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  /// Widget hôte reproduisant le comportement de `CheckoutScreen` (Plan 12) :
  /// tant que `accessTokenProvider` est null, affiche [CheckoutAuthGate] ;
  /// une fois authentifié, l'`AnimatedSwitcher` révèle un contenu de
  /// remplacement représentant les étapes checkout.
  Widget buildHarness() {
    return Consumer(
      builder: (context, ref, _) {
        final isAuthenticated = ref.watch(accessTokenProvider) != null;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isAuthenticated
              ? const Text('Étapes checkout', key: ValueKey('steps'))
              : const CheckoutAuthGate(key: ValueKey('auth')),
        );
      },
    );
  }

  Widget wrap(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ...overrides,
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('CheckoutAuthGate', () {
    testWidgets('affiche le récap du panier (articles + total)',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const CheckoutAuthGate(),
          overrides: [
            cartProvider.overrideWith(
              (ref) => CartNotifier()..addItem(testProduct, quantity: 2),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('2 articles · 24.00 €'), findsOneWidget);
      expect(
        find.text('Connectez-vous pour finaliser votre commande.'),
        findsOneWidget,
      );
    });

    testWidgets('connexion réussie → CheckoutAuthGate disparaît',
        (tester) async {
      when(
        () => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => testTokens);
      when(() => mockAuthRepository.getMe()).thenAnswer((_) async => testUser);

      await tester.pumpWidget(wrap(buildHarness()));
      await tester.pump();

      expect(find.byKey(const ValueKey('auth')), findsOneWidget);
      expect(find.byKey(const ValueKey('steps')), findsNothing);

      // Onglet "Je me connecte" est actif par défaut (index 0) : les deux
      // premiers TextFormField du widget appartiennent à _LoginTabContent
      // (il précède _RegisterTabContent dans les children du TabBarView).
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'client@test.fr');
      await tester.enterText(fields.at(1), 'password123');

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      verify(
        () => mockAuthRepository.login(
          email: 'client@test.fr',
          password: 'password123',
        ),
      ).called(1);

      expect(find.byKey(const ValueKey('steps')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth')), findsNothing);
    });

    testWidgets(
        "erreur de connexion → message d'erreur inline, pas de navigation",
        (tester) async {
      when(
        () => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Email ou mot de passe incorrect.'));

      await tester.pumpWidget(wrap(buildHarness()));
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'client@test.fr');
      await tester.enterText(fields.at(1), 'wrong-password');

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
      // Toujours sur le gate — aucune navigation, le checkout n'a pas repris.
      expect(find.byKey(const ValueKey('auth')), findsOneWidget);
      expect(find.byKey(const ValueKey('steps')), findsNothing);
    });
  });
}
