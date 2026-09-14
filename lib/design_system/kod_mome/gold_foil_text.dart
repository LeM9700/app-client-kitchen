import 'package:flutter/material.dart';

import 'package:app_client/core/theme/kod_mome/kod_mome_design_pack.dart';

/// Text rendered with the brand's gold gradient via [ShaderMask] — for
/// headlines/prices, not body copy (expensive to read at small sizes).
class GoldFoilText extends StatelessWidget {
  const GoldFoilText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: KodMomeDesignPack.goldGradient,
      ).createShader(bounds),
      child: Text(
        text,
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// Small gold-outlined pill (discount badges, size legends).
class GoldBadge extends StatelessWidget {
  const GoldBadge({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KodMomeDesignPack.primary, width: 1),
        color: KodMomeDesignPack.primary.withValues(alpha: 0.12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: KodMomeDesignPack.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                color: KodMomeDesignPack.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
