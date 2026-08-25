import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/features/loyalty/models/loyalty_account.dart';
import 'package:app_client/features/loyalty/models/loyalty_reward.dart';
import 'package:app_client/features/loyalty/models/loyalty_transaction.dart';

part 'loyalty_repository.freezed.dart';
part 'loyalty_repository.g.dart';

/// Résultat d'un échange de récompense — miroir de `RedeemResponse`
/// (`api-pizza/app/modules/loyalty/config/schemas.py`).
///
/// [🔒 api-corrections-phase-d.md §6] Pour les récompenses `discount_euros`,
/// `promoCode` est un code à usage unique généré côté serveur — il n'est
/// JAMAIS appliqué automatiquement à une commande. L'UI doit l'afficher et
/// indiquer à l'utilisateur de le saisir au panier/checkout, ne jamais
/// prétendre que la réduction est déjà active.
@freezed
class RedeemResult with _$RedeemResult {
  const factory RedeemResult({
    @JsonKey(name: 'discount_euros') double? discountEuros,
    @JsonKey(name: 'free_product_id') int? freeProductId,
    @JsonKey(name: 'remaining_points') required int remainingPoints,
    @JsonKey(name: 'promo_code') String? promoCode,
  }) = _RedeemResult;

  factory RedeemResult.fromJson(Map<String, dynamic> json) =>
      _$RedeemResultFromJson(json);
}

/// Page de transactions — `LoyaltyTransactionPage` côté serveur.
///
/// [🔒 api-corrections-phase-d.md §6] Forme de pagination DIFFÉRENTE de
/// `OrderPage` (commandes) : `limit` au lieu de `page_size`, PAS de champ
/// `pages` — [hasMore] est donc calculé côté client à partir de
/// `page`/`limit`/`total`, contrairement à `OrderPage.pages` qui vient tel
/// quel du serveur.
///
/// DTO de repository volontairement non-freezed, même convention que
/// `OrderPage` (`features/orders/repositories/order_repository.dart`) : pas
/// besoin d'égalité structurelle/`copyWith`, reconstruit à chaque page.
class LoyaltyTransactionPage {
  const LoyaltyTransactionPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<LoyaltyTransaction> items;
  final int page;
  final int limit;
  final int total;

  factory LoyaltyTransactionPage.fromJson(Map<String, dynamic> json) =>
      LoyaltyTransactionPage(
        items: (json['items'] as List)
            .map(
              (e) => LoyaltyTransaction.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        page: json['page'] as int,
        limit: json['limit'] as int,
        total: json['total'] as int,
      );

  /// Pas de champ `pages` renvoyé par l'API pour cette pagination — calculé
  /// ici plutôt que côté serveur (voir doc de classe).
  bool get hasMore => page * limit < total;
}

/// Repository fidélité — solde (Plan 16), historique, catalogue de
/// récompenses et échange. Distinct de `PromoRepository.previewLoyaltyPoints`
/// (Plan 09, `cart/repositories/promo_repository.dart`) qui couvre l'aperçu
/// de points AVANT validation panier, un concept différent.
class LoyaltyRepository {
  const LoyaltyRepository(this._client);
  final ApiClient _client;

  /// `GET /loyalty/me` — solde courant (`LoyaltyAccountOut`).
  Future<LoyaltyAccount> getAccount() async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>(ApiEndpoints.loyaltyAccount);
      return LoyaltyAccount.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// `GET /loyalty/transactions?page=&limit=&type=` — historique paginé.
  /// [type] filtre optionnel sur `transaction_type` (passé tel quel côté
  /// serveur, ex. `manual`/`order`/`redeem`).
  Future<LoyaltyTransactionPage> getTransactions({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.loyaltyTransactions,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (type != null) 'type': type,
        },
      );
      return LoyaltyTransactionPage.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// `GET /loyalty/rewards` — catalogue avec éligibilité
  /// (`list[LoyaltyRewardEligibilityResponse]`). Authentifié — passe par
  /// [ApiClient], le token Bearer est déjà attaché par défaut, rien de
  /// spécial à faire ici.
  Future<List<LoyaltyReward>> getRewards() async {
    try {
      final response =
          await _client.get<List<dynamic>>(ApiEndpoints.loyaltyRewards);
      return (response.data as List)
          .map((e) => LoyaltyReward.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// `POST /loyalty/rewards/{reward_id}/redeem` — l'id est dans le CHEMIN
  /// (voir [ApiEndpoints.loyaltyRedeem]). Peut lever `ValidationException`
  /// (422 `INSUFFICIENT_POINTS`) ou `NotFoundException` (404
  /// `REWARD_NOT_FOUND`) via [ApiClient.handleDioError].
  Future<RedeemResult> redeemReward(int rewardId) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.loyaltyRedeem(rewardId),
      );
      return RedeemResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}
