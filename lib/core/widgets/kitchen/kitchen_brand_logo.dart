import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/theme/kitchen_shadows.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/theme/tenant_theme_provider.dart';

class KitchenBrandLogo extends ConsumerWidget {
  const KitchenBrandLogo({
    super.key,
    this.size = 104,
    this.logoUrl,
    this.light = true,
  });

  final double size;
  final String? logoUrl;
  final bool light;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandingLogoUrl =
        logoUrl ?? ref.watch(tenantBrandingProvider).logoUrl;
    final trimmedLogoUrl = brandingLogoUrl?.trim();

    Widget logo;
    if (trimmedLogoUrl != null && trimmedLogoUrl.isNotEmpty) {
      logo = Image.network(
        trimmedLogoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _LocalLogo(size: size),
      );
    } else {
      logo = _LocalLogo(size: size);
    }

    return Semantics(
      label: 'Logo Kitchen',
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: light ? KitchenColors.paperLight : KitchenColors.espresso,
          border: Border.all(
            color: light
                ? KitchenColors.whiteWarm.withValues(alpha: 0.84)
                : KitchenColors.cognac.withValues(alpha: 0.72),
            width: 2,
          ),
          boxShadow: KitchenShadows.raised,
        ),
        child: ClipOval(child: logo),
      ),
    );
  }
}

class _LocalLogo extends StatelessWidget {
  const _LocalLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      KitchenAssets.localLogo,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: KitchenColors.espresso,
        child: Center(
          child: Text(
            'K',
            style: TextStyle(
              color: KitchenColors.paperLight,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
