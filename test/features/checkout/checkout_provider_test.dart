import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/features/cart/models/cart_item.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/repositories/catalog_repository.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/features/checkout/repositories/checkout_repository.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Mocks (mocktail — pas de build_runner requis, cohérent avec
// test/features/auth/auth_repository_test.dart)
// ──────────────────────────────────────────────────────────────────────────────

class MockCheckoutRepository extends Mock implements CheckoutRepository {}

class MockCatalogRepository extends Mock implements CatalogRepository {}

// ──────────────────────────────────────────────────────────────────────────────
// Fixtures
// ──────────────────────────────────────────────────────────────────────────────

const _product = Product(
  id: 1,
  name: 'Margherita',
  price: 10,
  categoryId: 1,
);

void main() {
  setUpAll(() {
    // Requis par mocktail pour `any(named: 'items')` : List<CartItem> n'est
    // pas un type "primitif" reconnu automatiquement.
    registerFallbackValue(<CartItem>[]);
  });

  late MockCheckoutRepository mockCheckoutRepo;
  late MockCatalogRepository mockCatalogRepo;
  late ProviderContainer container;

  setUp(() {
    mockCheckoutRepo = MockCheckoutRepository();
    mockCatalogRepo = MockCatalogRepository();
    container = ProviderContainer(
      overrides: [
        checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepo),
        catalogRepositoryProvider.overrideWithValue(mockCatalogRepo),
      ],
    );
    addTearDown(container.dispose);
    // checkoutProvider est `autoDispose` — on maintient un listener actif
    // pour que l'état survive entre les appels successifs d'un même test.
    container.listen(checkoutProvider, (_, __) {});
  });

  group('CheckoutNotifier', () {
    test('revalidateCart détecte un changement de prix', () async {
      container.read(cartProvider.notifier).addItem(_product);
      final freshProduct = _product.copyWith(price: 12);
      when(() => mockCatalogRepo.getProduct(1))
          .thenAnswer((_) async => freshProduct);

      await container.read(checkoutProvider.notifier).revalidateCart();

      final state = container.read(checkoutProvider);
      expect(state.priceAlerts, hasLength(1));
      expect(state.priceAlerts.first.oldPrice, 10);
      expect(state.priceAlerts.first.newPrice, 12);
      expect(state.currentStep, CheckoutStep.revalidation);
    });

    test('revalidateCart passe directement à deliveryMode si aucune alerte',
        () async {
      container.read(cartProvider.notifier).addItem(_product);
      when(() => mockCatalogRepo.getProduct(1))
          .thenAnswer((_) async => _product);

      await container.read(checkoutProvider.notifier).revalidateCart();

      final state = container.read(checkoutProvider);
      expect(state.priceAlerts, isEmpty);
      expect(state.currentStep, CheckoutStep.deliveryMode);
    });

    test('selectDeliveryMode pickup → skip étape adresse', () {
      final notifier = container.read(checkoutProvider.notifier);
      notifier.selectDeliveryMode(DeliveryMode.pickup);

      expect(container.read(checkoutProvider).currentStep, CheckoutStep.recap);
    });

    test('checkDeliveryAddress hors zone (422) → error non null, pas de crash',
        () async {
      when(
        () => mockCheckoutRepo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: any(named: 'displayAddress'),
        ),
      ).thenThrow(DeliveryZoneUnreachableException());

      await container.read(checkoutProvider.notifier).checkDeliveryAddress(
            displayAddress: '12 rue de la Paix',
            lat: 48.87,
            lng: 2.33,
          );

      final state = container.read(checkoutProvider);
      expect(state.error, isNotNull);
      verify(
        () => mockCheckoutRepo.checkDeliveryZone(
          lat: 48.87,
          lng: 2.33,
          displayAddress: '12 rue de la Paix',
        ),
      ).called(1);
      expect(state.deliveryInfo, isNull);
      expect(state.isLoading, false);
    });

    test(
        'createOrder réutilise la même idempotencyKey sur deux appels successifs',
        () async {
      container.read(cartProvider.notifier).addItem(_product);

      String? firstAttemptKey;
      when(
        () => mockCheckoutRepo.createOrder(
          items: any(named: 'items'),
          orderType: any(named: 'orderType'),
          idempotencyKey: any(named: 'idempotencyKey'),
          deliveryAddress: any(named: 'deliveryAddress'),
          deliveryZoneId: any(named: 'deliveryZoneId'),
          promoCode: any(named: 'promoCode'),
        ),
      ).thenAnswer((invocation) async {
        firstAttemptKey = invocation.namedArguments[#idempotencyKey] as String;
        // Simule un timeout réseau au premier essai.
        throw const NetworkException();
      });

      final firstResult =
          await container.read(checkoutProvider.notifier).createOrder();
      expect(firstResult, isNull);

      final keyAfterFirstAttempt =
          container.read(checkoutProvider).idempotencyKey;
      expect(keyAfterFirstAttempt, isNotNull);
      expect(keyAfterFirstAttempt, firstAttemptKey);

      String? secondAttemptKey;
      when(
        () => mockCheckoutRepo.createOrder(
          items: any(named: 'items'),
          orderType: any(named: 'orderType'),
          idempotencyKey: any(named: 'idempotencyKey'),
          deliveryAddress: any(named: 'deliveryAddress'),
          deliveryZoneId: any(named: 'deliveryZoneId'),
          promoCode: any(named: 'promoCode'),
        ),
      ).thenAnswer((invocation) async {
        secondAttemptKey = invocation.namedArguments[#idempotencyKey] as String;
        return 42;
      });

      final secondResult =
          await container.read(checkoutProvider.notifier).createOrder();

      expect(secondResult, 42);
      expect(secondAttemptKey, keyAfterFirstAttempt);
    });
  });
}
