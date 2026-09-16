import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/features/account/screens/favorites_screen.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/providers/favorites_provider.dart';
import 'package:app_client/features/catalog/repositories/favorites_repository.dart';
import 'package:app_client/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFavoritesRepository extends Mock implements FavoritesRepository {}

void main() {
  testWidgets('affiche uniquement les produits favoris', (tester) async {
    final repo = _MockFavoritesRepository();
    when(() => repo.list()).thenAnswer((_) async => {2});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accessTokenProvider.overrideWith((ref) => 'fake-token'),
          favoritesRepositoryProvider.overrideWithValue(repo),
          allProductsProvider.overrideWith(
            (ref) async => const [
              Product(id: 1, name: 'Margherita', price: 10),
              Product(id: 2, name: 'Regina', price: 12),
            ],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: FavoritesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mes favoris'), findsOneWidget);
    expect(find.text('Regina'), findsOneWidget);
    expect(find.text('Margherita'), findsNothing);
  });
}
