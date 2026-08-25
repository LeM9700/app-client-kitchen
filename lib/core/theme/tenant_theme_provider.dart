import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/models/tenant_branding.dart';
import 'package:app_client/core/monitoring/error_reporter.dart';
import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/core/repositories/branding_repository.dart';
import 'package:app_client/core/theme/app_theme.dart';

final brandingRepositoryProvider = Provider<BrandingRepository>(
  (ref) => BrandingRepository(ref.read(apiClientProvider)),
);

final tenantBrandingProvider =
    StateNotifierProvider<TenantBrandingNotifier, TenantBranding>(
  (ref) => TenantBrandingNotifier(ref.read(brandingRepositoryProvider)),
);

final appThemeProvider = Provider<ThemeData>((ref) {
  final branding = ref.watch(tenantBrandingProvider);
  return AppTheme.generate(branding);
});

class TenantBrandingNotifier extends StateNotifier<TenantBranding> {
  TenantBrandingNotifier(this._repository) : super(TenantBranding.demo());

  final BrandingRepository _repository;

  Future<void> load(String slug) async {
    try {
      final branding = await _repository.fetchBranding(slug);
      state = branding;
    } catch (error, stackTrace) {
      // Keep the app usable with the initial theme, but keep a redacted trace.
      unawaited(
        ErrorReporting.recordError(
          error,
          stackTrace,
          context: {
            'feature': 'tenant_branding',
            'tenant_slug': slug,
          },
        ),
      );
    }
  }
}
