import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/features/promotions/models/promotion.dart';
import 'package:app_client/features/promotions/repositories/promotions_repository.dart';

/// Repository promotions — singleton, dépend de [ApiClient].
final promotionsRepositoryProvider = Provider<PromotionsRepository>((ref) {
  return PromotionsRepository(ref.read(apiClientProvider));
});

/// Liste des promotions actives — `GET /promotions`, public. `autoDispose` :
/// pas de cache persistant entre deux visites de l'écran, les promotions ont
/// pu changer (nouvelle offre, expiration) — toujours refetch à l'entrée sur
/// l'écran, même convention que `loyaltyAccountProvider`
/// (`features/loyalty/providers/loyalty_provider.dart`).
final promotionsProvider = FutureProvider.autoDispose<List<Promotion>>((ref) {
  return ref.read(promotionsRepositoryProvider).getActivePromotions();
});
