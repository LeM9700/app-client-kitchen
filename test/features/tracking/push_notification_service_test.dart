import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/features/tracking/services/push_notification_service.dart';

void main() {
  group('PushNotificationService.trackingRouteFromMessageData', () {
    test('accepts positive integer order ids', () {
      expect(
        PushNotificationService.trackingRouteFromMessageData({'order_id': 42}),
        '/orders/42/tracking',
      );
      expect(
        PushNotificationService.trackingRouteFromMessageData(
          {'order_id': '42'},
        ),
        '/orders/42/tracking',
      );
    });

    test('rejects missing, non numeric and non positive order ids', () {
      expect(PushNotificationService.trackingRouteFromMessageData({}), isNull);
      expect(
        PushNotificationService.trackingRouteFromMessageData({
          'order_id': '../../auth/login',
        }),
        isNull,
      );
      expect(
        PushNotificationService.trackingRouteFromMessageData({'order_id': 0}),
        isNull,
      );
      expect(
        PushNotificationService.trackingRouteFromMessageData({'order_id': -1}),
        isNull,
      );
    });
  });
}
