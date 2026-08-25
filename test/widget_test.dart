import 'package:flutter_test/flutter_test.dart';

/// Smoke test minimal du harness Flutter. Les tests fonctionnels sont rangés
/// par feature dans `test/features/` et `test/integration/`.
void main() {
  test('test harness is available', () {
    expect(1 + 1, equals(2));
  });
}
