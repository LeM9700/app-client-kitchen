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

/// Conditions de l'empreinte bancaire (paiement a la livraison), versionnees
/// par le serveur : la version affichee est renvoyee avec l'acceptation.
class GuaranteeTerms {
  const GuaranteeTerms({
    required this.version,
    required this.holdValidityDays,
  });

  factory GuaranteeTerms.fromJson(Map<String, dynamic> json) => GuaranteeTerms(
        version: json['version'] as String,
        holdValidityDays: (json['hold_validity_days'] as num?)?.toInt() ?? 7,
      );

  final String version;
  final int holdValidityDays;
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

  Future<GuaranteeTerms> fetchGuaranteeTerms() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.guaranteeTerms,
      );
      return GuaranteeTerms.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Pre-autorise le total de la commande (aucun debit) pour un paiement a la
  /// livraison. [termsVersion] est la version des conditions que le client a
  /// acceptees ; le serveur refuse une version perimee.
  Future<PaymentIntentResult> createGuaranteeIntent(
    int orderId,
    String termsVersion,
  ) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.guaranteeIntent,
        data: {
          'order_id': orderId,
          'terms_version': termsVersion,
          'accept_terms': true,
        },
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
