import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/repositories/catalog_repository.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/models/reorder_result.dart';
import 'package:app_client/features/orders/providers/order_provider.dart';
import 'package:app_client/features/orders/repositories/order_repository.dart';
import 'package:app_client/features/tracking/models/order_status.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Mocks (mocktail — cohérent avec test/features/checkout/checkout_provider_test.dart)
// ──────────────────────────────────────────────────────────────────────────────

class MockOrderRepository extends Mock implements OrderRepository {}

class MockCatalogRepository extends Mock implements CatalogRepository {}

// ──────────────────────────────────────────────────────────────────────────────
// Fixtures
// ──────────────────────────────────────────────────────────────────────────────

Order _order(int id) => Order(
      id: id,
      status: OrderStatusCode.delivered,
      subtotal: 20,
      discountTotal: 0,
      deliveryFee: 0,
      total: 20,
    );

const _product = Product(
  id: 7,
  name: 'Margherita',
  price: 10,
  categoryId: 1,
);

void main() {
  late MockOrderRepository mockOrderRepo;
  late MockCatalogRepository mockCatalogRepo;
  late ProviderContainer container;

  setUp(() {
    mockOrderRepo = MockOrderRepository();
    mockCatalogRepo = MockCatalogRepository();
    container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        catalogRepositoryProvider.overrideWithValue(mockCatalogRepo),
      ],
    );
    addTearDown(container.dispose);
  });

  group('OrderHistoryNotifier — pagination OFFSET (page/page_size)', () {
    test('refresh() charge la première page', () async {
      when(() => mockOrderRepo.getMyOrders(page: 1, pageSize: 20)).thenAnswer(
        (_) async => OrderPage(
          items: [_order(1), _order(2)],
          total: 5,
          page: 1,
          pageSize: 20,
          pages: 1,
        ),
      );

      // orderHistoryProvider est `autoDispose` et déclenche déjà refresh()
      // dans son create() — le mock doit être posé AVANT le premier
      // read/listen, sinon ce refresh() automatique s'exécute contre un
      // mock non stubbé. Le `listen` maintient ensuite l'état vivant entre
      // les appels successifs de ce test (même précaution que
      // test/features/checkout/checkout_provider_test.dart).
      container.listen(orderHistoryProvider, (_, __) {});
      final notifier = container.read(orderHistoryProvider.notifier);
      await notifier.refresh();

      final state = container.read(orderHistoryProvider);
      expect(state.orders, hasLength(2));
      expect(state.total, 5);
      expect(state.hasMore, false);
    });

    test('loadMore() accumule la page suivante sans écraser la précédente',
        () async {
      when(() => mockOrderRepo.getMyOrders(page: 1, pageSize: 20)).thenAnswer(
        (_) async => OrderPage(
          items: [_order(1)],
          total: 2,
          page: 1,
          pageSize: 20,
          pages: 2,
        ),
      );
      when(() => mockOrderRepo.getMyOrders(page: 2, pageSize: 20)).thenAnswer(
        (_) async => OrderPage(
          items: [_order(2)],
          total: 2,
          page: 2,
          pageSize: 20,
          pages: 2,
        ),
      );

      container.listen(orderHistoryProvider, (_, __) {});
      final notifier = container.read(orderHistoryProvider.notifier);
      await notifier.refresh();
      expect(container.read(orderHistoryProvider).hasMore, true);

      await notifier.loadMore();

      final state = container.read(orderHistoryProvider);
      expect(state.orders.map((o) => o.id), [1, 2]);
      expect(state.hasMore, false);
    });
  });

  group('ReorderNotifier — POST /orders/{id}/reorder', () {
    test('reorder() ajoute les items disponibles au panier', () async {
      when(() => mockOrderRepo.reorder(1)).thenAnswer(
        (_) async => const ReorderResult(
          sourceOrderId: 1,
          items: [
            ReorderItem(productId: 7, quantity: 2, available: true),
          ],
        ),
      );
      when(() => mockCatalogRepo.getProduct(7))
          .thenAnswer((_) async => _product);

      final outcome = await container.read(reorderProvider).reorder(1);

      expect(outcome.addedCount, 1);
      expect(outcome.unavailableItems, isEmpty);
      expect(container.read(cartProvider).totalQuantity, 2);
    });

    test(
        'reorder() remonte les items indisponibles sans les ajouter au panier '
        'ni faire échouer les autres', () async {
      when(() => mockOrderRepo.reorder(1)).thenAnswer(
        (_) async => const ReorderResult(
          sourceOrderId: 1,
          items: [
            ReorderItem(productId: 7, quantity: 1, available: true),
          ],
          unavailableItems: [
            ReorderItem(
              productId: 99,
              quantity: 1,
              available: false,
              warning: 'Produit retiré du catalogue.',
            ),
          ],
        ),
      );
      when(() => mockCatalogRepo.getProduct(7))
          .thenAnswer((_) async => _product);

      final outcome = await container.read(reorderProvider).reorder(1);

      expect(outcome.addedCount, 1);
      expect(outcome.unavailableItems, hasLength(1));
      expect(outcome.unavailableItems.first.productId, 99);
      expect(container.read(cartProvider).totalQuantity, 1);
    });

    test(
        'reorder() traite un produit disponible côté serveur mais introuvable '
        'au refetch catalogue comme indisponible (jamais une suppression '
        'silencieuse)', () async {
      when(() => mockOrderRepo.reorder(1)).thenAnswer(
        (_) async => const ReorderResult(
          sourceOrderId: 1,
          items: [
            ReorderItem(productId: 404, quantity: 1, available: true),
          ],
        ),
      );
      when(() => mockCatalogRepo.getProduct(404))
          .thenThrow(const NotFoundException());

      final outcome = await container.read(reorderProvider).reorder(1);

      expect(outcome.addedCount, 0);
      expect(outcome.unavailableItems, hasLength(1));
      expect(outcome.unavailableItems.first.productId, 404);
      expect(container.read(cartProvider).isEmpty, true);
    });
  });
}
