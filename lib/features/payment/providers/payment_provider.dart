import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/analytics/analytics_reporter.dart';
import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/core/theme/tenant_theme_provider.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/payment/repositories/payment_repository.dart';
import 'package:app_client/features/payment/services/stripe_payment_sheet_client.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.read(apiClientProvider)),
);

enum PaymentStatus { idle, loading, success, failure }

class PaymentState {
  const PaymentState({
    this.status = PaymentStatus.idle,
    this.error,
    this.clientSecret,
    this.providerPaymentId,
  });

  final PaymentStatus status;
  final String? error;
  final String? clientSecret;
  final String? providerPaymentId;
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier(this._repo, this._paymentSheetClient, this._ref)
      : super(const PaymentState());

  final PaymentRepository _repo;
  final StripePaymentSheetClient _paymentSheetClient;
  final Ref _ref;

  Future<bool> pay(int orderId) async {
    if (!supportsNativeStripePaymentSheet) {
      if (_supportsLocalWebTestPayment) {
        return _payLocalWebTest(orderId);
      }

      state = const PaymentState(
        status: PaymentStatus.failure,
        error:
            'Paiement carte indisponible sur cette plateforme. Utilisez Android ou iOS.',
      );
      return false;
    }

    state = PaymentState(
      status: PaymentStatus.loading,
      clientSecret: state.clientSecret,
      providerPaymentId: state.providerPaymentId,
    );
    _ref.read(analyticsReporterProvider).track(
      'payment_started',
      {'order_id': orderId},
    );

    try {
      String clientSecret;
      String providerPaymentId;
      if (state.clientSecret != null && state.providerPaymentId != null) {
        clientSecret = state.clientSecret!;
        providerPaymentId = state.providerPaymentId!;
        _ref.read(analyticsReporterProvider).track(
          'payment_intent_reused',
          {'order_id': orderId},
        );
      } else {
        final intent = await _repo.createPaymentIntent(orderId);
        clientSecret = intent.clientSecret;
        providerPaymentId = intent.providerPaymentId;
        _ref.read(analyticsReporterProvider).track(
          'payment_intent_created',
          {'order_id': orderId},
        );
        state = PaymentState(
          status: PaymentStatus.loading,
          clientSecret: clientSecret,
          providerPaymentId: providerPaymentId,
        );
      }

      final branding = _ref.read(tenantBrandingProvider);
      await _paymentSheetClient.initPaymentSheet(
        clientSecret: clientSecret,
        merchantDisplayName: branding.displayName ?? 'Restaurant',
      );

      await _paymentSheetClient.presentPaymentSheet();
      await _repo.confirmPayment(providerPaymentId);

      _ref.read(cartProvider.notifier).clear();
      _ref.read(analyticsReporterProvider).track(
        'payment_succeeded',
        {'order_id': orderId},
      );

      state = const PaymentState(status: PaymentStatus.success);
      return true;
    } on PaymentSheetCancelledException {
      state = PaymentState(
        status: PaymentStatus.idle,
        clientSecret: state.clientSecret,
        providerPaymentId: state.providerPaymentId,
      );
      _ref.read(analyticsReporterProvider).track(
        'payment_cancelled',
        {'order_id': orderId},
      );
      return false;
    } on PaymentSheetFailureException catch (e) {
      _ref.read(analyticsReporterProvider).track(
        'payment_failed',
        {
          'order_id': orderId,
          'error_type': 'payment_sheet',
        },
      );
      state = PaymentState(
        status: PaymentStatus.failure,
        error: e.message,
        clientSecret: state.clientSecret,
        providerPaymentId: state.providerPaymentId,
      );
      return false;
    } on AppException catch (e) {
      _ref.read(analyticsReporterProvider).track(
        'payment_failed',
        {
          'order_id': orderId,
          'error_type': e.runtimeType.toString(),
        },
      );
      state = PaymentState(
        status: PaymentStatus.failure,
        error: e.message,
        clientSecret: state.clientSecret,
        providerPaymentId: state.providerPaymentId,
      );
      return false;
    }
  }

  bool get _supportsLocalWebTestPayment {
    final environment = Env.appEnvironment.trim().toLowerCase();
    return kIsWeb && environment != 'production' && environment != 'prod';
  }

  Future<bool> _payLocalWebTest(int orderId) async {
    state = const PaymentState(status: PaymentStatus.loading);
    _ref.read(analyticsReporterProvider).track(
      'payment_started',
      {
        'order_id': orderId,
        'mode': 'local_web_test',
      },
    );

    try {
      await _repo.confirmLocalTestPayment(orderId);

      _ref.read(cartProvider.notifier).clear();
      _ref.read(analyticsReporterProvider).track(
        'payment_succeeded',
        {
          'order_id': orderId,
          'mode': 'local_web_test',
        },
      );

      state = const PaymentState(status: PaymentStatus.success);
      return true;
    } on AppException catch (e) {
      _ref.read(analyticsReporterProvider).track(
        'payment_failed',
        {
          'order_id': orderId,
          'mode': 'local_web_test',
          'error_type': e.runtimeType.toString(),
        },
      );
      state = PaymentState(status: PaymentStatus.failure, error: e.message);
      return false;
    }
  }

  void reset() => state = const PaymentState();
}

final paymentProvider =
    StateNotifierProvider.autoDispose<PaymentNotifier, PaymentState>(
  (ref) => PaymentNotifier(
    ref.read(paymentRepositoryProvider),
    ref.read(stripePaymentSheetClientProvider),
    ref,
  ),
);
