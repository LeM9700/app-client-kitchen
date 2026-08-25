import 'package:dio/dio.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';

class PaymentIntentResult {
  const PaymentIntentResult({
    required this.clientSecret,
    required this.providerPaymentId,
  });

  final String clientSecret;
  final String providerPaymentId;
}

class PaymentRepository {
  const PaymentRepository(this._client);

  final ApiClient _client;

  /// Creates or reuses the active server-side PaymentIntent for this order.
  ///
  /// The backend is responsible for idempotency by tenant/user/order. The client
  /// still caches the returned intent in memory to avoid unnecessary retries.
  Future<PaymentIntentResult> createPaymentIntent(int orderId) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.paymentIntent,
        data: {'order_id': orderId},
      );
      final data = response.data!;
      final payment = data['payment'] as Map<String, dynamic>;
      return PaymentIntentResult(
        clientSecret: data['client_secret'] as String,
        providerPaymentId: payment['provider_payment_id'] as String,
      );
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  Future<void> confirmPayment(String providerPaymentId) async {
    try {
      await _client.post<void>(
        ApiEndpoints.paymentConfirm,
        data: {'provider_payment_id': providerPaymentId},
      );
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  Future<void> confirmLocalTestPayment(int orderId) async {
    try {
      await _client.post<void>(
        ApiEndpoints.localTestPaymentConfirm,
        data: {'order_id': orderId},
      );
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}
