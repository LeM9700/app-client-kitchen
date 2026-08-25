import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/analytics/analytics_reporter.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/features/cart/models/cart_item.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/cart/repositories/promo_repository.dart';
import 'package:app_client/features/cart/screens/cart_screen.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/repositories/catalog_repository.dart';
import 'package:app_client/features/catalog/screens/product_detail_screen.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/features/checkout/repositories/checkout_repository.dart';
import 'package:app_client/features/checkout/screens/checkout_screen.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/providers/order_provider.dart';
import 'package:app_client/features/orders/repositories/order_repository.dart';
import 'package:app_client/features/payment/providers/payment_provider.dart';
import 'package:app_client/features/payment/repositories/payment_repository.dart';
import 'package:app_client/features/payment/screens/payment_screen.dart';
import 'package:app_client/features/payment/services/stripe_payment_sheet_client.dart';
import 'package:app_client/features/tracking/models/order_status.dart';

class MockCatalogRepository extends Mock implements CatalogRepository {}

class MockCheckoutRepository extends Mock implements CheckoutRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}

class MockPaymentRepository extends Mock implements PaymentRepository {}

class MockStripePaymentSheetClient extends Mock
    implements StripePaymentSheetClient {}

class MockPromoRepository extends Mock implements PromoRepository {}

class _NoopAnalyticsReporter implements AnalyticsReporter {
  const _NoopAnalyticsReporter();

  @override
  void track(String eventName, Map<String, Object?> properties) {}
}

const _product = Product(
  id: 1,
  name: 'Margherita',
  price: 10,
);
const _paymentIntent = PaymentIntentResult(
  clientSecret: 'pi_42_secret_test',
  providerPaymentId: 'pi_42',
);

void main() {
  setUpAll(() {
    registerFallbackValue(<CartItem>[]);
  });

  late MockCatalogRepository mockCatalogRepo;
  late MockCheckoutRepository mockCheckoutRepo;
  late MockOrderRepository mockOrderRepo;
  late MockPaymentRepository mockPaymentRepo;
  late MockStripePaymentSheetClient mockStripeSheet;
  late MockPromoRepository mockPromoRepo;
  late ProviderContainer container;

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        accessTokenProvider.overrideWith((ref) => 'access-token'),
        catalogRepositoryProvider.overrideWithValue(mockCatalogRepo),
        productDetailProvider(_product.id)
            .overrideWith((ref) async => _product),
        checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepo),
        orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        paymentRepositoryProvider.overrideWithValue(mockPaymentRepo),
        stripePaymentSheetClientProvider.overrideWithValue(mockStripeSheet),
        promoRepositoryProvider.overrideWithValue(mockPromoRepo),
        analyticsReporterProvider.overrideWithValue(
          const _NoopAnalyticsReporter(),
        ),
      ],
    );
  }

  GoRouter buildCheckoutRouter() {
    return GoRouter(
      initialLocation: AppRoutes.cart,
      routes: [
        GoRoute(
          path: AppRoutes.cart,
          builder: (_, __) => const CartScreen(),
        ),
        GoRoute(
          path: AppRoutes.checkout,
          builder: (_, __) => const CheckoutScreen(),
          routes: [
            GoRoute(
              path: 'payment',
              builder: (_, state) {
                final rawOrderId = state.uri.queryParameters['orderId'];
                return PaymentScreen(orderId: int.parse(rawOrderId!));
              },
            ),
          ],
        ),
        GoRoute(
          path: '/orders/:id/tracking',
          builder: (_, state) => Scaffold(
            body: Center(
              child: Text('Tracking ${state.pathParameters['id']}'),
            ),
          ),
        ),
      ],
    );
  }

  setUp(() {
    mockCatalogRepo = MockCatalogRepository();
    mockCheckoutRepo = MockCheckoutRepository();
    mockOrderRepo = MockOrderRepository();
    mockPaymentRepo = MockPaymentRepository();
    mockStripeSheet = MockStripePaymentSheetClient();
    mockPromoRepo = MockPromoRepository();
    container = buildContainer();
    addTearDown(container.dispose);
  });

  group('Golden path UI: product -> cart -> checkout -> payment', () {
    testWidgets(
      'adds from the real CTA, creates a pickup order and clears cart after payment',
      (tester) async {
        when(() => mockCatalogRepo.getProduct(_product.id))
            .thenAnswer((_) async => _product);
        when(() => mockPromoRepo.previewLoyaltyPoints(any())).thenAnswer(
          (_) async => const LoyaltyPointsPreview(
            basePoints: 10,
            bonusPoints: 0,
            totalPoints: 10,
          ),
        );
        when(
          () => mockCheckoutRepo.createOrder(
            items: any(named: 'items'),
            orderType: any(named: 'orderType'),
            idempotencyKey: any(named: 'idempotencyKey'),
            deliveryAddress: any(named: 'deliveryAddress'),
            deliveryZoneId: any(named: 'deliveryZoneId'),
            promoCode: any(named: 'promoCode'),
          ),
        ).thenAnswer((_) async => 42);
        when(() => mockPaymentRepo.createPaymentIntent(42))
            .thenAnswer((_) async => _paymentIntent);
        when(
          () => mockPaymentRepo.confirmPayment(
            _paymentIntent.providerPaymentId,
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockStripeSheet.initPaymentSheet(
            clientSecret: any(named: 'clientSecret'),
            merchantDisplayName: any(named: 'merchantDisplayName'),
          ),
        ).thenAnswer((_) async {});
        when(() => mockStripeSheet.presentPaymentSheet())
            .thenAnswer((_) async {});

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: ProductDetailScreen(productId: '1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Ajouter au panier'),
        );
        await tester.pumpAndSettle();

        expect(container.read(cartProvider).totalQuantity, 1);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: buildCheckoutRouter()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(
          container.read(checkoutProvider).currentStep,
          CheckoutStep.deliveryMode,
        );

        await tester.tap(find.text('Retrait en boutique'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirmer la commande'));
        await tester.pumpAndSettle();

        expect(find.text('Paiement'), findsOneWidget);

        await tester.tap(find.text('Payer maintenant'));
        await tester.pumpAndSettle();

        expect(find.text('Tracking 42'), findsOneWidget);
        expect(container.read(cartProvider).isEmpty, true);
        verify(
          () => mockCheckoutRepo.createOrder(
            items: any(named: 'items'),
            orderType: 'pickup',
            idempotencyKey: any(named: 'idempotencyKey'),
            deliveryAddress: null,
            deliveryZoneId: null,
            promoCode: null,
          ),
        ).called(1);
        verify(() => mockPaymentRepo.createPaymentIntent(42)).called(1);
        verify(
          () => mockStripeSheet.initPaymentSheet(
            clientSecret: _paymentIntent.clientSecret,
            merchantDisplayName: any(named: 'merchantDisplayName'),
          ),
        ).called(1);
        verify(() => mockStripeSheet.presentPaymentSheet()).called(1);
        verify(
          () =>
              mockPaymentRepo.confirmPayment(_paymentIntent.providerPaymentId),
        ).called(1);
      },
    );
  });

  group('Golden path data: created order -> history', () {
    test('the created order is retrievable through orderDetailProvider',
        () async {
      const orderId = 42;
      const fakeOrder = Order(
        id: orderId,
        status: OrderStatusCode.confirmed,
        subtotal: 20,
        discountTotal: 0,
        deliveryFee: 0,
        total: 20,
      );
      when(() => mockOrderRepo.getOrderById(orderId))
          .thenAnswer((_) async => fakeOrder);

      final fetched = await container.read(orderDetailProvider(orderId).future);

      expect(fetched.id, orderId);
      expect(fetched.status, OrderStatusCode.confirmed);
      expect(fetched.total, 20);
    });

    test('the created order appears in orderHistoryProvider', () async {
      const orderId = 42;
      const fakeOrder = Order(
        id: orderId,
        status: OrderStatusCode.confirmed,
        subtotal: 20,
        discountTotal: 0,
        deliveryFee: 0,
        total: 20,
      );
      when(() => mockOrderRepo.getMyOrders(page: 1, pageSize: 20)).thenAnswer(
        (_) async => const OrderPage(
          items: [fakeOrder],
          total: 1,
          page: 1,
          pageSize: 20,
          pages: 1,
        ),
      );

      final notifier = container.read(orderHistoryProvider.notifier);
      await notifier.refresh();

      final state = container.read(orderHistoryProvider);
      expect(state.orders, hasLength(1));
      expect(state.orders.first.id, orderId);
      expect(state.error, isNull);
    });
  });
}
