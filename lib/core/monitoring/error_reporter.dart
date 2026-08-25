import 'package:flutter/foundation.dart';

abstract interface class ErrorReporter {
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    Map<String, Object?> context = const {},
  });
}

abstract final class ErrorReporting {
  static ErrorReporter reporter =
      kDebugMode ? const DebugPrintErrorReporter() : const NoopErrorReporter();

  static Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    Map<String, Object?> context = const {},
  }) {
    return reporter.recordError(
      error,
      stackTrace,
      fatal: fatal,
      context: context,
    );
  }

  static Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
    Map<String, Object?> context = const {},
  }) {
    return recordError(
      details.exception,
      details.stack ?? StackTrace.current,
      fatal: fatal,
      context: {
        ...context,
        if (details.library != null) 'library': details.library,
        if (details.context != null)
          'flutter_context': details.context.toString(),
      },
    );
  }
}

class NoopErrorReporter implements ErrorReporter {
  const NoopErrorReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    Map<String, Object?> context = const {},
  }) async {}
}

class DebugPrintErrorReporter implements ErrorReporter {
  const DebugPrintErrorReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    Map<String, Object?> context = const {},
  }) async {
    if (!kDebugMode) return;
    final sanitizedError = TelemetrySanitizer.sanitizeValue(error.toString());
    final sanitizedContext = TelemetrySanitizer.sanitizeMap(context);
    debugPrint(
      '[error] fatal=$fatal error=$sanitizedError context=$sanitizedContext',
    );
  }
}

abstract final class TelemetrySanitizer {
  static const String redacted = '[redacted]';

  static final RegExp _bearerPattern = RegExp(
    r'\bBearer\s+[A-Za-z0-9._~+/=-]+',
    caseSensitive: false,
  );
  static final RegExp _jwtPattern = RegExp(
    r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b',
  );
  static final RegExp _emailPattern = RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );
  static final RegExp _stripeSensitivePattern = RegExp(
    r'\b(?:sk|rk|whsec)_[A-Za-z0-9_]+\b',
  );
  static final RegExp _firebaseKeyPattern = RegExp(
    r'\bAIza[0-9A-Za-z_-]+\b',
  );
  static final RegExp _paymentIntentPattern = RegExp(
    r'\bpi_[A-Za-z0-9_]+\b',
  );

  static final Set<String> _sensitiveKeys = {
    'access_token',
    'address',
    'authorization',
    'client_secret',
    'email',
    'firebase_api_key',
    'password',
    'phone',
    'provider_payment_id',
    'refresh_token',
    'secret',
    'stripe_secret_key',
    'stripe_webhook_secret',
    'token',
  };

  static Map<String, Object?> sanitizeMap(Map<String, Object?> values) {
    return {
      for (final entry in values.entries)
        entry.key: sanitizeValue(entry.value, key: entry.key),
    };
  }

  static Object? sanitizeValue(Object? value, {String? key}) {
    if (key != null && _isSensitiveKey(key)) return redacted;
    if (value is String) return _redactString(value);
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): sanitizeValue(
            entry.value,
            key: entry.key.toString(),
          ),
      };
    }
    if (value is Iterable) {
      return value.map((item) => sanitizeValue(item)).toList(growable: false);
    }
    return value;
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll('-', '_');
    return _sensitiveKeys.contains(normalized) ||
        normalized.endsWith('_token') ||
        normalized.endsWith('_secret') ||
        normalized.endsWith('_password');
  }

  static String _redactString(String value) {
    return value
        .replaceAll(_bearerPattern, 'Bearer $redacted')
        .replaceAll(_jwtPattern, redacted)
        .replaceAll(_stripeSensitivePattern, redacted)
        .replaceAll(_firebaseKeyPattern, redacted)
        .replaceAll(_paymentIntentPattern, redacted)
        .replaceAll(_emailPattern, redacted);
  }
}
