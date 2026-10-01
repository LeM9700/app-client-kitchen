import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/widgets/kitchen_order_timeline.dart';
import 'package:app_client/features/orders/widgets/kitchen_status_badge.dart';
import 'package:app_client/features/orders/widgets/order_status_presentation.dart';
import 'package:app_client/features/tracking/models/order_status.dart';

Map<String, dynamic> _orderJson({
  String status = 'out_for_delivery',
  List<Map<String, dynamic>> history = const [],
}) =>
    {
      'id': 12,
      'order_type': 'delivery',
      'status': status,
      'subtotal': 20.0,
      'discount_total': 0.0,
      'delivery_fee': 3.0,
      'total': 23.0,
      'delivery_address': '1 rue de la Paix',
      'delivery_lat': 48.8566,
      'delivery_lng': 2.3522,
      'delivery_instructions': '3e etage, code 4521',
      'status_history': history,
    };

void main() {
  group('orderStatusFromApi', () {
    test('parses the two statuses the API always had but the app lacked', () {
      expect(
        orderStatusFromApi('delivery_failed'),
        OrderStatusCode.deliveryFailed,
      );
      expect(orderStatusFromApi('rejected'), OrderStatusCode.rejected);
    });

    test('never throws on an unknown or internal value', () {
      expect(orderStatusFromApi('item_ready'), OrderStatusCode.unknown);
      expect(orderStatusFromApi('some_future_status'), OrderStatusCode.unknown);
      expect(orderStatusFromApi(''), OrderStatusCode.unknown);
    });

    test('round-trips every known status', () {
      for (final status in OrderStatusCode.values) {
        if (status == OrderStatusCode.unknown) continue;
        expect(orderStatusFromApi(status.apiValue), status);
      }
    });
  });

  group('terminal and failure states', () {
    test('delivery_failed and rejected are terminal failures', () {
      for (final status in [
        OrderStatusCode.deliveryFailed,
        OrderStatusCode.rejected,
        OrderStatusCode.cancelled,
      ]) {
        expect(status.isTerminal, isTrue, reason: status.name);
        expect(status.isFailure, isTrue, reason: status.name);
      }
      expect(OrderStatusCode.delivered.isTerminal, isTrue);
      expect(OrderStatusCode.delivered.isFailure, isFalse);
    });

    test('unknown is not terminal so polling keeps running', () {
      expect(OrderStatusCode.unknown.isTerminal, isFalse);
      expect(OrderStatusCode.unknown.isFailure, isFalse);
    });

    test('every status has a label, an icon and a presentation', () {
      for (final status in OrderStatusCode.values) {
        expect(status.label, isNotEmpty);
        expect(status.icon, isNotEmpty);
        expect(OrderStatusPresentation.fromStatus(status).label, isNotEmpty);
      }
    });
  });

  group('Order.fromJson', () {
    test('a delivery_failed order parses with its delivery details', () {
      final order = Order.fromJson(_orderJson(status: 'delivery_failed'));

      expect(order.status, OrderStatusCode.deliveryFailed);
      expect(order.isTerminal, isTrue);
      expect(order.deliveryLat, 48.8566);
      expect(order.deliveryLng, 2.3522);
      expect(order.deliveryInstructions, '3e etage, code 4521');
    });

    test('internal item_* history entries do not break the order', () {
      final order = Order.fromJson(
        _orderJson(
          history: [
            {'status': 'pending', 'created_at': '2026-10-01T10:00:00Z'},
            {'status': 'item_ready', 'note': 'Item #3: ok'},
            {
              'status': 'out_for_delivery',
              'authority': 'internal',
              'created_at': '2026-10-01T10:30:00Z',
            },
          ],
        ),
      );

      expect(order.statusHistory, hasLength(3));
      expect(order.statusHistory[1].status, OrderStatusCode.unknown);
      expect(order.status, OrderStatusCode.outForDelivery);
    });

    test('an unknown order status does not throw', () {
      expect(
        Order.fromJson(_orderJson(status: 'brand_new_status')).status,
        OrderStatusCode.unknown,
      );
    });

    test('an older payload without the new delivery fields still parses', () {
      final json = _orderJson()
        ..remove('delivery_lat')
        ..remove('delivery_lng')
        ..remove('delivery_instructions');
      final order = Order.fromJson(json);

      expect(order.deliveryLat, isNull);
      expect(order.deliveryInstructions, isNull);
    });
  });

  group('timeline and badge for a failed delivery', () {
    testWidgets('the timeline shows the failure alone', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KitchenOrderTimeline(
              currentStatus: OrderStatusCode.deliveryFailed,
              orderType: OrderType.delivery,
            ),
          ),
        ),
      );

      expect(find.text('Livraison echouee'), findsOneWidget);
      expect(find.text('Prete a partir'), findsNothing);
    });

    testWidgets('the badge renders for delivery_failed and unknown',
        (tester) async {
      for (final status in [
        OrderStatusCode.deliveryFailed,
        OrderStatusCode.unknown,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: KitchenStatusBadge(status: status)),
          ),
        );
        expect(
          find.text(OrderStatusPresentation.fromStatus(status).label),
          findsOneWidget,
        );
      }
    });

    test('timeline state marks only the failure as failed', () {
      expect(
        timelineStateFor(
          status: OrderStatusCode.deliveryFailed,
          currentStatus: OrderStatusCode.deliveryFailed,
          orderType: OrderType.delivery,
        ),
        KitchenTimelineState.failed,
      );
      expect(
        timelineStateFor(
          status: OrderStatusCode.preparing,
          currentStatus: OrderStatusCode.deliveryFailed,
          orderType: OrderType.delivery,
        ),
        KitchenTimelineState.upcoming,
      );
    });
  });
}
