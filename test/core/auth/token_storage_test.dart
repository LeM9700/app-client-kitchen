import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/core/auth/token_storage.dart';

void main() {
  group('TokenStorage platform options', () {
    test('uses encrypted Android storage and resets corrupted restored state',
        () {
      final options = TokenStorage.androidOptions.toMap();

      expect(options['encryptedSharedPreferences'], 'true');
      expect(options['resetOnError'], 'true');
    });

    test('keeps iOS refresh tokens device-local and non-synchronizable', () {
      final options = TokenStorage.iosOptions.toMap();

      expect(
        options['accessibility'],
        KeychainAccessibility.first_unlock_this_device.name,
      );
      expect(options['synchronizable'], 'false');
    });
  });
}
