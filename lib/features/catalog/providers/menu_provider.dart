import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/features/catalog/models/menu.dart';
import 'package:app_client/features/catalog/repositories/menu_repository.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ref.read(apiClientProvider));
});

final menusProvider = FutureProvider<List<CatalogMenu>>((ref) {
  return ref.read(menuRepositoryProvider).getMenus();
});

final menuDetailProvider = FutureProvider.family<CatalogMenu, int>((ref, id) {
  return ref.read(menuRepositoryProvider).getMenu(id);
});
