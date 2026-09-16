import 'package:flutter/material.dart';

import 'package:app_client/core/theme/kod_mome/kod_mome_design_pack.dart';

enum _MedallionVariant { splash, empty, loading, success }

/// The restaurant's real circular logo, treated as a stamped medallion
/// (skeuomorphic bevel ring + shadow) rather than a free-floating mascot —
/// only a JPEG of the badge is available, no clean character cutout exists.
/// Each named constructor picks a motion appropriate to where it's used.
class KodMomeMedallion extends StatefulWidget {
  const KodMomeMedallion.splash({super.key, this.size = 140})
      : _variant = _MedallionVariant.splash;

  const KodMomeMedallion.empty({super.key, this.size = 96})
      : _variant = _MedallionVariant.empty;

  const KodMomeMedallion.loading({super.key, this.size = 64})
      : _variant = _MedallionVariant.loading;

  const KodMomeMedallion.success({super.key, this.size = 110})
      : _variant = _MedallionVariant.success;

  final double size;
  final _MedallionVariant _variant;

  @override
  State<KodMomeMedallion> createState() => _KodMomeMedallionState();
}

class _KodMomeMedallionState extends State<KodMomeMedallion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final duration = switch (widget._variant) {
      _MedallionVariant.loading => const Duration(seconds: 2),
      _MedallionVariant.success => KodMomeDesignPack.celebrationDuration,
      _MedallionVariant.splash ||
      _MedallionVariant.empty =>
        KodMomeDesignPack.entranceDuration,
    };
    _controller = AnimationController(vsync: this, duration: duration);
    if (widget._variant == _MedallionVariant.loading) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ring = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: KodMomeDesignPack.primary, width: 3),
        boxShadow: [
          const BoxShadow(
            color: KodMomeDesignPack.neuDarkShadow,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: KodMomeDesignPack.primary.withValues(alpha: 0.35),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child: Image.asset(
            KodMomeDesignPack.medallionAssetPath,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return switch (widget._variant) {
          _MedallionVariant.splash => Opacity(
              opacity: _controller.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: Curves.elasticOut.transform(_controller.value),
                child: child,
              ),
            ),
          _MedallionVariant.loading => Transform.rotate(
              angle: _controller.value * 6.28319,
              child: child,
            ),
          _MedallionVariant.success => Transform.scale(
              scale:
                  0.8 + 0.2 * Curves.easeOutBack.transform(_controller.value),
              child: child,
            ),
          _MedallionVariant.empty => Opacity(
              opacity: _controller.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(
                  0,
                  6 * (1 - Curves.easeOutCubic.transform(_controller.value)),
                ),
                child: child,
              ),
            ),
        };
      },
      child: ring,
    );
  }
}
