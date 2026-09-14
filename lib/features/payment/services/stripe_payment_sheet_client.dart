import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/theme/kod_mome/kod_mome_design_pack.dart';

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

/// Kod Mome PaymentSheet appearance — only sets colors/shapes on the
/// native Stripe sheet, a surface Flutter widgets never touch directly.
/// See the plan's field-name verification against the installed
/// flutter_stripe API before this was written.
const _kodMomePaymentSheetAppearance = PaymentSheetAppearance(
  colors: PaymentSheetAppearanceColors(
    primary: KodMomeDesignPack.primary,
    background: KodMomeDesignPack.charcoal,
    componentBackground: KodMomeDesignPack.charcoalDeep,
    componentBorder: Color(0x4DD4A73C), // primary @ 30%
    componentDivider: Color(0x33F2E9D8), // cream @ 20%
    componentText: KodMomeDesignPack.cream,
    primaryText: KodMomeDesignPack.cream,
    secondaryText: Color(0xB3F2E9D8), // cream @ 70%
    placeholderText: Color(0x66F2E9D8), // cream @ 40%
    icon: KodMomeDesignPack.primary,
    error: KodMomeDesignPack.redAccent,
  ),
  shapes: PaymentSheetShape(borderRadius: 16, borderWidth: 1),
  primaryButton: PaymentSheetPrimaryButtonAppearance(
    colors: PaymentSheetPrimaryButtonTheme(
      light: PaymentSheetPrimaryButtonThemeColors(
        background: KodMomeDesignPack.primary,
        text: KodMomeDesignPack.charcoalDeep,
        border: KodMomeDesignPack.primary,
      ),
      dark: PaymentSheetPrimaryButtonThemeColors(
        background: KodMomeDesignPack.primary,
        text: KodMomeDesignPack.charcoalDeep,
        border: KodMomeDesignPack.primary,
      ),
    ),
    shapes: PaymentSheetPrimaryButtonShape(borderWidth: 0),
  ),
);

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
          appearance: Env.isKodMomeBuild ? _kodMomePaymentSheetAppearance : null,
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
