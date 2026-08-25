import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/core/monitoring/error_reporter.dart';

void main() {
  group('TelemetrySanitizer', () {
    test('redacts sensitive keys recursively', () {
      final sanitized = TelemetrySanitizer.sanitizeMap({
        'order_id': 42,
        'email': 'client@example.com',
        'nested': {
          'refresh_token': 'refresh-secret',
          'provider_payment_id': 'pi_123',
        },
      });

      expect(sanitized['order_id'], 42);
      expect(sanitized['email'], TelemetrySanitizer.redacted);
      expect(
        sanitized['nested'],
        {
          'refresh_token': TelemetrySanitizer.redacted,
          'provider_payment_id': TelemetrySanitizer.redacted,
        },
      );
    });

    test('redacts common secret and PII patterns in strings', () {
      const stripeSecret = 'sk_' 'live_secret';
      const webhookSecret = 'wh' 'sec_secret';
      final sanitized = TelemetrySanitizer.sanitizeValue(
        'Bearer eyJabc.def.ghi email client@example.com '
        '$stripeSecret $webhookSecret AIzaabcdef pi_12345',
      );

      expect(sanitized, isNot(contains('eyJabc.def.ghi')));
      expect(sanitized, isNot(contains('client@example.com')));
      expect(sanitized, isNot(contains(stripeSecret)));
      expect(sanitized, isNot(contains(webhookSecret)));
      expect(sanitized, isNot(contains('AIzaabcdef')));
      expect(sanitized, isNot(contains('pi_12345')));
    });
  });
}
