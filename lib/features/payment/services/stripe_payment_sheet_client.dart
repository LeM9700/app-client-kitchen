import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:app_client/core/config/env.dart';

final stripePaymentSheetClientProvider = Provider<StripePaymentSheetClient>(
  (ref) => supportsNativeStripePaymentSheet
      ? const NativeStripePaymentSheetClient()
      : const UnsupportedStripePaymentSheetClient(),
);

bool get supportsNativeStripePaymentSheet {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

abstract interface class StripePaymentSheetClient {
  Future<void> initPaymentSheet({
    required String clientSecret,
    required String merchantDisplayName,
  });

  Future<void> presentPaymentSheet();
}

class PaymentSheetCancelledException implements Exception {
  const PaymentSheetCancelledException();
}

class PaymentSheetFailureException implements Exception {
  const PaymentSheetFailureException(this.message);

  final String message;
}

class NativeStripePaymentSheetClient implements StripePaymentSheetClient {
  const NativeStripePaymentSheetClient();

  @override
  Future<void> initPaymentSheet({
    required String clientSecret,
    required String merchantDisplayName,
  }) {
    return _mapStripeErrors(
      () => Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName,
          applePay: const PaymentSheetApplePay(merchantCountryCode: 'FR'),
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'FR',
            testEnv: Env.googlePayTestEnv,
          ),
        ),
      ),
    );
  }

  @override
  Future<void> presentPaymentSheet() {
    return _mapStripeErrors(() => Stripe.instance.presentPaymentSheet());
  }

  Future<void> _mapStripeErrors(Future<Object?> Function() action) async {
    try {
      await action();
    } on StripeException catch (error) {
      if (error.error.code == FailureCode.Canceled) {
        throw const PaymentSheetCancelledException();
      }

      throw PaymentSheetFailureException(
        error.error.localizedMessage ??
            error.error.message ??
            'Paiement refuse.',
      );
    } on Exception catch (_) {
      throw const PaymentSheetFailureException(
        'Paiement indisponible. Reessayez plus tard.',
      );
    }
  }
}

class UnsupportedStripePaymentSheetClient implements StripePaymentSheetClient {
  const UnsupportedStripePaymentSheetClient();

  static const String _message =
      'Le paiement Stripe natif est disponible uniquement sur Android et iOS.';

  @override
  Future<void> initPaymentSheet({
    required String clientSecret,
    required String merchantDisplayName,
  }) async {
    throw const PaymentSheetFailureException(_message);
  }

  @override
  Future<void> presentPaymentSheet() async {
    throw const PaymentSheetFailureException(_message);
  }
}
