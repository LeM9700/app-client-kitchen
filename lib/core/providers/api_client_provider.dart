import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/api/api_client.dart';

/// Provider singleton du client HTTP.
///
/// Tous les repositories font `ref.read(apiClientProvider)` pour obtenir
/// l'instance partagée. Un seul intercepteur JWT est donc actif à la fois.
///
/// Jamais de `Provider.autoDispose` ici — l'ApiClient doit vivre toute la
/// durée de vie de l'application.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref));
