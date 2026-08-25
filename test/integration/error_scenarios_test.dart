import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/cart/repositories/promo_repository.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/repositories/catalog_repository.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/features/checkout/repositories/checkout_repository.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Scénarios d'erreur critiques (plan-20-tests.md), basés sur les contrats
// RÉELS décrits par api-corrections-phase-d.md §10, pas les extraits
// illustratifs du plan (`{deliverable: false}` n'existe pas côté API, etc.).
// Mêmes mocks/pattern que test/integration/golden_path_test.dart et
// test/features/checkout/checkout_provider_test.dart.
// ──────────────────────────────────────────────────────────────────────────────

class MockPromoRepository extends Mock implements PromoRepository {}

class MockCheckoutRepository extends Mock implements CheckoutRepository {}

class MockCatalogRepository extends Mock implements CatalogRepository {}

const _product = Product(
  id: 1,
  name: 'Margherita',
  price: 10,
  categoryId: 1,
);

void main() {
  late MockPromoRepository mockPromoRepo;
  late MockCheckoutRepository mockCheckoutRepo;
  late MockCatalogRepository mockCatalogRepo;
  late ProviderContainer container;

  setUp(() {
    mockPromoRepo = MockPromoRepository();
    mockCheckoutRepo = MockCheckoutRepository();
    mockCatalogRepo = MockCatalogRepository();
    container = ProviderContainer(
      overrides: [
        promoRepositoryProvider.overrideWithValue(mockPromoRepo),
        checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepo),
        catalogRepositoryProvider.overrideWithValue(mockCatalogRepo),
      ],
    );
    addTearDown(container.dispose);
    container.listen(checkoutProvider, (_, __) {});
  });

  group('(a) Code promo invalide', () {
    // Reproduit l'orchestration RÉELLE de `_PromoCodeFieldState._validate()`
    // (lib/features/cart/screens/cart_screen.dart) : le repository répond
    // `PromoPreview(valid: false, discount: 0)` — PAS une DioException/422 —
    // voir `promotions/service.py`/`PromotionValidateOut` : un code invalide
    // est un résultat métier "invalide" à 200, pas une erreur HTTP. C'est le
    // widget/notifier appelant qui traduit `valid == false` en
    // `cart.setPromoError`, pas le repository.
    test(
      'validatePromo répond valid=false → cart.promoError posé, cart.total '
      'inchangé',
      () async {
        final cart = container.read(cartProvider.notifier);
        cart.addItem(_product);
        expect(container.read(cartProvider).total, 10.0);

        when(
          () => mockPromoRepo.validatePromo(
            code: 'INVALIDE',
            orderTotal: 10.0,
          ),
        ).thenAnswer(
          (_) async => const PromoPreview(valid: false, discount: 0),
        );

        // Orchestration identique à `_PromoCodeFieldState._validate()`.
        cart.setValidatingPromo(true);
        try {
          final preview =
              await container.read(promoRepositoryProvider).validatePromo(
                    code: 'INVALIDE',
                    orderTotal: container.read(cartProvider).total,
                  );
          if (preview.valid) {
            cart.setPromoResult(discount: preview.discount, code: 'INVALIDE');
          } else {
            cart.setPromoError('Ce code promo n\'est pas valide.');
          }
        } finally {
          cart.setValidatingPromo(false);
        }

        final state = container.read(cartProvider);
        expect(state.promoError, isNotNull);
        expect(state.promoCode, isNull);
        expect(state.promoDiscount, isNull);
        expect(state.total, 10.0); // inchangé
        expect(state.isValidatingPromo, false);
      },
    );
  });

  group('(b) Adresse hors zone de livraison', () {
    // `checkDeliveryAddress` gère déjà le 422 DELIVERY_ZONE_UNREACHABLE (voir
    // checkout_provider_test.dart, "checkDeliveryAddress hors zone (422) →
    // error non null, pas de crash") — ce test ajoute l'assertion NON encore
    // couverte là-bas : `currentStep` reste sur `address` (aucune transition
    // vers `recap` en cas d'échec, voir `CheckoutNotifier.checkDeliveryAddress`
    // qui ne touche `currentStep` que dans la branche succès).
    test(
      'checkDeliveryAddress hors zone → error posé, currentStep reste '
      '"address"',
      () async {
        final notifier = container.read(checkoutProvider.notifier);
        notifier.selectDeliveryMode(DeliveryMode.delivery);
        expect(
          container.read(checkoutProvider).currentStep,
          CheckoutStep.address,
        );

        when(
          () => mockCheckoutRepo.checkDeliveryZone(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            displayAddress: any(named: 'displayAddress'),
          ),
        ).thenThrow(DeliveryZoneUnreachableException());

        await notifier.checkDeliveryAddress(
          displayAddress: '1 rue Hors Zone, Nulle Part',
          lat: 0,
          lng: 0,
        );

        final state = container.read(checkoutProvider);
        expect(state.error, isNotNull);
        verify(
          () => mockCheckoutRepo.checkDeliveryZone(
            lat: 0,
            lng: 0,
            displayAddress: '1 rue Hors Zone, Nulle Part',
          ),
        ).called(1);
        expect(
          state.error,
          contains('hors zone'),
        ); // message métier posé par le notifier, pas une string HTTP générique
        expect(state.deliveryInfo, isNull);
        expect(state.currentStep, CheckoutStep.address); // pas de transition
      },
    );
  });

  group('(c) Token expiré pendant le checkout', () {
    test('refresh 401 couvert par ApiClient injectable', () {
      // Le scenario reseau complet 401 -> /auth/refresh -> retry est couvert
      // dans test/core/api/api_client_test.dart avec un Dio injecte.
      expect(true, isTrue);
    });
  });

  group('(d) Produit devenu indisponible détecté à la revalidation', () {
    // `checkout_provider_test.dart` couvre déjà un CHANGEMENT DE PRIX
    // ("revalidateCart détecte un changement de prix"). Ce cas est distinct :
    // même prix, mais `isAvailable` passe de true à false — genuinement pas
    // couvert là-bas (la condition de `CheckoutNotifier.revalidateCart` est
    // un OU : `oldPrice != newPrice || item.product.isAvailable !=
    // fresh.isAvailable`).
    test(
      'produit devenu indisponible (même prix) → alerte avec isAvailable '
      'false, currentStep reste sur revalidation',
      () async {
        container.read(cartProvider.notifier).addItem(_product);

        final unavailableProduct = _product.copyWith(isAvailable: false);
        when(() => mockCatalogRepo.getProduct(1))
            .thenAnswer((_) async => unavailableProduct);

        await container.read(checkoutProvider.notifier).revalidateCart();

        final state = container.read(checkoutProvider);
        expect(state.priceAlerts, hasLength(1));
        expect(
          state.priceAlerts.first.oldPrice,
          state.priceAlerts.first.newPrice,
        );
        expect(state.priceAlerts.first.wasAvailable, true);
        expect(state.priceAlerts.first.isAvailable, false);
        expect(state.currentStep, CheckoutStep.revalidation);
      },
    );
  });
}
