import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/monitoring/error_reporter.dart';

/// Minimal funnel analytics abstraction.
///
/// No external analytics SDK is wired by default because the production
/// destination and credentials are not present in this repository. Production
/// builds can override [analyticsReporterProvider] with Firebase Analytics,
/// Segment or another tenant-approved sink.
abstract interface class AnalyticsReporter {
  void track(String eventName, Map<String, Object?> properties);
}

class NoopAnalyticsReporter implements AnalyticsReporter {
  const NoopAnalyticsReporter();

  @override
  void track(String eventName, Map<String, Object?> properties) {}
}

class DebugPrintAnalyticsReporter implements AnalyticsReporter {
  const DebugPrintAnalyticsReporter();

  @override
  void track(String eventName, Map<String, Object?> properties) {
    if (!kDebugMode) return;
    final sanitized = TelemetrySanitizer.sanitizeMap(properties);
    debugPrint('[analytics] $eventName $sanitized');
  }
}

final analyticsReporterProvider = Provider<AnalyticsReporter>((ref) {
  if (kDebugMode) return const DebugPrintAnalyticsReporter();
  return const NoopAnalyticsReporter();
});
