import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/features/catalog/models/tenant_public_info.dart';
import 'package:app_client/features/catalog/repositories/tenant_public_repository.dart';

final tenantPublicRepositoryProvider = Provider<TenantPublicRepository>((ref) {
  return TenantPublicRepository(ref.read(apiClientProvider));
});

final tenantStatusProvider =
    FutureProvider.autoDispose<TenantStatusInfo>((ref) {
  return ref.read(tenantPublicRepositoryProvider).fetchStatus(Env.tenantSlug);
});

final tenantBusinessHoursProvider =
    FutureProvider.autoDispose<List<BusinessHourInfo>>((ref) {
  return ref.read(tenantPublicRepositoryProvider).fetchHours(Env.tenantSlug);
});
