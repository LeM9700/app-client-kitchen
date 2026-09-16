import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:app_client/core/theme/kod_mome/kod_mome_design_pack.dart';

/// Two glass treatments, deliberately kept separate for performance reasons
/// (see the Kod Mome DA plan): [hero] uses a real [BackdropFilter] blur and
/// must stay to at most one surface per screen; [listItem] is a cheap
/// gradient+border+shadow look-alike for anything inside a scrolling list.
enum KodMomeGlassVariant { hero, listItem }

class KodMomeGlassSurface extends StatelessWidget {
  const KodMomeGlassSurface({
    super.key,
    required this.child,
    this.variant = KodMomeGlassVariant.listItem,
    this.borderRadius = 20,
    this.padding,
  });

  final Widget child;
  final KodMomeGlassVariant variant;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: KodMomeDesignPack.glassOpacity),
            Colors.white.withValues(alpha: KodMomeDesignPack.glassOpacity / 3),
          ],
        ),
        border: Border.all(
          width: 1,
          color: KodMomeDesignPack.glassBorderGradient.first,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (variant == KodMomeGlassVariant.listItem) {
      return ClipRRect(borderRadius: radius, child: content);
    }

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: KodMomeDesignPack.glassBlurSigmaHero,
          sigmaY: KodMomeDesignPack.glassBlurSigmaHero,
        ),
        child: content,
      ),
    );
  }
}
