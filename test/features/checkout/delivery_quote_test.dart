import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/features/cart/models/cart_item.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/cart/repositories/promo_repository.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/repositories/catalog_repository.dart';
import 'package:app_client/features/checkout/models/address_models.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/models/delivery_info.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/features/checkout/repositories/address_repository.dart';
import 'package:app_client/features/checkout/repositories/checkout_repository.dart';
import 'package:app_client/features/checkout/screens/steps/step_delivery_mode.dart';
import 'package:app_client/features/checkout/widgets/kitchen_order_mode_selector.dart';
import 'package:app_client/features/checkout/widgets/kitchen_order_summary.dart';
import 'package:app_client/l10n/app_localizations.dart';

class MockCheckoutRepository extends Mock implements CheckoutRepository {}

class MockCatalogRepository extends Mock implements CatalogRepository {}

class MockApiClient extends Mock implements ApiClient {}

const _pizza = Product(id: 1, name: 'Margherita', price: 10, categoryId: 1);

DioException _httpError(int status, Object? data) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: data,
    ),
  );
}

Response<T> _ok<T>(T data) => Response<T>(
    data: data, requestOptions: RequestOptions(path: '/x'), statusCode: 200,);

const _zoneJson = {
  'zone_id': 7,
  'name': 'Centre',
  'fee': 2.5,
  'estimated_minutes': 30,
};

void main() {
  setUpAll(() {
    registerFallbackValue(<CartItem>[]);
    registerFallbackValue(Options());
  });

  // ------------------------------------------------------------------ notifier

  group('CheckoutNotifier - verification de livraison', () {
    late MockCheckoutRepository repo;
    late ProviderContainer container;

    void stubCheck(DeliveryInfo info) {
      when(
        () => repo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: any(named: 'displayAddress'),
          subtotal: any(named: 'subtotal'),
          establishmentId: any(named: 'establishmentId'),
        ),
      ).thenAnswer((_) async => info);
    }

    setUp(() {
      repo = MockCheckoutRepository();
      container = ProviderContainer(
        overrides: [
          checkoutRepositoryProvider.overrideWithValue(repo),
          catalogRepositoryProvider.overrideWithValue(MockCatalogRepository()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(checkoutProvider, (_, __) {});
      container.read(cartProvider.notifier)
        ..addItem(_pizza)
        ..addItem(_pizza); // sous-total 20
    });

    const info = DeliveryInfo(
      zoneId: 7,
      name: 'Centre',
      fee: 2.5,
      estimatedMinutes: 30,
      establishmentId: 3,
    );

    test('envoie le sous-total du panier pour calculer les frais reels',
        () async {
      stubCheck(info);
      await container.read(checkoutProvider.notifier).checkDeliveryAddress(
            displayAddress: '12 rue de la Paix',
            lat: 48.87,
            lng: 2.33,
          );
      verify(
        () => repo.checkDeliveryZone(
          lat: 48.87,
          lng: 2.33,
          displayAddress: '12 rue de la Paix',
          subtotal: 20.0,
          establishmentId: any(named: 'establishmentId'),
        ),
      ).called(1);
    });

    test('apercu : memorise le resultat sans avancer ni retenir l\'adresse',
        () async {
      stubCheck(info);
      container
          .read(checkoutProvider.notifier)
          .selectDeliveryMode(DeliveryMode.delivery);

      await container.read(checkoutProvider.notifier).checkDeliveryAddress(
            displayAddress: '12 rue de la Paix',
            lat: 48.87,
            lng: 2.33,
            advance: false,
          );

      final state = container.read(checkoutProvider);
      expect(state.currentStep, CheckoutStep.address);
      expect(state.address, isNull);
      expect(state.deliveryInfo?.zoneId, 7);
      expect((state.lat, state.lng), (48.87, 2.33));
      expect(state.error, isNull);
    });

    test('continuer : avance, retient adresse, telephone et instructions',
        () async {
      stubCheck(info);
      await container.read(checkoutProvider.notifier).checkDeliveryAddress(
            displayAddress: '12 rue de la Paix',
            lat: 48.87,
            lng: 2.33,
            phone: '06 12 34 56 78',
            instructions: '3e etage',
          );
      final state = container.read(checkoutProvider);
      expect(state.currentStep, CheckoutStep.recap);
      expect(state.address, '12 rue de la Paix');
      expect((state.phone, state.instructions), ('06 12 34 56 78', '3e etage'));
    });

    test(
        'un apercu ulterieur ne ramene pas au recapitulatif et garde le telephone',
        () async {
      stubCheck(info);
      final notifier = container.read(checkoutProvider.notifier);
      await notifier.checkDeliveryAddress(
        displayAddress: 'a',
        lat: 1,
        lng: 1,
        phone: '06 12 34 56 78',
      );
      await notifier.checkDeliveryAddress(
          displayAddress: 'b', lat: 2, lng: 2, advance: false,);
      expect(container.read(checkoutProvider).phone, '06 12 34 56 78');
    });

    test(
        'minimum de commande non atteint : on reste sur l\'adresse avec le montant',
        () async {
      stubCheck(
        const DeliveryInfo(
          zoneId: 7,
          name: 'Centre',
          fee: 2.5,
          estimatedMinutes: 30,
          minOrderAmount: 30,
          minOrderMet: false,
        ),
      );
      container
          .read(checkoutProvider.notifier)
          .selectDeliveryMode(DeliveryMode.delivery);
      await container.read(checkoutProvider.notifier).checkDeliveryAddress(
            displayAddress: 'x',
            lat: 1,
            lng: 1,
          );
      final state = container.read(checkoutProvider);
      expect(state.currentStep, CheckoutStep.address);
      expect(state.errorCode, 'DELIVERY_MIN_ORDER_NOT_MET');
      expect(state.deliveryInfo?.minOrderAmount, 30);
    });

    test('hors zone : efface un apercu precedent et pose le code', () async {
      final notifier = container.read(checkoutProvider.notifier);
      stubCheck(info);
      await notifier.checkDeliveryAddress(
          displayAddress: 'a', lat: 1, lng: 1, advance: false,);
      expect(container.read(checkoutProvider).deliveryInfo, isNotNull);

      when(
        () => repo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: any(named: 'displayAddress'),
          subtotal: any(named: 'subtotal'),
          establishmentId: any(named: 'establishmentId'),
        ),
      ).thenThrow(DeliveryZoneUnreachableException());
      await notifier.checkDeliveryAddress(
          displayAddress: 'b', lat: 9, lng: 9, advance: false,);

      final state = container.read(checkoutProvider);
      expect(state.deliveryInfo, isNull);
      expect(state.errorCode, 'DELIVERY_ZONE_UNREACHABLE');
      expect(state.error, contains('hors zone'));
    });

    test('livraison coupee et autres erreurs metier gardent leur code',
        () async {
      when(
        () => repo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: any(named: 'displayAddress'),
          subtotal: any(named: 'subtotal'),
          establishmentId: any(named: 'establishmentId'),
        ),
      ).thenThrow(const DeliveryException('DELIVERY_DISABLED', 'off'));
      await container
          .read(checkoutProvider.notifier)
          .checkDeliveryAddress(displayAddress: 'a', lat: 1, lng: 1);
      expect(container.read(checkoutProvider).errorCode, 'DELIVERY_DISABLED');

      when(
        () => repo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: any(named: 'displayAddress'),
          subtotal: any(named: 'subtotal'),
          establishmentId: any(named: 'establishmentId'),
        ),
      ).thenThrow(const NetworkException());
      await container
          .read(checkoutProvider.notifier)
          .checkDeliveryAddress(displayAddress: 'a', lat: 1, lng: 1);
      final state = container.read(checkoutProvider);
      expect(state.errorCode, isNull);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test(
        'la commande en livraison transmet etablissement, point, telephone et instructions',
        () async {
      stubCheck(info);
      final notifier = container.read(checkoutProvider.notifier);
      notifier.selectDeliveryMode(DeliveryMode.delivery);
      await notifier.checkDeliveryAddress(
        displayAddress: '12 rue de la Paix',
        lat: 48.87,
        lng: 2.33,
        phone: '06 12 34 56 78',
        instructions: 'code 4521',
      );
      when(
        () => repo.createOrder(
          items: any(named: 'items'),
          orderType: any(named: 'orderType'),
          idempotencyKey: any(named: 'idempotencyKey'),
          deliveryAddress: any(named: 'deliveryAddress'),
          deliveryZoneId: any(named: 'deliveryZoneId'),
          establishmentId: any(named: 'establishmentId'),
          deliveryLat: any(named: 'deliveryLat'),
          deliveryLng: any(named: 'deliveryLng'),
          customerPhone: any(named: 'customerPhone'),
          deliveryInstructions: any(named: 'deliveryInstructions'),
          promoCode: any(named: 'promoCode'),
        ),
      ).thenAnswer((_) async => 42);

      expect(await notifier.createOrder(), 42);

      verify(
        () => repo.createOrder(
          items: any(named: 'items'),
          orderType: 'delivery',
          idempotencyKey: any(named: 'idempotencyKey'),
          deliveryAddress: '12 rue de la Paix',
          deliveryZoneId: 7,
          establishmentId: 3,
          deliveryLat: 48.87,
          deliveryLng: 2.33,
          customerPhone: '06 12 34 56 78',
          deliveryInstructions: 'code 4521',
          promoCode: null,
        ),
      ).called(1);
    });

    test('le retrait n\'envoie aucune donnee de livraison', () async {
      stubCheck(info);
      final notifier = container.read(checkoutProvider.notifier);
      await notifier.checkDeliveryAddress(
        displayAddress: 'a',
        lat: 1,
        lng: 1,
        phone: '06 12 34 56 78',
      );
      notifier.selectDeliveryMode(DeliveryMode.pickup);
      when(
        () => repo.createOrder(
          items: any(named: 'items'),
          orderType: any(named: 'orderType'),
          idempotencyKey: any(named: 'idempotencyKey'),
          deliveryAddress: any(named: 'deliveryAddress'),
          deliveryZoneId: any(named: 'deliveryZoneId'),
          establishmentId: any(named: 'establishmentId'),
          deliveryLat: any(named: 'deliveryLat'),
          deliveryLng: any(named: 'deliveryLng'),
          customerPhone: any(named: 'customerPhone'),
          deliveryInstructions: any(named: 'deliveryInstructions'),
          promoCode: any(named: 'promoCode'),
        ),
      ).thenAnswer((_) async => 43);

      await notifier.createOrder();

      verify(
        () => repo.createOrder(
          items: any(named: 'items'),
          orderType: 'pickup',
          idempotencyKey: any(named: 'idempotencyKey'),
          deliveryAddress: any(named: 'deliveryAddress'),
          deliveryZoneId: any(named: 'deliveryZoneId'),
          establishmentId: null,
          deliveryLat: null,
          deliveryLng: null,
          customerPhone: null,
          deliveryInstructions: null,
          promoCode: any(named: 'promoCode'),
        ),
      ).called(1);
    });

    test('une erreur metier a la creation de commande garde son code',
        () async {
      when(
        () => repo.createOrder(
          items: any(named: 'items'),
          orderType: any(named: 'orderType'),
          idempotencyKey: any(named: 'idempotencyKey'),
          deliveryAddress: any(named: 'deliveryAddress'),
          deliveryZoneId: any(named: 'deliveryZoneId'),
          establishmentId: any(named: 'establishmentId'),
          deliveryLat: any(named: 'deliveryLat'),
          deliveryLng: any(named: 'deliveryLng'),
          customerPhone: any(named: 'customerPhone'),
          deliveryInstructions: any(named: 'deliveryInstructions'),
          promoCode: any(named: 'promoCode'),
        ),
      ).thenThrow(const DeliveryException('DELIVERY_DISABLED', 'off'));

      expect(await container.read(checkoutProvider.notifier).createOrder(),
          isNull,);
      expect(container.read(checkoutProvider).errorCode, 'DELIVERY_DISABLED');
    });
  });

  // ------------------------------------------------------------------ repositories

  group('mapDeliveryError', () {
    test('reconnait les codes de livraison', () {
      final error = mapDeliveryError(
        _httpError(
            409, {'code': 'DELIVERY_DISABLED', 'detail': 'off', 'field': null},),
      );
      expect(error, isA<DeliveryException>());
      expect((error as DeliveryException).code, 'DELIVERY_DISABLED');
      expect(error.message, 'off');
    });

    test('le 429 devient RATE_LIMITED', () {
      final error =
          mapDeliveryError(_httpError(429, {'error': 'Rate limit exceeded'}));
      expect((error as DeliveryException).code, 'RATE_LIMITED');
    });

    test('un code inconnu retombe sur la conversion generique', () {
      expect(
        mapDeliveryError(
            _httpError(404, {'code': 'ORDER_NOT_FOUND', 'detail': 'x'}),),
        isA<NotFoundException>(),
      );
      expect(
        mapDeliveryError(_httpError(500, 'boom')),
        isA<ServerException>(),
      );
    });
  });

  group('CheckoutRepository', () {
    late MockApiClient api;
    late CheckoutRepository repo;

    setUp(() {
      api = MockApiClient();
      repo = CheckoutRepository(api);
    });

    Future<Map<String, dynamic>> captureCheckBody({
      String? address,
      double? subtotal,
      int? establishmentId,
    }) async {
      when(
        () => api.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => _ok<Map<String, dynamic>>({..._zoneJson}));
      await repo.checkDeliveryZone(
        lat: 1.5,
        lng: 2.5,
        displayAddress: address,
        subtotal: subtotal,
        establishmentId: establishmentId,
      );
      final captured = verify(
        () => api.post<Map<String, dynamic>>(
          any(),
          data: captureAny(named: 'data'),
          options: any(named: 'options'),
        ),
      ).captured.single;
      return Map<String, dynamic>.from(captured as Map);
    }

    test('n\'envoie que ce qui est renseigne', () async {
      expect(await captureCheckBody(), {'lat': 1.5, 'lng': 2.5});
    });

    test('envoie adresse, sous-total et etablissement quand ils existent',
        () async {
      expect(
        await captureCheckBody(
            address: '12 rue', subtotal: 20, establishmentId: 3,),
        {
          'lat': 1.5,
          'lng': 2.5,
          'address': '12 rue',
          'subtotal': 20.0,
          'establishment_id': 3,
        },
      );
    });

    test('une adresse vide n\'est pas envoyee', () async {
      expect((await captureCheckBody(address: '')).containsKey('address'),
          isFalse,);
    });

    test('lit la reponse enrichie de /delivery/check', () async {
      when(
        () => api.post<Map<String, dynamic>>(any(),
            data: any(named: 'data'), options: any(named: 'options'),),
      ).thenAnswer(
        (_) async => _ok<Map<String, dynamic>>({
          ..._zoneJson,
          'establishment_id': 3,
          'base_fee': 3.0,
          'free_delivery': true,
          'applied_label': 'Offerte des 25',
          'remaining_for_free': null,
          'min_order_amount': 15,
          'min_order_met': true,
        }),
      );
      final result = await repo.checkDeliveryZone(lat: 1, lng: 1);
      expect(result.establishmentId, 3);
      expect((result.freeDelivery, result.appliedLabel, result.baseFee),
          (true, 'Offerte des 25', 3.0),);
      expect((result.minOrderAmount, result.minOrderMet), (15.0, true));
    });

    test(
        'hors zone (422) et 422 sans code deviennent DeliveryZoneUnreachableException',
        () async {
      for (final body in [
        {
          'code': 'DELIVERY_ZONE_UNREACHABLE',
          'detail': 'hors zone',
          'field': null,
        },
        {'detail': 'x'},
      ]) {
        when(
          () => api.post<Map<String, dynamic>>(any(),
              data: any(named: 'data'), options: any(named: 'options'),),
        ).thenThrow(_httpError(422, body));
        await expectLater(
          repo.checkDeliveryZone(lat: 1, lng: 1),
          throwsA(isA<DeliveryZoneUnreachableException>()),
        );
      }
    });

    test('livraison coupee (409) et autre 422 metier ne sont pas "hors zone"',
        () async {
      when(
        () => api.post<Map<String, dynamic>>(any(),
            data: any(named: 'data'), options: any(named: 'options'),),
      ).thenThrow(_httpError(
          409, {'code': 'DELIVERY_DISABLED', 'detail': 'off', 'field': null},),);
      await expectLater(
        repo.checkDeliveryZone(lat: 1, lng: 1),
        throwsA(isA<DeliveryException>()
            .having((e) => e.code, 'code', 'DELIVERY_DISABLED'),),
      );

      when(
        () => api.post<Map<String, dynamic>>(any(),
            data: any(named: 'data'), options: any(named: 'options'),),
      ).thenThrow(_httpError(422, {
        'code': 'DELIVERY_MIN_ORDER_NOT_MET',
        'detail': 'min',
        'field': null,
      }),);
      await expectLater(
        repo.checkDeliveryZone(lat: 1, lng: 1),
        throwsA(isA<DeliveryException>()),
      );
    });

    test('createOrder n\'envoie les champs de livraison que s\'ils existent',
        () async {
      when(
        () => api.post<Map<String, dynamic>>(any(),
            data: any(named: 'data'), options: any(named: 'options'),),
      ).thenAnswer((_) async => _ok<Map<String, dynamic>>({'id': 9}));

      await repo.createOrder(
        items: const [],
        orderType: 'delivery',
        idempotencyKey: 'k',
        deliveryAddress: '12 rue',
        deliveryZoneId: 7,
        establishmentId: 3,
        deliveryLat: 1.5,
        deliveryLng: 2.5,
        customerPhone: '06 12 34 56 78',
        deliveryInstructions: 'code',
      );
      final full = Map<String, dynamic>.from(
        verify(() => api.post<Map<String, dynamic>>(any(),
            data: captureAny(named: 'data'),
            options: any(named: 'options'),),).captured.single as Map,
      );
      expect(full['establishment_id'], 3);
      expect(
        [
          full['delivery_lat'],
          full['delivery_lng'],
          full['customer_phone'],
          full['delivery_instructions'],
        ],
        [1.5, 2.5, '06 12 34 56 78', 'code'],
      );

      clearInteractions(api);
      await repo.createOrder(
          items: const [], orderType: 'pickup', idempotencyKey: 'k2',);
      final bare = Map<String, dynamic>.from(
        verify(() => api.post<Map<String, dynamic>>(any(),
            data: captureAny(named: 'data'),
            options: any(named: 'options'),),).captured.single as Map,
      );
      for (final key in [
        'establishment_id',
        'delivery_lat',
        'delivery_lng',
        'customer_phone',
        'delivery_instructions',
      ]) {
        expect(bare.containsKey(key), isFalse, reason: key);
      }
    });

    test('createOrder traduit les codes metier', () async {
      when(
        () => api.post<Map<String, dynamic>>(any(),
            data: any(named: 'data'), options: any(named: 'options'),),
      ).thenThrow(_httpError(422, {
        'code': 'CUSTOMER_PHONE_REQUIRED',
        'detail': 'tel',
        'field': 'customer_phone',
      }),);
      await expectLater(
        repo.createOrder(
            items: const [], orderType: 'delivery', idempotencyKey: 'k',),
        throwsA(isA<DeliveryException>()
            .having((e) => e.code, 'code', 'CUSTOMER_PHONE_REQUIRED'),),
      );
    });
  });

  group('AddressRepository', () {
    late MockApiClient api;
    late AddressRepository repo;

    setUp(() {
      api = MockApiClient();
      repo = AddressRepository(api);
    });

    test(
        'geocode ignore les resultats sans coordonnees valides et envoie la proximite',
        () async {
      when(
        () => api.get<List<dynamic>>(any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),),
      ).thenAnswer(
        (_) async => _ok<List<dynamic>>([
          {'label': 'A', 'lat': 48.85, 'lng': 2.35, 'city': 'Paris'},
          {'label': 'sans point'},
          {'label': 'hors bornes', 'lat': 99, 'lng': 2},
          'pas un objet',
        ]),
      );
      final results =
          await repo.geocode('rue', lat: 48.8, lng: 2.3, language: 'sr');

      expect(results.map((r) => r.label), ['A']);
      expect(results.single.city, 'Paris');
      final query = verify(
        () => api.get<List<dynamic>>(any(),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),),
      ).captured.single as Map;
      expect(query['q'], 'rue');
      expect(
          (query['lat'], query['lng'], query['language']), (48.8, 2.3, 'sr'),);
    });

    test('geocode sans proximite n\'envoie pas lat/lng', () async {
      when(
        () => api.get<List<dynamic>>(any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),),
      ).thenAnswer((_) async => _ok<List<dynamic>>(const []));
      await repo.geocode('rue');
      final query = verify(
        () => api.get<List<dynamic>>(any(),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),),
      ).captured.single as Map;
      expect(query.containsKey('lat'), isFalse);
    });

    test('geocode traduit indisponibilite et limitation', () async {
      when(
        () => api.get<List<dynamic>>(any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),),
      ).thenThrow(_httpError(503,
          {'code': 'GEOCODING_UNAVAILABLE', 'detail': 'down', 'field': null},),);
      await expectLater(
        repo.geocode('rue'),
        throwsA(isA<DeliveryException>()
            .having((e) => e.code, 'code', 'GEOCODING_UNAVAILABLE'),),
      );

      when(
        () => api.get<List<dynamic>>(any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),),
      ).thenThrow(_httpError(429, {'error': 'x'}));
      await expectLater(
        repo.geocode('rue'),
        throwsA(isA<DeliveryException>()
            .having((e) => e.code, 'code', 'RATE_LIMITED'),),
      );
    });

    test('reverse retourne null quand l\'API ne trouve rien', () async {
      when(
        () => api.get<dynamic>(any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),),
      ).thenAnswer((_) async => _ok<dynamic>(null));
      expect(await repo.reverse(1, 1), isNull);
    });

    test('availability lit la reponse publique', () async {
      when(
        () => api.get<Map<String, dynamic>>(any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),),
      ).thenAnswer(
        (_) async => _ok<Map<String, dynamic>>({
          'delivery_enabled': false,
          'establishments': [
            {
              'id': 1,
              'name': 'Centre',
              'latitude': 48.85,
              'longitude': 2.35,
              'has_delivery_zones': true,
            },
          ],
        }),
      );
      final availability = await repo.availability();
      expect(availability.deliveryEnabled, isFalse);
      expect(availability.establishments.single.name, 'Centre');
    });
  });

  // ------------------------------------------------------------------ modeles

  group('modeles', () {
    test('AddressSuggestion.tryParse refuse les donnees inutilisables', () {
      expect(AddressSuggestion.tryParse(null), isNull);
      expect(AddressSuggestion.tryParse({'label': '', 'lat': 1, 'lng': 1}),
          isNull,);
      expect(AddressSuggestion.tryParse({'label': 'x', 'lat': 'a', 'lng': 1}),
          isNull,);
      expect(AddressSuggestion.tryParse({'label': 'x', 'lat': 100, 'lng': 1}),
          isNull,);
      expect(AddressSuggestion.tryParse({'label': 'x', 'lat': 48, 'lng': 181}),
          isNull,);
      final ok =
          AddressSuggestion.tryParse({'label': 'x', 'lat': 48, 'lng': 2});
      expect(ok?.point.latitude, 48.0);
    });

    test('DeliveryAvailability : centre de carte et valeurs par defaut', () {
      expect(DeliveryAvailability.fromJson(const {}).deliveryEnabled, isTrue);
      expect(DeliveryAvailability.fromJson(const {}).mapCenter, isNull);

      final availability = DeliveryAvailability.fromJson({
        'delivery_enabled': true,
        'establishments': [
          {
            'id': 1,
            'name': 'Sans zone',
            'latitude': 10.0,
            'longitude': 10.0,
            'has_delivery_zones': false,
          },
          {
            'id': 2,
            'name': 'Avec zone',
            'latitude': 48.0,
            'longitude': 2.0,
            'has_delivery_zones': true,
          },
          {'id': 3, 'name': 'Sans position', 'has_delivery_zones': true},
          {'broken': true},
        ],
      });
      expect(availability.establishments, hasLength(3));
      // Le restaurant qui livre et dont la position est connue prime.
      expect(availability.mapCenter?.latitude, 48.0);

      final onlyUnzoned = DeliveryAvailability.fromJson({
        'establishments': [
          {
            'id': 1,
            'name': 'A',
            'latitude': 10.0,
            'longitude': 11.0,
            'has_delivery_zones': false,
          },
        ],
      });
      expect(onlyUnzoned.mapCenter?.longitude, 11.0);
    });

    test('DeliveryInfo lit un ancien payload a 4 champs', () {
      final info = DeliveryInfo.fromJson({..._zoneJson});
      expect(info.freeDelivery, isFalse);
      expect((info.minOrderAmount, info.minOrderMet, info.establishmentId),
          (0.0, null, null),);
    });

    test('PromoPreview lit free_delivery (absent = faux)', () {
      expect(
          PromoPreview.fromJson(
                  {'valid': true, 'discount': 0.0, 'free_delivery': true},)
              .freeDelivery,
          isTrue,);
      expect(
          PromoPreview.fromJson({'valid': true, 'discount': 2.0}).freeDelivery,
          isFalse,);
    });
  });

  group('panier : code promo livraison offerte', () {
    test('le drapeau est pose, puis efface par une erreur ou un panier vide',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final cart = container.read(cartProvider.notifier);

      cart.setPromoResult(discount: 0, code: 'LIVRE0', freeDelivery: true);
      expect(container.read(cartProvider).promoFreeDelivery, isTrue);
      expect(container.read(cartProvider).promoDiscount, 0);

      cart.setPromoError('invalide');
      expect(container.read(cartProvider).promoFreeDelivery, isFalse);

      cart.setPromoResult(discount: 2, code: 'X');
      expect(container.read(cartProvider).promoFreeDelivery, isFalse);

      cart.setPromoResult(discount: 0, code: 'LIVRE0', freeDelivery: true);
      cart.clear();
      expect(container.read(cartProvider).promoFreeDelivery, isFalse);
    });
  });

  // ------------------------------------------------------------------ widgets

  group('choix livraison / retrait', () {
    Future<void> pumpSelector(
      WidgetTester tester, {
      required bool deliveryEnabled,
      required ValueChanged<DeliveryMode> onSelected,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KitchenOrderModeSelector(
              selectedMode: DeliveryMode.delivery,
              deliveryEnabled: deliveryEnabled,
              deliveryUnavailableLabel: 'Indisponible actuellement',
              onSelected: onSelected,
            ),
          ),
        ),
      );
    }

    testWidgets(
        'livraison coupee : segment grise, non selectionnable, retrait possible',
        (tester) async {
      final picked = <DeliveryMode>[];
      await pumpSelector(tester,
          deliveryEnabled: false, onSelected: picked.add,);

      expect(find.text('Indisponible actuellement'), findsOneWidget);
      expect(find.text('A domicile'), findsNothing);

      await tester.tap(find.text('Livraison'));
      await tester.pump();
      expect(picked, isEmpty);

      await tester.tap(find.text('Retrait'));
      await tester.pump();
      expect(picked, [DeliveryMode.pickup]);
    });

    testWidgets('livraison disponible : comportement inchange', (tester) async {
      final picked = <DeliveryMode>[];
      await pumpSelector(tester, deliveryEnabled: true, onSelected: picked.add);

      expect(find.text('A domicile'), findsOneWidget);
      await tester.tap(find.text('Livraison'));
      await tester.pump();
      expect(picked, [DeliveryMode.delivery]);
    });

    Future<ProviderContainer> pumpStep(
      WidgetTester tester,
      Override availability,
    ) async {
      final container = ProviderContainer(overrides: [availability]);
      addTearDown(container.dispose);
      container.listen(checkoutProvider, (_, __) {});
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: Scaffold(body: StepDeliveryMode()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return container;
    }

    testWidgets(
        'l\'etape lit la disponibilite : coupee -> message et pas d\'avance',
        (tester) async {
      final container = await pumpStep(
        tester,
        deliveryAvailabilityProvider.overrideWith(
          (ref) async => const DeliveryAvailability(deliveryEnabled: false),
        ),
      );
      expect(find.text('Indisponible actuellement'), findsOneWidget);

      await tester.tap(find.text('Livraison'));
      await tester.pump();
      expect(container.read(checkoutProvider).currentStep,
          isNot(CheckoutStep.address),);
    });

    testWidgets(
        'disponibilite inconnue (erreur reseau) : la livraison reste proposee',
        (tester) async {
      final container = await pumpStep(
        tester,
        deliveryAvailabilityProvider
            .overrideWith((ref) async => throw const NetworkException()),
      );
      expect(find.text('Indisponible actuellement'), findsNothing);

      await tester.tap(find.text('Livraison'));
      await tester.pump();
      expect(
          container.read(checkoutProvider).currentStep, CheckoutStep.address,);
    });
  });

  group('recapitulatif', () {
    Widget summary({
      double deliveryFee = 0,
      bool freeDelivery = false,
      double? remainingForFree,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: KitchenOrderSummary(
              items: const [],
              deliveryMode: DeliveryMode.delivery,
              subtotal: 20,
              deliveryFee: deliveryFee,
              freeDelivery: freeDelivery,
              remainingForFree: remainingForFree,
              total: 20 + deliveryFee,
            ),
          ),
        ),
      );
    }

    testWidgets('livraison offerte : ligne explicite', (tester) async {
      await tester.pumpWidget(summary(freeDelivery: true));
      expect(find.text('Offerte'), findsOneWidget);
      expect(find.textContaining('Plus que'), findsNothing);
    });

    testWidgets('frais payants : montant et incitation a atteindre le seuil',
        (tester) async {
      await tester.pumpWidget(summary(deliveryFee: 3, remainingForFree: 5));
      expect(find.text('3.00 €'), findsOneWidget);
      expect(find.textContaining('Plus que 5.00'), findsOneWidget);
      expect(find.text('Offerte'), findsNothing);
    });

    testWidgets('sans frais ni offre : ni « Offerte » ni ligne de frais a zero',
        (tester) async {
      await tester.pumpWidget(summary());
      expect(find.text('Offerte'), findsNothing);
      expect(find.textContaining('Plus que'), findsNothing);
      expect(find.text('0.00 €'), findsNothing); // pas de ligne de frais a zero
    });
  });
}
