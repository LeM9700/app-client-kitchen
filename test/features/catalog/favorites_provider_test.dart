import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/features/catalog/providers/favorites_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  group('favoritesProvider', () {
    test('vide par défaut', () {
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('toggle() ajoute un produit absent', () {
      container.read(favoritesProvider.notifier).toggle(1);

      expect(container.read(favoritesProvider), {1});
    });

    test('toggle() retire un produit déjà favori', () {
      final notifier = container.read(favoritesProvider.notifier);
      notifier.toggle(1);

      notifier.toggle(1);

      expect(container.read(favoritesProvider), isEmpty);
    });

    test('isFavorite() reflète le state courant', () {
      final notifier = container.read(favoritesProvider.notifier);

      expect(notifier.isFavorite(1), false);

      notifier.toggle(1);

      expect(notifier.isFavorite(1), true);
    });
  });
}
