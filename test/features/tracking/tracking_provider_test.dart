import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/repositories/order_repository.dart';
import 'package:app_client/features/tracking/models/order_status.dart';
import 'package:app_client/features/tracking/providers/tracking_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Mocks / fakes (mocktail — cohérent avec test/features/checkout et
// test/features/payment de cette session)
//
// [Consolidation Plan 14→15] Ce test mockait initialement
// `TrackingOrderRepository`/`TrackedOrder` (stub minimal du Plan 14, Plan 15
// pas encore exécuté). Bascule sur `OrderRepository`/`Order` (Plan 15) —
// voir tracking_provider.dart.
// ──────────────────────────────────────────────────────────────────────────────

class MockOrderRepository extends Mock implements OrderRepository {}

/// Double de test pour [TrackingSocket] — pas de dépendance au SDK Flutter
/// (indisponible dans cette session) : un simple [StreamController] simule
/// les messages serveur -> client, et [sent] capture les messages
/// client -> serveur pour assertion (handshake, heartbeat).
class FakeTrackingSocket implements TrackingSocket {
  final StreamController<dynamic> _controller = StreamController<dynamic>();
  final List<String> sent = [];
  bool closed = false;

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  void send(String data) => sent.add(data);

  @override
  Future<void> close() async {
    closed = true;
    if (!_controller.isClosed) await _controller.close();
  }

  /// Simule un message reçu du serveur.
  void emitFromServer(Map<String, dynamic> json) {
    _controller.add(jsonEncode(json));
  }

  /// Simule une coupure de connexion (équivalent à `onDone`).
  Future<void> disconnect() async {
    if (!_controller.isClosed) await _controller.close();
  }
}

/// Laisse le temps aux événements de stream / microtasks de se propager.
Future<void> pump([Duration duration = const Duration(milliseconds: 1)]) =>
    Future<void>.delayed(duration);

const _pendingOrder = Order(
  id: 1,
  status: OrderStatusCode.pending,
  subtotal: 0,
  discountTotal: 0,
  deliveryFee: 0,
  total: 0,
);
const _deliveredOrder = Order(
  id: 1,
  status: OrderStatusCode.delivered,
  subtotal: 0,
  discountTotal: 0,
  deliveryFee: 0,
  total: 0,
);

void main() {
  late MockOrderRepository mockRepo;
  late List<FakeTrackingSocket> createdSockets;
  late ProviderContainer container;

  // Provider de test — miroir de `trackingProvider` (lib/features/tracking/
  // providers/tracking_provider.dart) mais avec un repository et un
  // socketFactory injectés, et des délais courts pour ne pas ralentir les
  // tests (backoff par défaut = 1s/2s/4s/.../30s, polling = 35s).
  final testTrackingProvider = StateNotifierProvider.autoDispose
      .family<TrackingNotifier, TrackingState, int>((ref, orderId) {
    return TrackingNotifier(
      ref,
      orderId,
      orderRepository: mockRepo,
      socketFactory: (uri) {
        final socket = FakeTrackingSocket();
        createdSockets.add(socket);
        return socket;
      },
      reconnectDelays: const [Duration(milliseconds: 10)],
      // Suffisamment long pour ne jamais se déclencher pendant un test.
      pollInterval: const Duration(minutes: 10),
    );
  });

  setUp(() {
    mockRepo = MockOrderRepository();
    createdSockets = [];
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  group('TrackingNotifier — heartbeat', () {
    test('répond pong à un ping serveur', () async {
      when(() => mockRepo.getOrderById(1))
          .thenAnswer((_) async => _pendingOrder);

      container.listen(testTrackingProvider(1), (_, __) {});
      container.read(testTrackingProvider(1).notifier);
      await pump();

      final socket = createdSockets.single;
      socket.emitFromServer({'type': 'auth_required'});
      await pump();
      expect(
        socket.sent,
        contains(jsonEncode({'type': 'auth', 'token': null})),
      );

      socket.emitFromServer({'type': 'auth_ok', 'user_id': 1});
      await pump();
      expect(container.read(testTrackingProvider(1)).isConnected, isTrue);

      socket.emitFromServer({'type': 'ping', 'timestamp': 'now'});
      await pump();

      expect(socket.sent, contains(jsonEncode({'type': 'pong'})));
    });
  });

  group('TrackingNotifier — filtrage des événements', () {
    test(
      'refetch uniquement sur un event order.* correspondant à orderId, '
      'ignore les autres order_id et les events non-order',
      () async {
        when(() => mockRepo.getOrderById(1))
            .thenAnswer((_) async => _pendingOrder);

        container.listen(testTrackingProvider(1), (_, __) {});
        container.read(testTrackingProvider(1).notifier);
        await pump();
        // Fetch initial au démarrage du notifier.
        verify(() => mockRepo.getOrderById(1)).called(1);

        final socket = createdSockets.single;

        // Event pertinent : event order.* ET order_id correspondant.
        socket.emitFromServer({
          'type': 'notification',
          'event': 'order.confirmed',
          'data': {'order_id': 1, 'notification_id': 'n1'},
        });
        await pump();
        verify(() => mockRepo.getOrderById(1)).called(1);

        // Event order.* mais pour une AUTRE commande — canal partagé entre
        // toutes les notifications du user, doit être ignoré.
        socket.emitFromServer({
          'type': 'notification',
          'event': 'order.confirmed',
          'data': {'order_id': 999, 'notification_id': 'n2'},
        });
        await pump();

        // Event non-order — doit être ignoré.
        socket.emitFromServer({
          'type': 'notification',
          'event': 'promo.created',
          'data': {'order_id': 1, 'notification_id': 'n3'},
        });
        await pump();

        // Aucun refetch supplémentaire déclenché par les deux events ignorés.
        verifyNever(() => mockRepo.getOrderById(1));
      },
    );
  });

  group('TrackingNotifier — reconnexion', () {
    test('reconnecte avec backoff après une coupure (état non terminal)',
        () async {
      when(() => mockRepo.getOrderById(1))
          .thenAnswer((_) async => _pendingOrder);

      container.listen(testTrackingProvider(1), (_, __) {});
      container.read(testTrackingProvider(1).notifier);
      await pump();
      expect(createdSockets, hasLength(1));

      await createdSockets.first.disconnect();
      await pump();
      expect(
        container.read(testTrackingProvider(1)).isConnected,
        isFalse,
      );

      // Laisse le timer de backoff (10ms) se déclencher.
      await pump(const Duration(milliseconds: 50));

      expect(createdSockets, hasLength(2));
    });

    test(
        'arrête les tentatives de reconnexion une fois un statut terminal atteint',
        () async {
      when(() => mockRepo.getOrderById(1))
          .thenAnswer((_) async => _deliveredOrder);

      container.listen(testTrackingProvider(1), (_, __) {});
      container.read(testTrackingProvider(1).notifier);
      // Laisse le fetch initial se terminer (statut delivered => terminal).
      await pump(const Duration(milliseconds: 20));
      expect(container.read(testTrackingProvider(1)).isTerminal, isTrue);
      expect(createdSockets, hasLength(1));

      await createdSockets.first.disconnect();
      // Laisse largement le temps au backoff de se déclencher s'il n'était
      // pas correctement désactivé.
      await pump(const Duration(milliseconds: 50));

      expect(
        createdSockets,
        hasLength(1),
        reason: 'aucune reconnexion ne doit être tentée en état terminal',
      );
    });
  });
}
