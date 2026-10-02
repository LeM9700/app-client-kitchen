import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/providers/order_provider.dart';
import 'package:app_client/features/orders/repositories/order_repository.dart';
import 'package:app_client/features/tracking/models/order_status.dart';
import 'package:app_client/features/tracking/providers/tracking_provider.dart';
import 'package:app_client/features/tracking/screens/tracking_screen.dart';
import 'package:app_client/l10n/app_localizations.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _FakeTracking extends StateNotifier<TrackingState>
    implements TrackingNotifier {
  _FakeTracking(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Order _order({
  OrderType type = OrderType.delivery,
  OrderStatusCode status = OrderStatusCode.preparing,
}) =>
    Order(
      id: 7,
      orderType: type,
      status: status,
      subtotal: 22,
      discountTotal: 0,
      deliveryFee: 3,
      total: 25,
    );

DioException _httpError(int status) {
  final options = RequestOptions(path: '/orders/7/delivery-code');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(requestOptions: options, statusCode: status),
  );
}

void main() {
  group('OrderRepository.getDeliveryCode', () {
    late _MockApiClient client;
    late OrderRepository repository;

    setUp(() {
      client = _MockApiClient();
      repository = OrderRepository(client);
    });

    Response<Map<String, dynamic>> ok(Map<String, dynamic> data) => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: data,
        );

    test('renvoie le code a 4 chiffres', () async {
      when(() => client.get<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => ok({'code': '4821', 'length': 4}));

      expect(await repository.getDeliveryCode(7), '4821');
    });

    test('rien a afficher : 404 (autre client, retrait) et 409 (termine)',
        () async {
      for (final status in [404, 409]) {
        when(() => client.get<Map<String, dynamic>>(any()))
            .thenThrow(_httpError(status));
        expect(await repository.getDeliveryCode(7), isNull, reason: '$status');
      }
    });

    test('une vraie panne remonte, elle n\'est pas avalee', () async {
      when(() => client.get<Map<String, dynamic>>(any()))
          .thenThrow(_httpError(500));

      await expectLater(
        repository.getDeliveryCode(7),
        throwsA(isA<AppException>()),
      );
    });

    test('une reponse sans code donne null', () async {
      when(() => client.get<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => ok({'length': 4}));

      expect(await repository.getDeliveryCode(7), isNull);
    });
  });

  group('showsDeliveryCode', () {
    test('livraison confirmee ou en cours seulement', () {
      for (final status in [
        OrderStatusCode.confirmed,
        OrderStatusCode.preparing,
        OrderStatusCode.ready,
        OrderStatusCode.outForDelivery,
      ]) {
        expect(showsDeliveryCode(_order(status: status)), isTrue, reason: '$status');
      }
    });

    test('jamais pour un retrait, une commande non confirmee ou terminee', () {
      expect(showsDeliveryCode(_order(type: OrderType.pickup)), isFalse);
      expect(
        showsDeliveryCode(_order(status: OrderStatusCode.pending)),
        isFalse,
      );
      expect(
        showsDeliveryCode(_order(status: OrderStatusCode.delivered)),
        isFalse,
      );
      expect(
        showsDeliveryCode(_order(status: OrderStatusCode.cancelled)),
        isFalse,
      );
    });
  });

  group('ecran de suivi', () {
    Future<void> pump(
      WidgetTester tester,
      Order order, {
      String? code = '4821',
    }) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trackingProvider(7).overrideWith(
              (ref) => _FakeTracking(TrackingState(order: order, isConnected: true)),
            ),
            deliveryCodeProvider(7).overrideWith((ref) async => code),
          ],
          child: const MaterialApp(
            locale: Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TrackingScreen(orderId: 7),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('affiche le code a donner au livreur', (tester) async {
      await pump(tester, _order());

      expect(find.text('Votre code de remise'), findsOneWidget);
      expect(find.byKey(const ValueKey('delivery-code')), findsOneWidget);
      expect(find.text('4 8 2 1'), findsOneWidget);
      expect(find.textContaining('Donnez ce code au livreur'), findsOneWidget);
    });

    testWidgets('rien pour un retrait', (tester) async {
      await pump(tester, _order(type: OrderType.pickup));

      expect(find.byKey(const ValueKey('delivery-code')), findsNothing);
    });

    testWidgets('rien une fois la commande livree', (tester) async {
      await pump(tester, _order(status: OrderStatusCode.delivered));

      expect(find.byKey(const ValueKey('delivery-code')), findsNothing);
    });

    testWidgets('pas de code disponible : aucun cadre vide', (tester) async {
      await pump(tester, _order(), code: null);

      expect(find.text('Votre code de remise'), findsNothing);
    });
  });
}
