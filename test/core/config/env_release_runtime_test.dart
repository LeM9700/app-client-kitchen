import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/core/config/env.dart';

const _runReleaseConfigTest = bool.fromEnvironment(
  'RUN_RELEASE_CONFIG_TEST',
  defaultValue: false,
);

void main() {
  test('current dart-define configuration is release-safe', () {
    if (!_runReleaseConfigTest) return;

    expect(
      () => Env.validateForRelease(releaseMode: true),
      returnsNormally,
    );
  });
}
