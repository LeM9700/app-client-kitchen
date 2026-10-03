import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/features/checkout/screens/steps/step_address.dart'
    show addressMapTileLayerProvider;
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/providers/order_provider.dart';
import 'package:app_client/features/orders/repositories/order_repository.dart';
import 'package:app_client/features/tracking/models/driver_location.dart';
import 'package:app_client/features/tracking/models/order_status.dart';
import 'package:app_client/features/tracking/providers/tracking_provider.dart';
import 'package:app_client/features/tracking/screens/tracking_screen.dart';
import 'package:app_client/l10n/app_localizations.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockOrderRepository extends Mock implements OrderRepository {}

class _FakeTracking extends StateNotifier<TrackingState>
    implements TrackingNotifier {
  _FakeTracking(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Order _order({
  OrderType type = OrderType.delivery,
  OrderStatusCode status = OrderStatusCode.outForDelivery,
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
  final options = RequestOptions(path: '/orders/7/driver-location');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(requestOptions: options, statusCode: status),
  );
}

const _json = {
  'available': true,
  'driver_first_name': 'Marc',
  'lat': 48.86,
  'lng': 2.35,
  'destination_lat': 48.87,
  'destination_lng': 2.36,
  'age_seconds': 4,
  'stale': false,
  'eta_minutes': 6,
  'arrived': false,
};

void main() {
  group('DriverLocation', () {
    test('se lit depuis l\'API', () {
      final location = DriverLocation.fromJson(_json);
      expect(location.hasPosition, isTrue);
      expect(location.hasDestination, isTrue);
      expect(location.etaMinutes, 6);
      expect(location.driverFirstName, 'Marc');
      expect(location.stale, isFalse);
    });

    test('sans position : disponible=false, rien a dessiner', () {
      final location = DriverLocation.fromJson({
        'available': false,
        'driver_first_name': 'Marc',
        'destination_lat': 48.87,
        'destination_lng': 2.36,
      });
      expect(location.hasPosition, isFalse);
      expect(location.hasDestination, isTrue);
    });
  });

  group('OrderRepository.getDriverLocation', () {
    late _MockApiClient client;
    late OrderRepository repository;

    setUp(() {
      client = _MockApiClient();
      repository = OrderRepository(client);
    });

    test('renvoie la position', () async {
      when(() => client.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: Map<String, dynamic>.from(_json),
        ),
      );
      final location = await repository.getDriverLocation(7);
      expect(location!.lat, 48.86);
    });

    test('404 (commande d\'un autre) et 409 (pas en route) : rien a afficher', () async {
      for (final status in [404, 409]) {
        when(() => client.get<Map<String, dynamic>>(any())).thenThrow(_httpError(status));
        expect(await repository.getDriverLocation(7), isNull, reason: '$status');
      }
    });

    test('une vraie panne remonte', () async {
      when(() => client.get<Map<String, dynamic>>(any())).thenThrow(_httpError(500));
      await expectLater(repository.getDriverLocation(7), throwsA(isA<AppException>()));
    });
  });

  group('driverLocationProvider', () {
    testWidgets('une panne reseau garde la derniere position connue, puis reprend',
        (tester) async {
      final repo = _MockOrderRepository();
      var calls = 0;
      when(() => repo.getDriverLocation(7)).thenAnswer((_) async {
        calls++;
        if (calls == 2) throw Exception('reseau coupe');
        return DriverLocation.fromJson({..._json, 'eta_minutes': 10 - calls});
      });
      final container = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(repo)],
      );
      final values = <DriverLocation?>[];
      container.listen(
        driverLocationProvider(7),
        (_, next) => values.add(next.valueOrNull),
        fireImmediately: true,
      );

      await tester.pump();
      expect(values.last?.etaMinutes, 9); // 1er tour

      await tester.pump(driverLocationPollInterval);
      expect(calls, 2);
      expect(values.last?.etaMinutes, 9); // panne : la position precedente reste affichee

      await tester.pump(driverLocationPollInterval);
      expect(calls, 3);
      expect(values.last?.etaMinutes, 7); // le suivi reprend tout seul

      container.dispose();
      final before = calls;
      await tester.pump(driverLocationPollInterval * 3);
      expect(calls, before); // ecran ferme : on arrete d'interroger le serveur
    });

    test('l intervalle respecte la limite du serveur (30 requetes par minute)', () {
      expect(driverLocationPollInterval, const Duration(seconds: 8));
      expect(60 / driverLocationPollInterval.inSeconds, lessThan(30));
    });
  });

  group('showsDriverMap', () {
    test('seulement pendant la livraison', () {
      expect(showsDriverMap(_order()), isTrue);
      for (final status in [
        OrderStatusCode.pending,
        OrderStatusCode.confirmed,
        OrderStatusCode.preparing,
        OrderStatusCode.ready,
        OrderStatusCode.delivered,
        OrderStatusCode.cancelled,
      ]) {
        expect(showsDriverMap(_order(status: status)), isFalse, reason: '$status');
      }
      expect(showsDriverMap(_order(type: OrderType.pickup)), isFalse);
    });
  });

  group('ecran de suivi : carte du livreur', () {
    Future<void> pump(
      WidgetTester tester,
      Order order,
      DriverLocation? location,
    ) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trackingProvider(7).overrideWith(
              (ref) => _FakeTracking(TrackingState(order: order, isConnected: true)),
            ),
            deliveryCodeProvider(7).overrideWith((ref) async => null),
            driverLocationProvider(7).overrideWith((ref) => Stream.value(location)),
            // Pas de tuiles reseau en test.
            addressMapTileLayerProvider.overrideWithValue(const SizedBox.shrink()),
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

    testWidgets('carte, prenom et estimation d\'arrivee', (tester) async {
      await pump(tester, _order(), DriverLocation.fromJson(_json));

      expect(find.text('Votre livreur : Marc'), findsOneWidget);
      expect(find.text('Arrivée estimée dans environ 6 min'), findsOneWidget);
      expect(find.byKey(const ValueKey('driver-map')), findsOneWidget);
      expect(find.byKey(const ValueKey('driver-marker')), findsOneWidget);
      expect(find.byKey(const ValueKey('driver-stale')), findsNothing);
    });

    testWidgets('position perimee : signalee avec son anciennete', (tester) async {
      await pump(
        tester,
        _order(),
        DriverLocation.fromJson({..._json, 'stale': true, 'age_seconds': 130}),
      );

      expect(find.byKey(const ValueKey('driver-stale')), findsOneWidget);
      expect(find.text('Dernière position il y a 3 min'), findsOneWidget);
    });

    testWidgets('livreur arrive : plus d\'estimation', (tester) async {
      await pump(
        tester,
        _order(),
        DriverLocation.fromJson({..._json, 'arrived': true, 'eta_minutes': null}),
      );

      expect(find.text('Votre livreur est arrivé'), findsOneWidget);
      expect(find.textContaining('Arrivée estimée'), findsNothing);
    });

    testWidgets('pas encore de position : message, pas de carte', (tester) async {
      await pump(
        tester,
        _order(),
        DriverLocation.fromJson({
          'available': false,
          'driver_first_name': 'Marc',
          'destination_lat': 48.87,
          'destination_lng': 2.36,
        }),
      );

      expect(find.text('La position de votre livreur sera bientôt disponible.'), findsOneWidget);
      expect(find.byKey(const ValueKey('driver-map')), findsNothing);
    });

    testWidgets('suivi indisponible : aucun cadre', (tester) async {
      await pump(tester, _order(), null);

      expect(find.byKey(const ValueKey('driver-summary')), findsNothing);
      expect(find.byKey(const ValueKey('driver-map')), findsNothing);
    });

    testWidgets('jamais avant le depart ni pour un retrait', (tester) async {
      await pump(tester, _order(status: OrderStatusCode.preparing), DriverLocation.fromJson(_json));
      expect(find.byKey(const ValueKey('driver-map')), findsNothing);

      await pump(tester, _order(type: OrderType.pickup), DriverLocation.fromJson(_json));
      expect(find.byKey(const ValueKey('driver-map')), findsNothing);
    });
  });
}
