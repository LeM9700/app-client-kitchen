import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/core/utils/price_formatter.dart';

void main() {
  group('formatIndicativePrice()', () {
    test('suffixe le code devise, jamais un symbole ambigu', () {
      expect(formatIndicativePrice(12.5, 'USD'), '~12.50 USD');
      expect(formatIndicativePrice(9, 'GBP'), '~9.00 GBP');
    });
  });

  group('kSupportedDisplayCurrencies', () {
    test('miroir de SUPPORTED_CURRENCIES côté api-pizza', () {
      expect(
        kSupportedDisplayCurrencies,
        ['EUR', 'USD', 'GBP', 'CAD', 'CHF'],
      );
    });
  });
}
